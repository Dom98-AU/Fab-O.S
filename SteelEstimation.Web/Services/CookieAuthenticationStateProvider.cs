using Microsoft.AspNetCore.Components.Authorization;
using System.Security.Claims;

namespace SteelEstimation.Web.Services;

/// <summary>
/// Authentication state provider that works with ASP.NET Core cookie authentication
/// </summary>
public class CookieAuthenticationStateProvider : AuthenticationStateProvider
{
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly ILogger<CookieAuthenticationStateProvider> _logger;

    public CookieAuthenticationStateProvider(
        IHttpContextAccessor httpContextAccessor,
        ILogger<CookieAuthenticationStateProvider> logger)
    {
        _httpContextAccessor = httpContextAccessor;
        _logger = logger;
    }

    public override Task<AuthenticationState> GetAuthenticationStateAsync()
    {
        try
        {
            var httpContext = _httpContextAccessor.HttpContext;
            
            if (httpContext?.User?.Identity?.IsAuthenticated == true)
            {
                _logger.LogDebug("User authenticated: {UserName}", httpContext.User.Identity.Name);
                return Task.FromResult(new AuthenticationState(httpContext.User));
            }
            
            _logger.LogDebug("User not authenticated");
            var anonymous = new ClaimsPrincipal(new ClaimsIdentity());
            return Task.FromResult(new AuthenticationState(anonymous));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting authentication state");
            var anonymous = new ClaimsPrincipal(new ClaimsIdentity());
            return Task.FromResult(new AuthenticationState(anonymous));
        }
    }

    /// <summary>
    /// Notify that authentication state has changed (used after login/logout)
    /// </summary>
    public void NotifyAuthenticationStateChanged()
    {
        NotifyAuthenticationStateChanged(GetAuthenticationStateAsync());
    }
}