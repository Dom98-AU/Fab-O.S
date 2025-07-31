using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Interfaces
{
    public interface IMultiAuthService : IFabOSAuthenticationService
    {
        // Sign up methods
        Task<AuthenticationResult> SignUpWithEmailAsync(string email, string password, string username, string companyName);
        Task<AuthenticationResult> SignUpWithSocialAsync(string provider, ClaimsPrincipal externalPrincipal, string companyName = null);
        
        // Sign in methods
        Task<AuthenticationResult> SignInWithEmailAsync(string email, string password, string productName = null);
        Task<AuthenticationResult> SignInWithSocialAsync(string provider, ClaimsPrincipal externalPrincipal, string productName = null);
        
        // Account linking
        Task<bool> LinkSocialAccountAsync(int userId, string provider, ClaimsPrincipal externalPrincipal);
        Task<bool> UnlinkSocialAccountAsync(int userId, string provider);
        Task<List<UserAuthMethod>> GetUserAuthMethodsAsync(int userId);
        
        // Provider management
        Task<List<OAuthProviderSettings>> GetEnabledProvidersAsync();
        Task<bool> IsProviderEnabledAsync(string provider);
        
        // Audit
        Task LogSocialLoginEventAsync(int? userId, string provider, string eventType, bool success, string errorMessage = null);
    }

    public class SignUpModel
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public string CompanyName { get; set; } = string.Empty;
        public string? JobTitle { get; set; }
        public string? PhoneNumber { get; set; }
    }

    public class SocialSignUpModel
    {
        public string Provider { get; set; } = string.Empty;
        public string ExternalId { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string DisplayName { get; set; } = string.Empty;
        public string? ProfilePictureUrl { get; set; }
        public string? CompanyName { get; set; }
    }
}