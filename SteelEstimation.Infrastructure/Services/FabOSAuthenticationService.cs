using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using SteelEstimation.Core.DTOs;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Interfaces;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services
{
    public class FabOSAuthenticationService : IFabOSAuthenticationService
    {
        private readonly IDbContextFactory<ApplicationDbContext> _contextFactory;
        private readonly IConfiguration _configuration;
        private readonly ILogger<FabOSAuthenticationService> _logger;
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly string _jwtSecret;
        private readonly string _jwtIssuer;
        private readonly string _jwtAudience;
        private readonly int _jwtExpiryHours;

        public FabOSAuthenticationService(
            IDbContextFactory<ApplicationDbContext> contextFactory,
            IConfiguration configuration,
            ILogger<FabOSAuthenticationService> logger,
            IHttpContextAccessor httpContextAccessor)
        {
            _contextFactory = contextFactory;
            _configuration = configuration;
            _logger = logger;
            _httpContextAccessor = httpContextAccessor;
            
            // JWT Configuration
            _jwtSecret = configuration["JwtSettings:SecretKey"] ?? throw new InvalidOperationException("JWT Secret Key is not configured");
            _jwtIssuer = configuration["JwtSettings:Issuer"] ?? "SteelEstimation";
            _jwtAudience = configuration["JwtSettings:Audience"] ?? "SteelEstimation";
            _jwtExpiryHours = configuration.GetValue<int>("JwtSettings:ExpiryHours", 8);
        }

        public string GenerateJwtToken(User user)
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var key = Encoding.ASCII.GetBytes(_jwtSecret);
            
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Name, user.Username),
                new Claim(ClaimTypes.Email, user.Email ?? ""),
                new Claim("CompanyId", user.CompanyId.ToString())
            };

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(claims),
                Expires = DateTime.UtcNow.AddHours(_jwtExpiryHours),
                Issuer = _jwtIssuer,
                Audience = _jwtAudience,
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature)
            };

            var token = tokenHandler.CreateToken(tokenDescriptor);
            return tokenHandler.WriteToken(token);
        }

        public ClaimsPrincipal? ValidateJwtToken(string token)
        {
            try
            {
                var tokenHandler = new JwtSecurityTokenHandler();
                var key = Encoding.ASCII.GetBytes(_jwtSecret);
                
                var validationParameters = new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(key),
                    ValidateIssuer = true,
                    ValidIssuer = _jwtIssuer,
                    ValidateAudience = true,
                    ValidAudience = _jwtAudience,
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.Zero
                };

                var principal = tokenHandler.ValidateToken(token, validationParameters, out SecurityToken validatedToken);
                return principal;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "JWT token validation failed");
                return null;
            }
        }

        public async Task<AuthenticationResult> AuthenticateAsync(string email, string password, string productName = null)
        {
            try
            {
                using var context = await _contextFactory.CreateDbContextAsync();
                var user = await context.Users
                    .Include(u => u.Company)
                    .Include(u => u.UserRoles)
                    .ThenInclude(ur => ur.Role)
                    .FirstOrDefaultAsync(u => u.Email == email && u.IsActive);

                if (user == null)
                {
                    return new AuthenticationResult
                    {
                        Success = false,
                        ErrorMessage = "Invalid email or password"
                    };
                }

                // Verify password
                if (!VerifyPassword(password, user.PasswordHash!, user.PasswordSalt!))
                {
                    return new AuthenticationResult
                    {
                        Success = false,
                        ErrorMessage = "Invalid email or password"
                    };
                }

                // Check product access if specified
                if (!string.IsNullOrEmpty(productName))
                {
                    var hasAccess = await UserHasProductAccessAsync(user.Id, productName);
                    if (!hasAccess)
                    {
                        return new AuthenticationResult
                        {
                            Success = false,
                            ErrorMessage = $"You don't have access to {productName}"
                        };
                    }
                }

                // Update last login
                user.LastLoginDate = DateTime.UtcNow;
                await context.SaveChangesAsync();

                // Generate token
                var token = GenerateJwtToken(user);

                return new AuthenticationResult
                {
                    Success = true,
                    User = user,
                    Token = token
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Authentication failed for email {Email}", email);
                return new AuthenticationResult
                {
                    Success = false,
                    ErrorMessage = "Authentication failed"
                };
            }
        }

        public async Task<bool> UserHasProductAccessAsync(int userId, string productName)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            return await context.UserProductAccess
                .AnyAsync(upa => upa.UserId == userId && 
                                upa.ProductLicense.ProductName == productName &&
                                upa.ProductLicense.IsActive &&
                                upa.ProductLicense.ValidUntil > DateTime.UtcNow);
        }

        public async Task<List<string>> GetUserProductsAsync(int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            return await context.UserProductAccess
                .Where(upa => upa.UserId == userId && 
                             upa.ProductLicense.IsActive &&
                             upa.ProductLicense.ValidUntil > DateTime.UtcNow)
                .Select(upa => upa.ProductLicense.ProductName)
                .Distinct()
                .ToListAsync();
        }

        public async Task<string?> GetUserProductRoleAsync(int userId, string productName)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            var userProductRole = await context.UserProductRoles
                .Include(upr => upr.ProductRole)
                .Where(upr => upr.UserId == userId && upr.ProductRole.ProductName == productName)
                .Select(upr => upr.ProductRole.RoleName)
                .FirstOrDefaultAsync();

            return userProductRole;
        }

        public async Task<bool> CheckConcurrentUserLimitAsync(string productName, int companyId, int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            var license = await context.ProductLicenses
                .FirstOrDefaultAsync(pl => pl.CompanyId == companyId && 
                                          pl.ProductName == productName && 
                                          pl.IsActive);

            if (license == null || license.MaxConcurrentUsers == 0)
            {
                return true; // No limit or no license
            }

            // Count active sessions for this product in the last hour
            var oneHourAgo = DateTime.UtcNow.AddHours(-1);
            var activeUsers = await context.UserProductAccess
                .Where(upa => upa.ProductLicenseId == license.Id &&
                             upa.LastAccessDate > oneHourAgo &&
                             upa.UserId != userId) // Don't count current user
                .Select(upa => upa.UserId)
                .Distinct()
                .CountAsync();

            return activeUsers < license.MaxConcurrentUsers;
        }

        public async Task RecordUserActivityAsync(int userId, string productName)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            var access = await context.UserProductAccess
                .FirstOrDefaultAsync(upa => upa.UserId == userId &&
                                           upa.ProductLicense.ProductName == productName);

            if (access != null)
            {
                access.LastAccessDate = DateTime.UtcNow;
                await context.SaveChangesAsync();
            }
        }

        private static bool VerifyPassword(string password, string hash, string salt)
        {
            var saltBytes = Convert.FromBase64String(salt);
            using var hmac = new HMACSHA512(saltBytes);
            var computedHash = hmac.ComputeHash(Encoding.UTF8.GetBytes(password));
            return Convert.ToBase64String(computedHash) == hash;
        }
        
        // IAuthenticationService compatibility methods
        
        public async Task<AuthResult> LoginAsync(string usernameOrEmail, string password)
        {
            try
            {
                var authResult = await AuthenticateAsync(usernameOrEmail, password);
                
                return new AuthResult
                {
                    Success = authResult.Success,
                    Message = authResult.ErrorMessage ?? authResult.Message ?? "Login successful",
                    User = authResult.User,
                    AccessToken = authResult.Token,
                    RefreshToken = null // FabOS uses JWT tokens, not refresh tokens
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Login failed for {UsernameOrEmail}", usernameOrEmail);
                return new AuthResult
                {
                    Success = false,
                    Message = "Login failed"
                };
            }
        }
        
        public async Task<User?> GetCurrentUserAsync()
        {
            var httpContext = _httpContextAccessor.HttpContext;
            if (httpContext?.User?.Identity?.IsAuthenticated != true)
            {
                _logger.LogWarning("GetCurrentUserAsync: User is not authenticated");
                return null;
            }
                
            // Try multiple claim types to find the user ID
            var userIdClaim = httpContext.User.FindFirst("UserId")?.Value 
                           ?? httpContext.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                           
            _logger.LogInformation("GetCurrentUserAsync: Found UserId claim: {UserIdClaim}", userIdClaim);
                           
            if (string.IsNullOrEmpty(userIdClaim))
            {
                _logger.LogWarning("No UserId claim found for authenticated user");
                return null;
            }
            
            if (!int.TryParse(userIdClaim, out var userId))
            {
                _logger.LogWarning("Invalid UserId claim value: {UserIdClaim}", userIdClaim);
                return null;
            }
            
            using var context = await _contextFactory.CreateDbContextAsync();
            var user = await context.Users
                .Include(u => u.Company)
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.Id == userId);
                
            _logger.LogInformation("GetCurrentUserAsync: Found user: {Username} (ID: {UserId})", user?.Username, user?.Id);
            return user;
        }
        
        public async Task<int?> GetCurrentUserIdAsync()
        {
            var user = await GetCurrentUserAsync();
            return user?.Id;
        }
        
        public async Task<int?> GetUserCompanyIdAsync()
        {
            var user = await GetCurrentUserAsync();
            return user?.CompanyId;
        }
        
        public async Task<IEnumerable<string>> GetUserRolesAsync(int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            return await context.UserRoles
                .Include(ur => ur.Role)
                .Where(ur => ur.UserId == userId)
                .Select(ur => ur.Role.RoleName)
                .ToListAsync();
        }
        
        public async Task<bool> IsUserInRoleAsync(int userId, string roleName)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            return await context.UserRoles
                .Include(ur => ur.Role)
                .AnyAsync(ur => ur.UserId == userId && ur.Role.RoleName == roleName);
        }
        
        public async Task<bool> ChangePasswordAsync(int userId, string currentPassword, string newPassword)
        {
            try
            {
                using var context = await _contextFactory.CreateDbContextAsync();
                var user = await context.Users.FindAsync(userId);
                if (user == null)
                    return false;
                    
                // Verify current password
                if (!VerifyPassword(currentPassword, user.PasswordHash!, user.PasswordSalt!))
                    return false;
                    
                // Generate new password hash and salt
                var salt = GenerateSalt();
                var hash = HashPassword(newPassword, salt);
                
                user.PasswordSalt = salt;
                user.PasswordHash = hash;
                
                await context.SaveChangesAsync();
                
                _logger.LogInformation("Password changed successfully for user {UserId}", userId);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error changing password for user {UserId}", userId);
                return false;
            }
        }
        
        public async Task<bool> ResetPasswordAsync(string email)
        {
            try
            {
                using var context = await _contextFactory.CreateDbContextAsync();
                var user = await context.Users.FirstOrDefaultAsync(u => u.Email == email);
                if (user == null)
                {
                    // Don't reveal if user exists
                    _logger.LogWarning("Password reset requested for non-existent email: {Email}", email);
                    return true;
                }
                
                // Generate reset token (in a real implementation, this would be sent via email)
                var resetToken = Guid.NewGuid().ToString();
                user.PasswordResetToken = resetToken;
                user.PasswordResetExpiry = DateTime.UtcNow.AddHours(1);
                
                await context.SaveChangesAsync();
                
                _logger.LogInformation("Password reset token generated for user {Email}", email);
                // TODO: Send email with reset token
                
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error resetting password for {Email}", email);
                return false;
            }
        }
        
        public async Task<bool> ConfirmPasswordResetAsync(string token, string newPassword)
        {
            try
            {
                using var context = await _contextFactory.CreateDbContextAsync();
                var user = await context.Users
                    .FirstOrDefaultAsync(u => u.PasswordResetToken == token 
                                           && u.PasswordResetExpiry > DateTime.UtcNow);
                                           
                if (user == null)
                    return false;
                    
                // Generate new password hash and salt
                var salt = GenerateSalt();
                var hash = HashPassword(newPassword, salt);
                
                user.PasswordSalt = salt;
                user.PasswordHash = hash;
                user.PasswordResetToken = null;
                user.PasswordResetExpiry = null;
                
                await context.SaveChangesAsync();
                
                _logger.LogInformation("Password reset confirmed for user {UserId}", user.Id);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error confirming password reset");
                return false;
            }
        }
        
        // Stub implementations for methods not used in cookie authentication
        
        public Task<AuthResult> RegisterAsync(RegisterRequest request)
        {
            throw new NotImplementedException("Registration is not implemented. Use user management features instead.");
        }
        
        public Task<bool> LogoutAsync()
        {
            // Logout is handled by cookie authentication at the controller level
            return Task.FromResult(true);
        }
        
        public Task<AuthResult> RefreshTokenAsync(string refreshToken)
        {
            throw new NotImplementedException("Refresh tokens are not used with cookie authentication.");
        }
        
        public Task<bool> ConfirmEmailAsync(string token)
        {
            throw new NotImplementedException("Email confirmation is not implemented.");
        }
        
        // Helper methods
        
        private static string GenerateSalt()
        {
            var buffer = new byte[16];
            using var rng = RandomNumberGenerator.Create();
            rng.GetBytes(buffer);
            return Convert.ToBase64String(buffer);
        }
        
        private static string HashPassword(string password, string salt)
        {
            var saltBytes = Convert.FromBase64String(salt);
            using var hmac = new HMACSHA512(saltBytes);
            var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(password));
            return Convert.ToBase64String(hash);
        }
    }
}