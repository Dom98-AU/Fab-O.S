using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Cryptography.KeyDerivation;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SteelEstimation.Core.DTOs;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Interfaces;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services
{
    public class AuthenticationService : IAuthenticationService
    {
        private readonly ApplicationDbContext _context;
        private readonly ITokenService? _tokenService;
        private readonly IConfiguration _configuration;
        private readonly ILogger<AuthenticationService> _logger;
        private readonly IHttpContextAccessor _httpContextAccessor;
        private const int MaxFailedAttempts = 5;
        private const int LockoutMinutes = 30;

        public AuthenticationService(
            ApplicationDbContext context,
            IConfiguration configuration,
            ILogger<AuthenticationService> logger,
            IHttpContextAccessor httpContextAccessor,
            ITokenService? tokenService = null)
        {
            _context = context;
            _tokenService = tokenService;
            _configuration = configuration;
            _logger = logger;
            _httpContextAccessor = httpContextAccessor;
        }

        public async Task<AuthResult> LoginAsync(string usernameOrEmail, string password)
        {
            try
            {
                _logger.LogInformation("LoginAsync called for user: {User}", usernameOrEmail);
                
                // Test database connection first
                try
                {
                    var canConnect = await _context.Database.CanConnectAsync();
                    _logger.LogInformation("Database connection test: {Result}", canConnect);
                    if (!canConnect)
                    {
                        return new AuthResult 
                        { 
                            Success = false, 
                            Message = "Cannot connect to database"
                        };
                    }
                }
                catch (Exception dbEx)
                {
                    _logger.LogError(dbEx, "Database connection test failed");
                    return new AuthResult 
                    { 
                        Success = false, 
                        Message = $"Database connection error: {dbEx.Message}"
                    };
                }
                
                // Find user by username or email
                var user = await _context.Users
                    .Include(u => u.UserRoles)
                    .ThenInclude(ur => ur.Role)
                    .Include(u => u.Company)
                    .FirstOrDefaultAsync(u => 
                        u.Username == usernameOrEmail || 
                        u.Email == usernameOrEmail);

                if (user == null)
                {
                    return new AuthResult 
                    { 
                        Success = false, 
                        Message = "Invalid username or password" 
                    };
                }

                // Check if account is locked
                if (user.IsLockedOut)
                {
                    return new AuthResult 
                    { 
                        Success = false, 
                        Message = $"Account is locked. Try again after {user.LockedOutUntil:t}" 
                    };
                }

                // Check if account is active
                if (!user.IsActive)
                {
                    return new AuthResult 
                    { 
                        Success = false, 
                        Message = "Account is inactive. Contact administrator." 
                    };
                }

                // Verify password
                if (!VerifyPassword(password, user.PasswordHash))
                {
                    // Increment failed attempts
                    user.FailedLoginAttempts++;
                    
                    if (user.FailedLoginAttempts >= MaxFailedAttempts)
                    {
                        user.LockedOutUntil = DateTime.UtcNow.AddMinutes(LockoutMinutes);
                        await _context.SaveChangesAsync();
                        
                        return new AuthResult 
                        { 
                            Success = false, 
                            Message = "Account locked due to multiple failed attempts" 
                        };
                    }
                    
                    await _context.SaveChangesAsync();
                    
                    return new AuthResult 
                    { 
                        Success = false, 
                        Message = "Invalid username or password" 
                    };
                }

                // Check if email is confirmed (if required)
                if (!user.IsEmailConfirmed && _configuration.GetValue<bool>("RequireEmailConfirmation"))
                {
                    return new AuthResult 
                    { 
                        Success = false, 
                        Message = "Email not confirmed. Please check your email." 
                    };
                }

                // Reset failed attempts and update last login
                user.FailedLoginAttempts = 0;
                user.LockedOutUntil = null;
                user.LastLoginDate = DateTime.UtcNow;
                await _context.SaveChangesAsync();

                // Don't generate tokens - we're using session-based auth
                return new AuthResult
                {
                    Success = true,
                    Message = "Login successful",
                    AccessToken = null,
                    RefreshToken = null,
                    User = user
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during login for {UsernameOrEmail}", usernameOrEmail);
                
                // Include more detailed error information for debugging
                var errorMessage = $"Login error: {ex.Message}";
                if (ex.InnerException != null)
                {
                    errorMessage += $" | Inner: {ex.InnerException.Message}";
                }
                
                return new AuthResult 
                { 
                    Success = false, 
                    Message = errorMessage
                };
            }
        }

        public async Task<AuthResult> RegisterAsync(RegisterRequest request)
        {
            try
            {
                // Check if username exists
                if (await _context.Users.AnyAsync(u => u.Username == request.Username))
                {
                    return new AuthResult 
                    { 
                        Success = false, 
                        Message = "Username already exists" 
                    };
                }

                // Check if email exists
                if (await _context.Users.AnyAsync(u => u.Email == request.Email))
                {
                    return new AuthResult 
                    { 
                        Success = false, 
                        Message = "Email already registered" 
                    };
                }

                // Create new user
                var user = new User
                {
                    Username = request.Username,
                    Email = request.Email,
                    FirstName = request.FirstName,
                    LastName = request.LastName,
                    CompanyName = request.CompanyName,
                    JobTitle = request.JobTitle,
                    PhoneNumber = request.PhoneNumber,
                    PasswordHash = HashPassword(request.Password),
                    EmailConfirmationToken = GenerateToken(),
                    CreatedDate = DateTime.UtcNow,
                    LastModified = DateTime.UtcNow
                };

                _context.Users.Add(user);
                await _context.SaveChangesAsync();

                // Assign default role (Viewer)
                var viewerRole = await _context.Roles.FirstOrDefaultAsync(r => r.RoleName == "Viewer");
                if (viewerRole != null)
                {
                    _context.UserRoles.Add(new UserRole
                    {
                        UserId = user.Id,
                        RoleId = viewerRole.Id,
                        AssignedDate = DateTime.UtcNow
                    });
                    await _context.SaveChangesAsync();
                }

                // TODO: Send confirmation email
                _logger.LogInformation("New user registered: {Username}", user.Username);

                return new AuthResult
                {
                    Success = true,
                    Message = "Registration successful. Please check your email to confirm your account.",
                    User = user
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during registration");
                return new AuthResult 
                { 
                    Success = false, 
                    Message = "An error occurred during registration" 
                };
            }
        }

        public async Task<bool> ChangePasswordAsync(int userId, string currentPassword, string newPassword)
        {
            try
            {
                var user = await _context.Users.FindAsync(userId);
                if (user == null) return false;

                // Verify current password
                if (!VerifyPassword(currentPassword, user.PasswordHash))
                    return false;

                // Update password
                user.PasswordHash = HashPassword(newPassword);
                user.SecurityStamp = Guid.NewGuid().ToString();
                user.LastModified = DateTime.UtcNow;

                await _context.SaveChangesAsync();
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
                var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
                if (user == null) return true; // Don't reveal if email exists

                user.PasswordResetToken = GenerateToken();
                user.PasswordResetExpiry = DateTime.UtcNow.AddHours(24);
                
                await _context.SaveChangesAsync();

                // TODO: Send password reset email
                _logger.LogInformation("Password reset requested for {Email}", email);

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error initiating password reset");
                return false;
            }
        }

        public async Task<bool> ConfirmPasswordResetAsync(string token, string newPassword)
        {
            try
            {
                var user = await _context.Users.FirstOrDefaultAsync(u => 
                    u.PasswordResetToken == token && 
                    u.PasswordResetExpiry > DateTime.UtcNow);

                if (user == null) return false;

                user.PasswordHash = HashPassword(newPassword);
                user.PasswordResetToken = null;
                user.PasswordResetExpiry = null;
                user.SecurityStamp = Guid.NewGuid().ToString();
                user.LastModified = DateTime.UtcNow;

                await _context.SaveChangesAsync();
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error confirming password reset");
                return false;
            }
        }

        public async Task<bool> ConfirmEmailAsync(string token)
        {
            try
            {
                var user = await _context.Users.FirstOrDefaultAsync(u => 
                    u.EmailConfirmationToken == token);

                if (user == null) return false;

                user.IsEmailConfirmed = true;
                user.EmailConfirmationToken = null;
                user.LastModified = DateTime.UtcNow;

                await _context.SaveChangesAsync();
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error confirming email");
                return false;
            }
        }

        public async Task<bool> LogoutAsync()
        {
            // TODO: Implement token revocation if needed
            return await Task.FromResult(true);
        }

        public Task<AuthResult> RefreshTokenAsync(string refreshToken)
        {
            try
            {
                // TODO: Implement refresh token validation
                // For now, return error
                return Task.FromResult(new AuthResult 
                { 
                    Success = false, 
                    Message = "Refresh token not implemented yet" 
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error refreshing token");
                return Task.FromResult(new AuthResult 
                { 
                    Success = false, 
                    Message = "An error occurred while refreshing token" 
                });
            }
        }

        public async Task<User?> GetCurrentUserAsync()
        {
            var httpContext = _httpContextAccessor.HttpContext;
            if (httpContext?.User?.Identity?.IsAuthenticated != true)
                return null;
                
            // Try multiple claim types to find the user ID
            var userIdClaim = httpContext.User.FindFirst("UserId")?.Value 
                           ?? httpContext.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                           
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
                
            var user = await _context.Users
                .Include(u => u.Company)
                .FirstOrDefaultAsync(u => u.Id == userId);
                
            if (user == null)
            {
                _logger.LogWarning("User with ID {UserId} not found in database", userId);
            }
            
            return user;
        }

        public async Task<bool> IsUserInRoleAsync(int userId, string roleName)
        {
            return await _context.UserRoles
                .Include(ur => ur.Role)
                .AnyAsync(ur => ur.UserId == userId && ur.Role.RoleName == roleName);
        }

        public async Task<IEnumerable<string>> GetUserRolesAsync(int userId)
        {
            return await _context.UserRoles
                .Include(ur => ur.Role)
                .Where(ur => ur.UserId == userId)
                .Select(ur => ur.Role.RoleName)
                .ToListAsync();
        }

        #region Private Methods

        private string HashPassword(string password)
        {
            // Generate a 128-bit salt
            byte[] salt = new byte[128 / 8];
            using (var rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(salt);
            }

            // Derive a 256-bit subkey (use HMACSHA256 with 100,000 iterations)
            string hashed = Convert.ToBase64String(KeyDerivation.Pbkdf2(
                password: password,
                salt: salt,
                prf: KeyDerivationPrf.HMACSHA256,
                iterationCount: 100000,
                numBytesRequested: 256 / 8));

            // Combine salt and hash
            return $"{Convert.ToBase64String(salt)}.{hashed}";
        }

        private bool VerifyPassword(string password, string hashedPassword)
        {
            try
            {
                var parts = hashedPassword.Split('.');
                if (parts.Length != 2) return false;

                var salt = Convert.FromBase64String(parts[0]);
                var hash = parts[1];

                // Derive key from provided password and stored salt
                string hashed = Convert.ToBase64String(KeyDerivation.Pbkdf2(
                    password: password,
                    salt: salt,
                    prf: KeyDerivationPrf.HMACSHA256,
                    iterationCount: 100000,
                    numBytesRequested: 256 / 8));

                return hash == hashed;
            }
            catch
            {
                return false;
            }
        }

        private string GenerateToken()
        {
            var bytes = new byte[32];
            using (var rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(bytes);
            }
            return Convert.ToBase64String(bytes).Replace("+", "-").Replace("/", "_");
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

        #endregion
    }
}