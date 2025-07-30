namespace SteelEstimation.Core.Interfaces;

public interface IKeyVaultService
{
    Task<string> GetSecretAsync(string secretName);
    Task StoreSecretAsync(string secretName, string secretValue);
    Task DeleteSecretAsync(string secretName);
    Task<bool> SecretExistsAsync(string secretName);
    Task<Dictionary<string, string>> GetSecretsAsync(string prefix);
}