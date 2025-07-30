using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using SteelEstimation.Web.Services;

namespace SteelEstimation.Web.Pages.Account;

public class LogoutModel : PageModel
{
    private readonly ICookieAuthenticationService _cookieAuthService;
    private readonly ILogger<LogoutModel> _logger;

    public LogoutModel(
        ICookieAuthenticationService cookieAuthService,
        ILogger<LogoutModel> logger)
    {
        _cookieAuthService = cookieAuthService;
        _logger = logger;
    }

    public async Task<IActionResult> OnGet()
    {
        return await LogoutUser();
    }

    public async Task<IActionResult> OnPost()
    {
        return await LogoutUser();
    }

    private async Task<IActionResult> LogoutUser()
    {
        _logger.LogInformation("User logged out.");
        
        await _cookieAuthService.SignOutAsync(HttpContext);
        
        return LocalRedirect("~/");
    }
}