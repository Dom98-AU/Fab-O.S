using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Interfaces;
using System.Security.Claims;

namespace SteelEstimation.Web.Pages.Account.Manage;

[Authorize]
public class LinkedAccountsModel : PageModel
{
    private readonly IMultiAuthService _multiAuthService;
    private readonly IUserService _userService;
    private readonly ILogger<LinkedAccountsModel> _logger;

    public LinkedAccountsModel(
        IMultiAuthService multiAuthService,
        IUserService userService,
        ILogger<LinkedAccountsModel> logger)
    {
        _multiAuthService = multiAuthService;
        _userService = userService;
        _logger = logger;
    }

    public List<UserAuthMethod> UserAuthMethods { get; set; } = new();
    public List<OAuthProviderSettings> AvailableProviders { get; set; } = new();
    public bool HasPassword { get; set; }
    
    public async Task<IActionResult> OnGetAsync()
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return RedirectToPage("/Account/Login");
        }
        
        await LoadDataAsync(userId.Value);
        return Page();
    }
    
    public async Task<IActionResult> OnPostLinkAsync(string provider)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return RedirectToPage("/Account/Login");
        }
        
        // Check if provider is enabled
        if (!await _multiAuthService.IsProviderEnabledAsync(provider))
        {
            TempData["StatusMessage"] = "This provider is not available.";
            return RedirectToPage();
        }
        
        // Request a redirect to the external login provider
        var redirectUrl = Url.Page("./LinkedAccounts", pageHandler: "LinkCallback");
        var properties = new AuthenticationProperties
        {
            RedirectUri = redirectUrl,
            Items =
            {
                ["LoginProvider"] = provider
            }
        };
        
        return new ChallengeResult(provider, properties);
    }
    
    public async Task<IActionResult> OnGetLinkCallbackAsync(string? remoteError = null)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return RedirectToPage("/Account/Login");
        }
        
        if (remoteError != null)
        {
            TempData["StatusMessage"] = $"Error from external provider: {remoteError}";
            return RedirectToPage();
        }
        
        var info = await HttpContext.AuthenticateAsync();
        if (!info.Succeeded)
        {
            TempData["StatusMessage"] = "Error loading external login information.";
            return RedirectToPage();
        }
        
        var provider = info.Properties?.Items["LoginProvider"];
        if (string.IsNullOrEmpty(provider))
        {
            TempData["StatusMessage"] = "Error loading external login information.";
            return RedirectToPage();
        }
        
        // Link the account
        var success = await _multiAuthService.LinkSocialAccountAsync(userId.Value, provider, info.Principal!);
        
        if (success)
        {
            TempData["StatusMessage"] = $"Successfully linked {provider} account.";
        }
        else
        {
            TempData["StatusMessage"] = $"Failed to link {provider} account. It may already be linked to another account.";
        }
        
        return RedirectToPage();
    }
    
    public async Task<IActionResult> OnPostUnlinkAsync(string provider)
    {
        var userId = GetCurrentUserId();
        if (userId == null)
        {
            return RedirectToPage("/Account/Login");
        }
        
        var success = await _multiAuthService.UnlinkSocialAccountAsync(userId.Value, provider);
        
        if (success)
        {
            TempData["StatusMessage"] = $"Successfully unlinked {provider} account.";
        }
        else
        {
            TempData["StatusMessage"] = $"Cannot unlink {provider} account. You must have at least one sign-in method.";
        }
        
        return RedirectToPage();
    }
    
    private async Task LoadDataAsync(int userId)
    {
        // Get user's auth methods
        UserAuthMethods = await _multiAuthService.GetUserAuthMethodsAsync(userId);
        
        // Get all enabled providers
        var allProviders = await _multiAuthService.GetEnabledProvidersAsync();
        
        // Filter out already linked providers
        var linkedProviders = UserAuthMethods.Select(m => m.AuthProvider).ToHashSet();
        AvailableProviders = allProviders.Where(p => !linkedProviders.Contains(p.ProviderName)).ToList();
        
        // Check if user has password
        var user = await _userService.GetUserByIdAsync(userId);
        HasPassword = user?.HasPassword ?? false;
    }
    
    private int? GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (int.TryParse(userIdClaim, out var userId))
        {
            return userId;
        }
        return null;
    }
}