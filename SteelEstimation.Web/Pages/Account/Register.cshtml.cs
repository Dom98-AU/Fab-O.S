using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using SteelEstimation.Web.Services;
using System.ComponentModel.DataAnnotations;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Interfaces;

namespace SteelEstimation.Web.Pages.Account;

public class RegisterModel : PageModel
{
    private readonly IMultiAuthService _multiAuthService;
    private readonly IFabOSAuthenticationService _authService;
    private readonly ICookieAuthenticationService _cookieAuthService;
    private readonly ILogger<RegisterModel> _logger;

    public RegisterModel(
        IMultiAuthService multiAuthService,
        IFabOSAuthenticationService authService,
        ICookieAuthenticationService cookieAuthService,
        ILogger<RegisterModel> logger)
    {
        _multiAuthService = multiAuthService;
        _authService = authService;
        _cookieAuthService = cookieAuthService;
        _logger = logger;
    }

    [BindProperty]
    public InputModel Input { get; set; } = new();

    public string? ReturnUrl { get; set; }
    
    public List<OAuthProviderSettings> EnabledProviders { get; set; } = new();

    public class InputModel
    {
        [Required]
        [Display(Name = "Username")]
        [StringLength(50, MinimumLength = 3)]
        public string Username { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        [Display(Name = "Email")]
        public string Email { get; set; } = string.Empty;

        [Required]
        [Display(Name = "Company Name")]
        [StringLength(200, MinimumLength = 2)]
        public string CompanyName { get; set; } = string.Empty;

        [Required]
        [StringLength(100, ErrorMessage = "The {0} must be at least {2} and at max {1} characters long.", MinimumLength = 6)]
        [DataType(DataType.Password)]
        [Display(Name = "Password")]
        public string Password { get; set; } = string.Empty;

        [DataType(DataType.Password)]
        [Display(Name = "Confirm password")]
        [Compare("Password", ErrorMessage = "The password and confirmation password do not match.")]
        public string ConfirmPassword { get; set; } = string.Empty;
    }

    public async Task OnGetAsync(string? returnUrl = null)
    {
        ReturnUrl = returnUrl ?? Url.Content("~/");
        
        // Load enabled OAuth providers
        EnabledProviders = await _multiAuthService.GetEnabledProvidersAsync();
    }

    public async Task<IActionResult> OnPostAsync(string? returnUrl = null)
    {
        returnUrl ??= Url.Content("~/");
        
        if (!ModelState.IsValid)
        {
            EnabledProviders = await _multiAuthService.GetEnabledProvidersAsync();
            return Page();
        }

        try
        {
            // Use multi-auth service for email signup
            var result = await _multiAuthService.SignUpWithEmailAsync(
                Input.Email, 
                Input.Password, 
                Input.Username, 
                Input.CompanyName);

            if (result.Success && result.User != null)
            {
                _logger.LogInformation("User {Email} created a new account with password.", Input.Email);

                // If email confirmation is required, redirect to confirmation page
                if (result.RequiresEmailConfirmation)
                {
                    return RedirectToPage("./RegisterConfirmation", new { email = Input.Email });
                }

                // Otherwise, sign them in
                var roles = await _authService.GetUserRolesAsync(result.User.Id);
                var primaryRole = roles.FirstOrDefault() ?? "Viewer";

                await _cookieAuthService.SignInAsync(
                    HttpContext,
                    result.User.Username,
                    primaryRole,
                    result.User.Id.ToString(),
                    result.User.Email ?? "",
                    result.User.CompanyId.ToString(),
                    result.User.Company?.Name ?? Input.CompanyName
                );

                return LocalRedirect("/welcome");
            }

            ModelState.AddModelError(string.Empty, result.ErrorMessage ?? "Registration failed.");
            EnabledProviders = await _multiAuthService.GetEnabledProvidersAsync();
            return Page();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during registration for user {Email}", Input.Email);
            ModelState.AddModelError(string.Empty, "An error occurred during registration. Please try again.");
            EnabledProviders = await _multiAuthService.GetEnabledProvidersAsync();
            return Page();
        }
    }
    
    public async Task<IActionResult> OnPostExternalRegisterAsync(string provider, string? returnUrl = null)
    {
        returnUrl ??= Url.Content("~/");
        
        // Check if provider is enabled
        if (!await _multiAuthService.IsProviderEnabledAsync(provider))
        {
            ModelState.AddModelError(string.Empty, "This registration provider is not available.");
            EnabledProviders = await _multiAuthService.GetEnabledProvidersAsync();
            return Page();
        }
        
        // Request a redirect to the external login provider
        var redirectUrl = Url.Page("./Register", pageHandler: "ExternalRegisterCallback", values: new { returnUrl });
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
    
    public async Task<IActionResult> OnGetExternalRegisterCallbackAsync(string? returnUrl = null, string? remoteError = null)
    {
        returnUrl ??= Url.Content("~/");
        
        if (remoteError != null)
        {
            ModelState.AddModelError(string.Empty, $"Error from external provider: {remoteError}");
            EnabledProviders = await _multiAuthService.GetEnabledProvidersAsync();
            return Page();
        }
        
        var info = await HttpContext.AuthenticateAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        if (!info.Succeeded)
        {
            ModelState.AddModelError(string.Empty, "Error loading external registration information.");
            EnabledProviders = await _multiAuthService.GetEnabledProvidersAsync();
            return Page();
        }
        
        var provider = info.Properties?.Items["LoginProvider"];
        if (string.IsNullOrEmpty(provider))
        {
            ModelState.AddModelError(string.Empty, "Error loading external registration information.");
            EnabledProviders = await _multiAuthService.GetEnabledProvidersAsync();
            return Page();
        }
        
        // Sign up with external provider
        var result = await _multiAuthService.SignUpWithSocialAsync(provider, info.Principal!);
        
        if (result.Success && result.User != null)
        {
            _logger.LogInformation("User {Email} registered with {Provider}.", result.User.Email, provider);
            
            // Get user roles
            var roles = await _authService.GetUserRolesAsync(result.User.Id);
            var primaryRole = roles.FirstOrDefault() ?? "Viewer";
            
            // Sign in with cookies
            await _cookieAuthService.SignInAsync(
                HttpContext,
                result.User.Username,
                primaryRole,
                result.User.Id.ToString(),
                result.User.Email ?? "",
                result.User.CompanyId.ToString(),
                result.User.Company?.Name ?? "Unknown Company"
            );
            
            // New users should complete their profile
            return LocalRedirect("/welcome");
        }
        
        ModelState.AddModelError(string.Empty, result.ErrorMessage ?? "Registration failed.");
        EnabledProviders = await _multiAuthService.GetEnabledProvidersAsync();
        return Page();
    }
}