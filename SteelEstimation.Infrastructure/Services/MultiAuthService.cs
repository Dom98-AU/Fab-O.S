using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Interfaces;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services
{
    public class MultiAuthService : IMultiAuthService
    {
        private readonly ApplicationDbContext _context;
        private readonly IConfiguration _configuration;
        private readonly ILogger<MultiAuthService> _logger;
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly FabOSAuthenticationService _fabOSService;

        public MultiAuthService(
            ApplicationDbContext context,
            IConfiguration configuration,
            ILogger<MultiAuthService> logger,
            IHttpContextAccessor httpContextAccessor,
            FabOSAuthenticationService fabOSService)
        {
            _context = context;
            _configuration = configuration;
            _logger = logger;
            _httpContextAccessor = httpContextAccessor;
            _fabOSService = fabOSService;
        }

        // Email/Password Sign Up
        public async Task<AuthenticationResult> SignUpWithEmailAsync(string email, string password, string username, string companyName)
        {
            try
            {
                // Check if email already exists
                var existingUser = await _context.Users
                    .FirstOrDefaultAsync(u => u.Email == email && u.IsActive);
                
                if (existingUser != null)
                {
                    return new AuthenticationResult
                    {
                        Success = false,
                        ErrorMessage = "Email already registered"
                    };
                }

                // Create or find company
                var company = await GetOrCreateCompanyAsync(companyName);

                // Hash password
                var (hash, salt) = HashPassword(password);

                // Create user
                var user = new User
                {
                    Email = email,
                    Username = username,
                    PasswordHash = hash,
                    PasswordSalt = salt,
                    AuthProvider = "Local",
                    CompanyId = company.Id,
                    IsActive = true,
                    IsEmailConfirmed = false, // Require email confirmation
                    CreatedDate = DateTime.UtcNow
                };

                _context.Users.Add(user);
                await _context.SaveChangesAsync();

                // Create auth method record
                var authMethod = new UserAuthMethod
                {
                    UserId = user.Id,
                    AuthProvider = "Local",
                    Email = email,
                    DisplayName = username,
                    LinkedDate = DateTime.UtcNow,
                    IsActive = true
                };

                _context.UserAuthMethods.Add(authMethod);

                // Grant default Estimate product access
                await GrantDefaultProductAccessAsync(user.Id, company.Id);

                await _context.SaveChangesAsync();

                // Log the event
                await LogSocialLoginEventAsync(user.Id, "Local", "SignUp", true);

                // Generate token
                var token = _fabOSService.GenerateJwtToken(user);

                return new AuthenticationResult
                {
                    Success = true,
                    User = user,
                    Token = token,
                    RequiresEmailConfirmation = true
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during email sign up");
                await LogSocialLoginEventAsync(null, "Local", "SignUp", false, ex.Message);
                
                return new AuthenticationResult
                {
                    Success = false,
                    ErrorMessage = "Sign up failed. Please try again."
                };
            }
        }

        // Social Sign Up/Sign In (unified flow)
        public async Task<AuthenticationResult> SignUpWithSocialAsync(string provider, ClaimsPrincipal externalPrincipal, string companyName = null)
        {
            try
            {
                var email = GetClaimValue(externalPrincipal, ClaimTypes.Email);
                var externalId = GetClaimValue(externalPrincipal, ClaimTypes.NameIdentifier);
                var displayName = GetClaimValue(externalPrincipal, ClaimTypes.Name) ?? 
                                 GetClaimValue(externalPrincipal, "name") ?? 
                                 email?.Split('@')[0] ?? "User";

                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(externalId))
                {
                    return new AuthenticationResult
                    {
                        Success = false,
                        ErrorMessage = "Could not retrieve email from authentication provider"
                    };
                }

                // Check if user exists
                var existingUser = await _context.Users
                    .Include(u => u.Company)
                    .FirstOrDefaultAsync(u => u.Email == email && u.IsActive);

                if (existingUser != null)
                {
                    // Existing user - link the auth method if needed
                    var authMethod = await _context.UserAuthMethods
                        .FirstOrDefaultAsync(am => am.UserId == existingUser.Id && 
                                                  am.AuthProvider == provider && 
                                                  am.IsActive);

                    if (authMethod == null)
                    {
                        // Link new auth method
                        authMethod = new UserAuthMethod
                        {
                            UserId = existingUser.Id,
                            AuthProvider = provider,
                            ExternalUserId = externalId,
                            Email = email,
                            DisplayName = displayName,
                            LinkedDate = DateTime.UtcNow,
                            LastUsedDate = DateTime.UtcNow,
                            IsActive = true
                        };
                        _context.UserAuthMethods.Add(authMethod);
                    }
                    else
                    {
                        // Update last used
                        authMethod.LastUsedDate = DateTime.UtcNow;
                        authMethod.ExternalUserId = externalId; // Update in case it changed
                    }

                    existingUser.LastLoginDate = DateTime.UtcNow;
                    await _context.SaveChangesAsync();

                    await LogSocialLoginEventAsync(existingUser.Id, provider, "Login", true);

                    var token = _fabOSService.GenerateJwtToken(existingUser);
                    return new AuthenticationResult
                    {
                        Success = true,
                        User = existingUser,
                        Token = token
                    };
                }
                else
                {
                    // New user - create account
                    var company = await GetOrCreateCompanyAsync(companyName ?? email.Split('@')[1]);

                    var user = new User
                    {
                        Email = email,
                        Username = displayName,
                        AuthProvider = provider,
                        ExternalUserId = externalId,
                        CompanyId = company.Id,
                        IsActive = true,
                        IsEmailConfirmed = true, // Social logins are pre-verified
                            CreatedDate = DateTime.UtcNow
                    };

                    _context.Users.Add(user);
                    await _context.SaveChangesAsync();

                    // Create auth method record
                    var authMethod = new UserAuthMethod
                    {
                        UserId = user.Id,
                        AuthProvider = provider,
                        ExternalUserId = externalId,
                        Email = email,
                        DisplayName = displayName,
                        LinkedDate = DateTime.UtcNow,
                        LastUsedDate = DateTime.UtcNow,
                        IsActive = true
                    };

                    _context.UserAuthMethods.Add(authMethod);

                    // Grant default product access
                    await GrantDefaultProductAccessAsync(user.Id, company.Id);

                    await _context.SaveChangesAsync();

                    await LogSocialLoginEventAsync(user.Id, provider, "SignUp", true);

                    var token = _fabOSService.GenerateJwtToken(user);
                    return new AuthenticationResult
                    {
                        Success = true,
                        User = user,
                        Token = token,
                        IsNewUser = true
                    };
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during social sign up/sign in");
                await LogSocialLoginEventAsync(null, provider, "Failed", false, ex.Message);
                
                return new AuthenticationResult
                {
                    Success = false,
                    ErrorMessage = "Authentication failed. Please try again."
                };
            }
        }

        // Email/Password Sign In
        public async Task<AuthenticationResult> SignInWithEmailAsync(string email, string password, string productName = null)
        {
            try
            {
                var user = await _context.Users
                    .Include(u => u.Company)
                    .FirstOrDefaultAsync(u => u.Email == email && u.IsActive);

                if (user == null || !user.HasPassword)
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
                    await LogSocialLoginEventAsync(user.Id, "Local", "Login", false, "Invalid password");
                    return new AuthenticationResult
                    {
                        Success = false,
                        ErrorMessage = "Invalid email or password"
                    };
                }

                // Check product access if specified
                if (!string.IsNullOrEmpty(productName))
                {
                    var hasAccess = await _fabOSService.UserHasProductAccessAsync(user.Id, productName);
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
                
                // Update auth method last used
                var authMethod = await _context.UserAuthMethods
                    .FirstOrDefaultAsync(am => am.UserId == user.Id && am.AuthProvider == "Local");
                if (authMethod != null)
                {
                    authMethod.LastUsedDate = DateTime.UtcNow;
                }

                await _context.SaveChangesAsync();

                await LogSocialLoginEventAsync(user.Id, "Local", "Login", true);

                var token = _fabOSService.GenerateJwtToken(user);
                return new AuthenticationResult
                {
                    Success = true,
                    User = user,
                    Token = token
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during email sign in");
                return new AuthenticationResult
                {
                    Success = false,
                    ErrorMessage = "Sign in failed. Please try again."
                };
            }
        }

        // Social Sign In (redirects to SignUpWithSocialAsync for unified flow)
        public async Task<AuthenticationResult> SignInWithSocialAsync(string provider, ClaimsPrincipal externalPrincipal, string productName = null)
        {
            // Social sign in and sign up are handled by the same method
            return await SignUpWithSocialAsync(provider, externalPrincipal);
        }

        // Account Linking
        public async Task<bool> LinkSocialAccountAsync(int userId, string provider, ClaimsPrincipal externalPrincipal)
        {
            try
            {
                var externalId = GetClaimValue(externalPrincipal, ClaimTypes.NameIdentifier);
                var email = GetClaimValue(externalPrincipal, ClaimTypes.Email);
                var displayName = GetClaimValue(externalPrincipal, ClaimTypes.Name) ?? email?.Split('@')[0] ?? "User";

                if (string.IsNullOrEmpty(externalId))
                {
                    _logger.LogWarning("No external ID found for provider {Provider}", provider);
                    return false;
                }

                // Check if already linked
                var existingLink = await _context.UserAuthMethods
                    .AnyAsync(am => am.UserId == userId && am.AuthProvider == provider && am.IsActive);

                if (existingLink)
                {
                    _logger.LogWarning("User {UserId} already has {Provider} linked", userId, provider);
                    return false;
                }

                // Check if this external account is linked to another user
                var otherUser = await _context.UserAuthMethods
                    .AnyAsync(am => am.AuthProvider == provider && 
                                   am.ExternalUserId == externalId && 
                                   am.UserId != userId &&
                                   am.IsActive);

                if (otherUser)
                {
                    _logger.LogWarning("External account already linked to another user");
                    await LogSocialLoginEventAsync(userId, provider, "Link", false, "Account already linked to another user");
                    return false;
                }

                // Create link
                var authMethod = new UserAuthMethod
                {
                    UserId = userId,
                    AuthProvider = provider,
                    ExternalUserId = externalId,
                    Email = email,
                    DisplayName = displayName,
                    LinkedDate = DateTime.UtcNow,
                    IsActive = true
                };

                _context.UserAuthMethods.Add(authMethod);
                await _context.SaveChangesAsync();

                await LogSocialLoginEventAsync(userId, provider, "Link", true);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error linking social account");
                await LogSocialLoginEventAsync(userId, provider, "Link", false, ex.Message);
                return false;
            }
        }

        public async Task<bool> UnlinkSocialAccountAsync(int userId, string provider)
        {
            try
            {
                // Don't allow unlinking if it's the only auth method
                var authMethodCount = await _context.UserAuthMethods
                    .CountAsync(am => am.UserId == userId && am.IsActive);

                if (authMethodCount <= 1)
                {
                    _logger.LogWarning("Cannot unlink last auth method for user {UserId}", userId);
                    return false;
                }

                var authMethod = await _context.UserAuthMethods
                    .FirstOrDefaultAsync(am => am.UserId == userId && 
                                              am.AuthProvider == provider && 
                                              am.IsActive);

                if (authMethod == null)
                {
                    return false;
                }

                authMethod.IsActive = false;
                await _context.SaveChangesAsync();

                await LogSocialLoginEventAsync(userId, provider, "Unlink", true);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error unlinking social account");
                await LogSocialLoginEventAsync(userId, provider, "Unlink", false, ex.Message);
                return false;
            }
        }

        public async Task<List<UserAuthMethod>> GetUserAuthMethodsAsync(int userId)
        {
            return await _context.UserAuthMethods
                .Where(am => am.UserId == userId && am.IsActive)
                .OrderBy(am => am.LinkedDate)
                .ToListAsync();
        }

        // Provider Management
        public async Task<List<OAuthProviderSettings>> GetEnabledProvidersAsync()
        {
            return await _context.OAuthProviderSettings
                .Where(p => p.IsEnabled)
                .OrderBy(p => p.SortOrder)
                .ToListAsync();
        }

        public async Task<bool> IsProviderEnabledAsync(string provider)
        {
            return await _context.OAuthProviderSettings
                .AnyAsync(p => p.ProviderName == provider && p.IsEnabled);
        }

        // Audit
        public async Task LogSocialLoginEventAsync(int? userId, string provider, string eventType, bool success, string errorMessage = null)
        {
            try
            {
                var audit = new SocialLoginAudit
                {
                    UserId = userId,
                    AuthProvider = provider,
                    EventType = eventType,
                    Success = success,
                    ErrorMessage = errorMessage,
                    IpAddress = _httpContextAccessor.HttpContext?.Connection?.RemoteIpAddress?.ToString(),
                    UserAgent = _httpContextAccessor.HttpContext?.Request?.Headers["User-Agent"].ToString(),
                    EventDate = DateTime.UtcNow
                };

                _context.SocialLoginAudits.Add(audit);
                await _context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error logging social login event");
                // Don't throw - logging failures shouldn't break authentication
            }
        }

        // IFabOSAuthenticationService implementation (delegate to FabOSAuthenticationService)
        public string GenerateJwtToken(User user) => _fabOSService.GenerateJwtToken(user);
        
        public ClaimsPrincipal? ValidateJwtToken(string token) => _fabOSService.ValidateJwtToken(token);
        
        public async Task<AuthenticationResult> AuthenticateAsync(string email, string password, string productName = null)
            => await SignInWithEmailAsync(email, password, productName);
        
        public async Task<bool> UserHasProductAccessAsync(int userId, string productName)
            => await _fabOSService.UserHasProductAccessAsync(userId, productName);
        
        public async Task<List<string>> GetUserProductsAsync(int userId)
            => await _fabOSService.GetUserProductsAsync(userId);
        
        public async Task<string?> GetUserProductRoleAsync(int userId, string productName)
            => await _fabOSService.GetUserProductRoleAsync(userId, productName);
        
        public async Task<bool> CheckConcurrentUserLimitAsync(string productName, int companyId, int userId)
            => await _fabOSService.CheckConcurrentUserLimitAsync(productName, companyId, userId);
        
        public async Task RecordUserActivityAsync(int userId, string productName)
            => await _fabOSService.RecordUserActivityAsync(userId, productName);

        // Helper methods
        private async Task<Company> GetOrCreateCompanyAsync(string companyName)
        {
            var company = await _context.Companies
                .FirstOrDefaultAsync(c => c.Name == companyName && c.IsActive);

            if (company == null)
            {
                company = new Company
                {
                    Name = companyName,
                    Code = companyName.Length >= 3 ? companyName.Substring(0, 3).ToUpper() : companyName.ToUpper(),
                    IsActive = true,
                    CreatedDate = DateTime.UtcNow
                };
                _context.Companies.Add(company);
                await _context.SaveChangesAsync();
            }

            return company;
        }

        private async Task GrantDefaultProductAccessAsync(int userId, int companyId)
        {
            var estimateLicense = await _context.ProductLicenses
                .FirstOrDefaultAsync(pl => pl.CompanyId == companyId && 
                                          pl.ProductName == "Estimate" && 
                                          pl.IsActive);

            if (estimateLicense != null)
            {
                var access = new UserProductAccess
                {
                    UserId = userId,
                    ProductLicenseId = estimateLicense.Id
                };
                _context.UserProductAccess.Add(access);
            }
        }

        private static (string hash, string salt) HashPassword(string password)
        {
            using var hmac = new HMACSHA512();
            var salt = Convert.ToBase64String(hmac.Key);
            var hash = Convert.ToBase64String(hmac.ComputeHash(Encoding.UTF8.GetBytes(password)));
            return (hash, salt);
        }

        private static bool VerifyPassword(string password, string hash, string salt)
        {
            var saltBytes = Convert.FromBase64String(salt);
            using var hmac = new HMACSHA512(saltBytes);
            var computedHash = hmac.ComputeHash(Encoding.UTF8.GetBytes(password));
            return Convert.ToBase64String(computedHash) == hash;
        }

        private static string? GetClaimValue(ClaimsPrincipal principal, string claimType)
        {
            return principal.FindFirst(claimType)?.Value ??
                   principal.FindFirst(c => c.Type.Contains(claimType.Split('/').Last()))?.Value;
        }
    }
}