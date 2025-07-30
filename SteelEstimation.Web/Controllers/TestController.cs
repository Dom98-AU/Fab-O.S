using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SteelEstimation.Infrastructure.Data;
using SteelEstimation.Core.Interfaces;
using SteelEstimation.Infrastructure.Interfaces;

namespace SteelEstimation.Web.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TestController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IAuthenticationService _authService;
    private readonly ILogger<TestController> _logger;

    public TestController(ApplicationDbContext context, IAuthenticationService authService, ILogger<TestController> logger)
    {
        _context = context;
        _authService = authService;
        _logger = logger;
    }

    [HttpGet("db")]
    [Route("/api/test/db")]
    public async Task<IActionResult> TestDatabase()
    {
        try
        {
            var result = new
            {
                ConnectionString = _context.Database.GetConnectionString()?.Replace("Password=", "Password=***"),
                CanConnect = await _context.Database.CanConnectAsync(),
                UserCount = await _context.Users.CountAsync(),
                AdminExists = await _context.Users.AnyAsync(u => u.Email == "admin@steelestimation.com")
            };
            
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Database test failed");
            return StatusCode(500, new 
            { 
                Error = ex.GetType().Name,
                Message = ex.Message,
                Inner = ex.InnerException?.Message
            });
        }
    }

    [HttpPost("login")]
    public async Task<IActionResult> TestLogin([FromBody] LoginRequest request)
    {
        try
        {
            _logger.LogInformation("TestLogin called for {Email}", request.Email);
            var result = await _authService.LoginAsync(request.Email, request.Password);
            
            return Ok(new
            {
                result.Success,
                result.Message,
                User = result.User != null ? new { result.User.Id, result.User.Email } : null
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Test login failed");
            return StatusCode(500, new
            {
                Error = ex.GetType().Name,
                Message = ex.Message,
                Inner = ex.InnerException?.Message
            });
        }
    }
}

public class LoginRequest
{
    public string Email { get; set; } = "";
    public string Password { get; set; } = "";
}