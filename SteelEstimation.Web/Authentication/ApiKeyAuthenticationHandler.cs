using System;
using System.Linq;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Encodings.Web;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authentication;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Web.Authentication
{
    public class ApiKeyAuthenticationHandler : AuthenticationHandler<ApiKeyAuthenticationOptions>
    {
        private readonly ApplicationDbContext _context;
        private const string API_KEY_HEADER = "X-API-Key";
        private const string API_SIGNATURE_HEADER = "X-API-Signature";
        private const string API_TIMESTAMP_HEADER = "X-API-Timestamp";
        private const string API_NONCE_HEADER = "X-API-Nonce";

        public ApiKeyAuthenticationHandler(
            IOptionsMonitor<ApiKeyAuthenticationOptions> options,
            ILoggerFactory logger,
            UrlEncoder encoder,
            ApplicationDbContext context)
            : base(options, logger, encoder)
        {
            _context = context;
        }

        protected override async Task<AuthenticateResult> HandleAuthenticateAsync()
        {
            try
            {
                // Check if API key header exists
                if (!Request.Headers.ContainsKey(API_KEY_HEADER))
                {
                    return AuthenticateResult.NoResult();
                }

                var apiKey = Request.Headers[API_KEY_HEADER].FirstOrDefault();
                if (string.IsNullOrEmpty(apiKey))
                {
                    return AuthenticateResult.Fail("Invalid API key");
                }

                // Extract key prefix (first 8 characters)
                if (apiKey.Length < 8)
                {
                    return AuthenticateResult.Fail("Invalid API key format");
                }

                var keyPrefix = apiKey.Substring(0, 8);

                // Look up API key in database
                var apiKeyEntity = await _context.ApiKeys
                    .FirstOrDefaultAsync(k => k.KeyPrefix == keyPrefix && k.IsActive);

                if (apiKeyEntity == null)
                {
                    return AuthenticateResult.Fail("API key not found");
                }

                // Check expiration
                if (apiKeyEntity.ExpiresAt.HasValue && apiKeyEntity.ExpiresAt.Value < DateTime.UtcNow)
                {
                    return AuthenticateResult.Fail("API key has expired");
                }

                // Verify the full key hash
                var keyHash = ComputeHash(apiKey);
                if (apiKeyEntity.KeyHash != keyHash)
                {
                    return AuthenticateResult.Fail("Invalid API key");
                }

                // Optional: Verify signature for enhanced security
                if (Options.RequireSignature)
                {
                    var isSignatureValid = await VerifySignature(apiKey);
                    if (!isSignatureValid)
                    {
                        return AuthenticateResult.Fail("Invalid signature");
                    }
                }

                // Update last used timestamp
                apiKeyEntity.LastUsedAt = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                // Create claims
                var claims = new[]
                {
                    new Claim(ClaimTypes.Name, apiKeyEntity.Name),
                    new Claim("ApiKeyId", apiKeyEntity.Id.ToString()),
                    new Claim("Scopes", apiKeyEntity.Scopes ?? string.Empty)
                };

                var identity = new ClaimsIdentity(claims, Scheme.Name);
                var principal = new ClaimsPrincipal(identity);
                var ticket = new AuthenticationTicket(principal, Scheme.Name);

                return AuthenticateResult.Success(ticket);
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error during API key authentication");
                return AuthenticateResult.Fail("An error occurred during authentication");
            }
        }

        private async Task<bool> VerifySignature(string apiKey)
        {
            try
            {
                if (!Request.Headers.ContainsKey(API_SIGNATURE_HEADER) ||
                    !Request.Headers.ContainsKey(API_TIMESTAMP_HEADER) ||
                    !Request.Headers.ContainsKey(API_NONCE_HEADER))
                {
                    return false;
                }

                var signature = Request.Headers[API_SIGNATURE_HEADER].FirstOrDefault();
                var timestamp = Request.Headers[API_TIMESTAMP_HEADER].FirstOrDefault();
                var nonce = Request.Headers[API_NONCE_HEADER].FirstOrDefault();

                if (string.IsNullOrEmpty(signature) || string.IsNullOrEmpty(timestamp) || string.IsNullOrEmpty(nonce))
                {
                    return false;
                }

                // Verify timestamp is within acceptable range (e.g., 5 minutes)
                if (long.TryParse(timestamp, out var timestampValue))
                {
                    var requestTime = DateTimeOffset.FromUnixTimeSeconds(timestampValue);
                    var timeDiff = Math.Abs((DateTimeOffset.UtcNow - requestTime).TotalMinutes);
                    if (timeDiff > 5)
                    {
                        return false;
                    }
                }
                else
                {
                    return false;
                }

                // Compute expected signature
                var method = Request.Method;
                var path = Request.Path.Value;
                var body = string.Empty; // For simplicity, not reading body here

                var message = $"{method}{path}{timestamp}{nonce}{body}";
                var expectedSignature = ComputeHmac(message, apiKey);

                return signature == expectedSignature;
            }
            catch
            {
                return false;
            }
        }

        private string ComputeHash(string input)
        {
            using (var sha256 = SHA256.Create())
            {
                var bytes = Encoding.UTF8.GetBytes(input);
                var hash = sha256.ComputeHash(bytes);
                return Convert.ToBase64String(hash);
            }
        }

        private string ComputeHmac(string message, string secret)
        {
            using (var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secret)))
            {
                var bytes = Encoding.UTF8.GetBytes(message);
                var hash = hmac.ComputeHash(bytes);
                return Convert.ToBase64String(hash);
            }
        }
    }

    public class ApiKeyAuthenticationOptions : AuthenticationSchemeOptions
    {
        public bool RequireSignature { get; set; } = false;
    }

    public static class ApiKeyAuthenticationExtensions
    {
        public const string SchemeName = "ApiKey";

        public static AuthenticationBuilder AddApiKey(this AuthenticationBuilder builder)
        {
            return builder.AddApiKey(options => { });
        }

        public static AuthenticationBuilder AddApiKey(this AuthenticationBuilder builder, Action<ApiKeyAuthenticationOptions> configureOptions)
        {
            return builder.AddScheme<ApiKeyAuthenticationOptions, ApiKeyAuthenticationHandler>(SchemeName, configureOptions);
        }
    }
}