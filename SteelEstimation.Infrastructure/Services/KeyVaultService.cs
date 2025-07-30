using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SteelEstimation.Core.Interfaces;

namespace SteelEstimation.Infrastructure.Services;

/// <summary>
/// Service for interacting with Azure Key Vault
/// Note: This requires Azure Key Vault to be configured
/// </summary>
public class KeyVaultService : IKeyVaultService
{
    private readonly SecretClient? _secretClient;
    private readonly IConfiguration _configuration;
    private readonly ILogger<KeyVaultService> _logger;
    private readonly bool _isEnabled;

    public KeyVaultService(IConfiguration configuration, ILogger<KeyVaultService> logger)
    {
        _configuration = configuration;
        _logger = logger;
        
        var keyVaultUrl = configuration["KeyVault:Url"];
        _isEnabled = !string.IsNullOrEmpty(keyVaultUrl);
        
        if (_isEnabled)
        {
            try
            {
                _secretClient = new SecretClient(new Uri(keyVaultUrl!), new DefaultAzureCredential());
                _logger.LogInformation("Key Vault service initialized with URL: {Url}", keyVaultUrl);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to initialize Key Vault client");
                _isEnabled = false;
            }
        }
        else
        {
            _logger.LogWarning("Key Vault is not configured. Secrets will be stored in memory only.");
        }
    }

    public async Task<string> GetSecretAsync(string secretName)
    {
        if (!_isEnabled || _secretClient == null)
        {
            // In development, return from configuration
            var devSecret = _configuration[$"DevSecrets:{secretName}"];
            if (string.IsNullOrEmpty(devSecret))
            {
                throw new InvalidOperationException($"Secret {secretName} not found in development configuration");
            }
            return devSecret;
        }

        try
        {
            var response = await _secretClient.GetSecretAsync(secretName);
            return response.Value.Value;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve secret {SecretName} from Key Vault", secretName);
            throw;
        }
    }

    public async Task StoreSecretAsync(string secretName, string secretValue)
    {
        if (!_isEnabled || _secretClient == null)
        {
            // In development, log the action
            _logger.LogInformation("Dev mode: Would store secret {SecretName}", secretName);
            return;
        }

        try
        {
            await _secretClient.SetSecretAsync(secretName, secretValue);
            _logger.LogInformation("Stored secret {SecretName} in Key Vault", secretName);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to store secret {SecretName} in Key Vault", secretName);
            throw;
        }
    }

    public async Task DeleteSecretAsync(string secretName)
    {
        if (!_isEnabled || _secretClient == null)
        {
            _logger.LogInformation("Dev mode: Would delete secret {SecretName}", secretName);
            return;
        }

        try
        {
            var deleteOperation = await _secretClient.StartDeleteSecretAsync(secretName);
            await deleteOperation.WaitForCompletionAsync();
            
            _logger.LogInformation("Deleted secret {SecretName} from Key Vault", secretName);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to delete secret {SecretName} from Key Vault", secretName);
            throw;
        }
    }

    public async Task<bool> SecretExistsAsync(string secretName)
    {
        if (!_isEnabled || _secretClient == null)
        {
            return _configuration[$"DevSecrets:{secretName}"] != null;
        }

        try
        {
            await _secretClient.GetSecretAsync(secretName);
            return true;
        }
        catch
        {
            return false;
        }
    }

    public async Task<Dictionary<string, string>> GetSecretsAsync(string prefix)
    {
        var secrets = new Dictionary<string, string>();
        
        if (!_isEnabled || _secretClient == null)
        {
            // In development, return from configuration
            var devSecrets = _configuration.GetSection("DevSecrets").GetChildren()
                .Where(x => x.Key.StartsWith(prefix))
                .ToDictionary(x => x.Key, x => x.Value ?? string.Empty);
            return devSecrets;
        }

        try
        {
            await foreach (var secretProperties in _secretClient.GetPropertiesOfSecretsAsync())
            {
                if (secretProperties.Name.StartsWith(prefix))
                {
                    var secret = await _secretClient.GetSecretAsync(secretProperties.Name);
                    secrets[secretProperties.Name] = secret.Value.Value;
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to retrieve secrets with prefix {Prefix} from Key Vault", prefix);
            throw;
        }

        return secrets;
    }
}