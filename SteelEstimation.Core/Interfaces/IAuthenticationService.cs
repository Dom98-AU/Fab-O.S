using SteelEstimation.Core.DTOs;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Interfaces;

public interface IAuthenticationService
{
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