using System;
using System.Collections.Generic;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Interfaces;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services
{
    public class FabOSAuthenticationService : IFabOSAuthenticationService
    {
        private readonly ApplicationDbContext _context;
        private readonly IConfiguration _configuration;
        private readonly ILogger<FabOSAuthenticationService> _logger;
        private readonly string _jwtSecret;
        private readonly string _jwtIssuer;
        private readonly string _jwtAudience;
        private readonly int _jwtExpiryHours;

        public FabOSAuthenticationService(
            ApplicationDbContext context,
            IConfiguration configuration,
            ILogger<FabOSAuthenticationService> logger)
        {
            _context = context;
            _configuration = configuration;
            _logger = logger;
            
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
                var user = await _context.Users
                    .Include(u => u.Company)
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
                await _context.SaveChangesAsync();

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
            return await _context.UserProductAccess
                .AnyAsync(upa => upa.UserId == userId && 
                                upa.ProductLicense.ProductName == productName &&
                                upa.ProductLicense.IsActive &&
                                upa.ProductLicense.ValidUntil > DateTime.UtcNow);
        }

        public async Task<List<string>> GetUserProductsAsync(int userId)
        {
            return await _context.UserProductAccess
                .Where(upa => upa.UserId == userId && 
                             upa.ProductLicense.IsActive &&
                             upa.ProductLicense.ValidUntil > DateTime.UtcNow)
                .Select(upa => upa.ProductLicense.ProductName)
                .Distinct()
                .ToListAsync();
        }

        public async Task<string?> GetUserProductRoleAsync(int userId, string productName)
        {
            var userProductRole = await _context.UserProductRoles
                .Include(upr => upr.ProductRole)
                .Where(upr => upr.UserId == userId && upr.ProductRole.ProductName == productName)
                .Select(upr => upr.ProductRole.RoleName)
                .FirstOrDefaultAsync();

            return userProductRole;
        }

        public async Task<bool> CheckConcurrentUserLimitAsync(string productName, int companyId, int userId)
        {
            var license = await _context.ProductLicenses
                .FirstOrDefaultAsync(pl => pl.CompanyId == companyId && 
                                          pl.ProductName == productName && 
                                          pl.IsActive);

            if (license == null || license.MaxConcurrentUsers == 0)
            {
                return true; // No limit or no license
            }

            // Count active sessions for this product in the last hour
            var oneHourAgo = DateTime.UtcNow.AddHours(-1);
            var activeUsers = await _context.UserProductAccess
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
            var access = await _context.UserProductAccess
                .FirstOrDefaultAsync(upa => upa.UserId == userId &&
                                           upa.ProductLicense.ProductName == productName);

            if (access != null)
            {
                access.LastAccessDate = DateTime.UtcNow;
                await _context.SaveChangesAsync();
            }
        }

        private static bool VerifyPassword(string password, string hash, string salt)
        {
            var saltBytes = Convert.FromBase64String(salt);
            using var hmac = new HMACSHA512(saltBytes);
            var computedHash = hmac.ComputeHash(Encoding.UTF8.GetBytes(password));
            return Convert.ToBase64String(computedHash) == hash;
        }
    }
}