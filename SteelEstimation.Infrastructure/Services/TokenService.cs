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
    public class TokenService : ITokenService
    {
        private readonly IConfiguration _configuration;
        private readonly ApplicationDbContext _context;
        private readonly ILogger<TokenService> _logger;

        public TokenService(
            IConfiguration configuration,
            ApplicationDbContext context,
            ILogger<TokenService> logger)
        {
            _configuration = configuration;
            _context = context;
            _logger = logger;
        }

        public async Task<string> GenerateTokenAsync(User user)
        {
            try
            {
                var tokenHandler = new JwtSecurityTokenHandler();
                var key = Encoding.UTF8.GetBytes(_configuration["JwtSettings:SecretKey"] ?? GenerateDefaultKey());
                
                var claims = new List<Claim>
                {
                    new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                    new Claim(ClaimTypes.Name, user.Username),
                    new Claim(ClaimTypes.Email, user.Email),
                    new Claim("FullName", user.FullName),
                    new Claim("SecurityStamp", user.SecurityStamp)
                };

                // Add role claims
                foreach (var role in user.RoleNames)
                {
                    claims.Add(new Claim(ClaimTypes.Role, role));
                }

                var tokenDescriptor = new SecurityTokenDescriptor
                {
                    Subject = new ClaimsIdentity(claims),
                    Expires = DateTime.UtcNow.AddHours(
                        _configuration.GetValue<int>("JwtSettings:ExpiryHours", 24)),
                    Issuer = _configuration["JwtSettings:Issuer"],
                    Audience = _configuration["JwtSettings:Audience"],
                    SigningCredentials = new SigningCredentials(
                        new SymmetricSecurityKey(key),
                        SecurityAlgorithms.HmacSha256Signature)
                };

                var token = tokenHandler.CreateToken(tokenDescriptor);
                return await Task.FromResult(tokenHandler.WriteToken(token));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating access token for user {UserId}", user.Id);
                throw;
            }
        }


        public async Task<ClaimsPrincipal?> ValidateTokenAsync(string token)
        {
            try
            {
                var tokenHandler = new JwtSecurityTokenHandler();
                var key = Encoding.UTF8.GetBytes(_configuration["JwtSettings:SecretKey"] ?? GenerateDefaultKey());

                var validationParameters = new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(key),
                    ValidateIssuer = true,
                    ValidIssuer = _configuration["JwtSettings:Issuer"],
                    ValidateAudience = true,
                    ValidAudience = _configuration["JwtSettings:Audience"],
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.Zero
                };

                var principal = tokenHandler.ValidateToken(token, validationParameters, out _);
                
                // Validate security stamp
                var userIdClaim = principal.FindFirst(ClaimTypes.NameIdentifier);
                var securityStampClaim = principal.FindFirst("SecurityStamp");
                
                if (userIdClaim != null && securityStampClaim != null)
                {
                    var userId = int.Parse(userIdClaim.Value);
                    var user = await _context.Users.FindAsync(userId);
                    
                    if (user == null || user.SecurityStamp != securityStampClaim.Value)
                    {
                        return null;
                    }
                }

                return principal;
            }
            catch (Exception ex)
            {
                _logger.LogDebug(ex, "Token validation failed");
                return null;
            }
        }


        public async Task<bool> RevokeTokenAsync(string token)
        {
            try
            {
                // TODO: Implement token revocation (blacklist)
                // For now, return true
                return await Task.FromResult(true);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error revoking token");
                return false;
            }
        }

        private string GenerateDefaultKey()
        {
            // Generate a default key if none is configured
            // This should only be used in development
            _logger.LogWarning("Using generated JWT key. Configure JwtSettings:SecretKey for production!");
            return "ThisIsADefaultKeyForDevelopmentOnly-PleaseChangeInProduction!";
        }
    }
}