using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using SteelEstimation.Web.Services;
using System.ComponentModel.DataAnnotations;
using System.Security.Claims;

namespace SteelEstimation.Web.Pages.Account;

public class LoginModel : PageModel
{
    private readonly SteelEstimation.Core.Interfaces.IAuthenticationService _authService;
    private readonly ICookieAuthenticationService _cookieAuthService;
    private readonly ILogger<LoginModel> _logger;

    public LoginModel(
        SteelEstimation.Core.Interfaces.IAuthenticationService authService,
        ICookieAuthenticationService cookieAuthService,
        ILogger<LoginModel> logger)
    {
        _authService = authService;
        _cookieAuthService = cookieAuthService;
        _logger = logger;
    }

    [BindProperty]
    public InputModel Input { get; set; } = new();

    public string? ReturnUrl { get; set; }

    public class InputModel
    {
        [Required]
        [Display(Name = "Email or Username")]
        public string Email { get; set; } = string.Empty;

        [Required]
        [DataType(DataType.Password)]
        public string Password { get; set; } = string.Empty;
    }

    public void OnGet(string? returnUrl = null)
    {
        ReturnUrl = returnUrl ?? Url.Content("~/");
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
            // Use the authentication service to validate credentials
            var result = await _authService.LoginAsync(Input.Email, Input.Password);

            if (result.Success && result.User != null)
            {
                _logger.LogInformation("User {Email} logged in.", Input.Email);

                // Get user roles
                var roles = await _authService.GetUserRolesAsync(result.User.Id);
                var primaryRole = roles.FirstOrDefault() ?? "Viewer";

                // Sign in with cookies using the service
                await _cookieAuthService.SignInAsync(
                    HttpContext,
                    result.User.Username,
                    primaryRole,
                    result.User.Id.ToString(),
                    result.User.Email ?? "",
                    result.User.CompanyId.ToString(),
                    result.User.Company?.Name ?? "Unknown Company"
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
}