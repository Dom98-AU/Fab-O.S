using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;
using SteelEstimation.Core.DTOs;
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
        
        // IAuthenticationService compatibility methods
        Task<AuthResult> LoginAsync(string usernameOrEmail, string password);
        Task<AuthResult> RegisterAsync(RegisterRequest request);
        Task<bool> LogoutAsync();
        Task<AuthResult> RefreshTokenAsync(string refreshToken);
        Task<bool> ChangePasswordAsync(int userId, string currentPassword, string newPassword);
        Task<bool> ResetPasswordAsync(string email);
        Task<bool> ConfirmPasswordResetAsync(string token, string newPassword);
        Task<bool> ConfirmEmailAsync(string token);
        Task<User?> GetCurrentUserAsync();
        Task<bool> IsUserInRoleAsync(int userId, string roleName);
        Task<IEnumerable<string>> GetUserRolesAsync(int userId);
        Task<int?> GetCurrentUserIdAsync();
        Task<int?> GetUserCompanyIdAsync();
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