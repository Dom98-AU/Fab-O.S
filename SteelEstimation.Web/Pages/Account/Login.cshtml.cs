using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using SteelEstimation.Web.Services;
using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Interfaces;

namespace SteelEstimation.Web.Pages.Account;

public class LoginModel : PageModel
{
    private readonly IFabOSAuthenticationService _authService;
    private readonly ICookieAuthenticationService _cookieAuthService;
    private readonly IMultiAuthService _multiAuthService;
    private readonly ILogger<LoginModel> _logger;

    public LoginModel(
        IFabOSAuthenticationService authService,
        ICookieAuthenticationService cookieAuthService,
        IMultiAuthService multiAuthService,
        ILogger<LoginModel> logger)
    {
        _authService = authService;
        _cookieAuthService = cookieAuthService;
        _multiAuthService = multiAuthService;
        _logger = logger;
    }

    [BindProperty]
    public InputModel Input { get; set; } = new();

    public string? ReturnUrl { get; set; }
    
    public List<OAuthProviderSettings> EnabledProviders { get; set; } = new();

    public class InputModel
    {
        [Required]
        [Display(Name = "Email or Username")]
        public string Email { get; set; } = string.Empty;

        [Required]
        [DataType(DataType.Password)]
        public string Password { get; set; } = string.Empty;
    }

    public async Task OnGetAsync(string? returnUrl = null)
    {
        ReturnUrl = returnUrl ?? Url.Content("~/");
        
        // Load enabled OAuth providers
        try
        {
            EnabledProviders = await _multiAuthService.GetEnabledProvidersAsync();
        }
        catch (Exception ex)
        {
            // If OAuth table doesn't exist, just continue without OAuth providers
            _logger.LogWarning(ex, "Could not load OAuth providers - table may not exist");
            EnabledProviders = new List<OAuthProviderSettings>();
        }
    }

    public async Task<IActionResult> OnPostAsync(string? returnUrl = null)
    {
        returnUrl ??= Url.Content("~/");

        if (!ModelState.IsValid)
        {
            return Page();
        }

        try
        {
            // Use the FabOS authentication service to validate credentials
            var result = await _authService.AuthenticateAsync(Input.Email, Input.Password);

            if (result.Success && result.User != null)
            {
                _logger.LogInformation("User {Email} logged in.", Input.Email);

                // Get user roles from the user entity
                var primaryRole = result.User.RoleNames.FirstOrDefault() ?? "Viewer";

                // Get user products
                var userProducts = await _authService.GetUserProductsAsync(result.User.Id);

                // Sign in with cookies using the service
                await _cookieAuthService.SignInAsync(
                    HttpContext,
                    result.User.Username,
                    primaryRole,
                    result.User.Id.ToString(),
                    result.User.Email ?? "",
                    result.User.CompanyId.ToString(),
                    result.User.Company?.Name ?? "Unknown Company",
                    null, // tenantId
                    userProducts
                );

                // Check if user needs to complete setup
                if (!result.User.IsEmailConfirmed || string.IsNullOrEmpty(result.User.FirstName))
                {
                    return LocalRedirect("/welcome");
                }

                return LocalRedirect(returnUrl);
            }

            ModelState.AddModelError(string.Empty, result.Message ?? "Invalid login attempt.");
            return Page();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during login for user {Email}", Input.Email);
            ModelState.AddModelError(string.Empty, "An error occurred during login. Please try again.");
            return Page();
        }
    }
    
    public async Task<IActionResult> OnPostExternalLoginAsync(string provider, string? returnUrl = null)
    {
        returnUrl ??= Url.Content("~/");
        
        // Check if provider is enabled
        if (!await _multiAuthService.IsProviderEnabledAsync(provider))
        {
            ModelState.AddModelError(string.Empty, "This login provider is not available.");
            return Page();
        }
        
        // Request a redirect to the external login provider
        var redirectUrl = Url.Page("./Login", pageHandler: "ExternalLoginCallback", values: new { returnUrl });
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
    
    public async Task<IActionResult> OnGetExternalLoginCallbackAsync(string? returnUrl = null, string? remoteError = null)
    {
        returnUrl ??= Url.Content("~/");
        
        if (remoteError != null)
        {
            ModelState.AddModelError(string.Empty, $"Error from external provider: {remoteError}");
            return Page();
        }
        
        var info = await HttpContext.AuthenticateAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        if (!info.Succeeded)
        {
            ModelState.AddModelError(string.Empty, "Error loading external login information.");
            return Page();
        }
        
        var provider = info.Properties?.Items["LoginProvider"];
        if (string.IsNullOrEmpty(provider))
        {
            ModelState.AddModelError(string.Empty, "Error loading external login information.");
            return Page();
        }
        
        // Sign in with external provider
        var result = await _multiAuthService.SignInWithSocialAsync(provider, info.Principal!);
        
        if (result.Success && result.User != null)
        {
            _logger.LogInformation("User {Email} logged in with {Provider}.", result.User.Email, provider);
            
            // Get user roles from the user entity
            var primaryRole = result.User.RoleNames.FirstOrDefault() ?? "Viewer";
            
            // Get user products
            var userProducts = await _authService.GetUserProductsAsync(result.User.Id);
            
            // Sign in with cookies
            await _cookieAuthService.SignInAsync(
                HttpContext,
                result.User.Username,
                primaryRole,
                result.User.Id.ToString(),
                result.User.Email ?? "",
                result.User.CompanyId.ToString(),
                result.User.Company?.Name ?? "Unknown Company",
                null, // tenantId
                userProducts
            );
            
            // Check if new user needs to complete profile
            if (result.IsNewUser && string.IsNullOrEmpty(result.User.FirstName))
            {
                return LocalRedirect("/welcome");
            }
            
            return LocalRedirect(returnUrl);
        }
        
        ModelState.AddModelError(string.Empty, result.ErrorMessage ?? "Authentication failed.");
        return Page();
    }
}