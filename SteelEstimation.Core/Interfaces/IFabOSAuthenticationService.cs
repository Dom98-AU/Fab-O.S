using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Interfaces
{
    public interface IFabOSAuthenticationService
    {
        // JWT token generation and validation
        string GenerateJwtToken(User user);
        ClaimsPrincipal? ValidateJwtToken(string token);
        
        // Authentication methods
        Task<AuthenticationResult> AuthenticateAsync(string email, string password, string productName = null);
        
        // Product access methods
        Task<bool> UserHasProductAccessAsync(int userId, string productName);
        Task<List<string>> GetUserProductsAsync(int userId);
        Task<string?> GetUserProductRoleAsync(int userId, string productName);
        Task<bool> CheckConcurrentUserLimitAsync(string productName, int companyId, int userId);
        Task RecordUserActivityAsync(int userId, string productName);
    }

    public class AuthenticationResult
    {
        public bool Success { get; set; }
        public User? User { get; set; }
        public string? Token { get; set; }
        public string? ErrorMessage { get; set; }
        public string? Message { get; set; }
        public bool RequiresEmailConfirmation { get; set; }
        public bool IsNewUser { get; set; }
        public List<string> AvailableProducts { get; set; } = new();
    }

    public class TokenPair
    {
        public string AccessToken { get; set; }
        public string RefreshToken { get; set; }
        public DateTime AccessTokenExpiry { get; set; }
        public DateTime RefreshTokenExpiry { get; set; }
    }
}