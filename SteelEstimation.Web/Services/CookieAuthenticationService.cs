using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using System.Security.Claims;

namespace SteelEstimation.Web.Services;

public interface ICookieAuthenticationService
{
    Task SignInAsync(HttpContext httpContext, string username, string role, string userId, 
        string email, string companyId, string companyName, string? tenantId = null);
    Task SignOutAsync(HttpContext httpContext);
    ClaimsPrincipal CreateClaimsPrincipal(string username, string role, string userId, 
        string email, string companyId, string companyName, string? tenantId = null);
}

public class CookieAuthenticationService : ICookieAuthenticationService
{
    private readonly ILogger<CookieAuthenticationService> _logger;

    public CookieAuthenticationService(ILogger<CookieAuthenticationService> logger)
    {
        _logger = logger;
    }

    public async Task SignInAsync(HttpContext httpContext, string username, string role, 
        string userId, string email, string companyId, string companyName, string? tenantId = null)
    {
        try
        {
            var principal = CreateClaimsPrincipal(username, role, userId, email, companyId, companyName, tenantId);
            
            await httpContext.SignInAsync(
                CookieAuthenticationDefaults.AuthenticationScheme,
                principal,
                new AuthenticationProperties
                {
                    IsPersistent = true,
                    ExpiresUtc = DateTimeOffset.UtcNow.AddHours(8),
                    AllowRefresh = true
                });

            _logger.LogInformation("User {Username} signed in with cookie authentication", username);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error signing in user {Username}", username);
            throw;
        }
    }

    public async Task SignOutAsync(HttpContext httpContext)
    {
        try
        {
            await httpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
            _logger.LogInformation("User signed out");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error signing out user");
            throw;
        }
    }

    public ClaimsPrincipal CreateClaimsPrincipal(string username, string role, string userId, 
        string email, string companyId, string companyName, string? tenantId = null)
    {
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.Name, username),
            new Claim(ClaimTypes.NameIdentifier, userId),
            new Claim(ClaimTypes.Email, email ?? string.Empty),
            new Claim("CompanyId", companyId),
            new Claim("CompanyName", companyName ?? string.Empty)
        };

        // Add role claims (support multiple roles)
        if (!string.IsNullOrEmpty(role))
        {
            var roles = role.Split(',', StringSplitOptions.RemoveEmptyEntries);
            foreach (var r in roles)
            {
                claims.Add(new Claim(ClaimTypes.Role, r.Trim()));
            }
        }

        // Add tenant claim for multi-tenant support
        if (!string.IsNullOrEmpty(tenantId))
        {
            claims.Add(new Claim("TenantId", tenantId));
        }

        var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        return new ClaimsPrincipal(identity);
    }
}