using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SteelEstimation.Infrastructure.Data;
using System.Text;

namespace SteelEstimation.Web.Controllers;

[ApiController]
[Route("api/[controller]")]
public class DbTestController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IConfiguration _configuration;
    private readonly ILogger<DbTestController> _logger;

    public DbTestController(ApplicationDbContext context, IConfiguration configuration, ILogger<DbTestController> logger)
    {
        _context = context;
        _configuration = configuration;
        _logger = logger;
    }

    [HttpGet]
    [Route("/dbtest")]
    public async Task<ContentResult> TestDatabase()
    {
        var results = new StringBuilder();
        results.AppendLine("<!DOCTYPE html>");
        results.AppendLine("<html><head><title>Database Test</title>");
        results.AppendLine("<link href=\"https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css\" rel=\"stylesheet\" />");
        results.AppendLine("</head><body>");
        results.AppendLine("<div class=\"container mt-4\">");
        results.AppendLine("<h1>Database Connection Test</h1>");
        results.AppendLine("<pre class=\"border p-3\">");

        try
        {
            var connectionString = _configuration.GetConnectionString("DefaultConnection");
            results.AppendLine($"1. Connection String: {connectionString?.Replace("Password=", "Password=***")}");
            
            results.AppendLine($"2. DbContext: {(_context != null ? "OK" : "NULL")}");
            
            if (_context != null)
            {
                results.AppendLine("3. Testing connection...");
                try
                {
                    var canConnect = await _context.Database.CanConnectAsync();
                    results.AppendLine($"   Can Connect: {canConnect}");
                    
                    if (canConnect)
                    {
                        var userCount = await _context.Users.CountAsync();
                        results.AppendLine($"4. User Count: {userCount}");
                        
                        var adminUser = await _context.Users.FirstOrDefaultAsync(u => u.Email == "admin@steelestimation.com");
                        results.AppendLine($"5. Admin User Exists: {(adminUser != null ? "Yes" : "No")}");
                        if (adminUser != null)
                        {
                            results.AppendLine($"   Admin ID: {adminUser.Id}");
                            results.AppendLine($"   Admin Email: {adminUser.Email}");
                        }
                    }
                }
                catch (Exception dbEx)
                {
                    results.AppendLine($"ERROR: {dbEx.GetType().FullName}");
                    results.AppendLine($"Message: {dbEx.Message}");
                    
                    var inner = dbEx.InnerException;
                    int level = 1;
                    while (inner != null && level <= 3)
                    {
                        results.AppendLine($"Inner {level}: {inner.GetType().FullName}");
                        results.AppendLine($"Inner {level} Message: {inner.Message}");
                        inner = inner.InnerException;
                        level++;
                    }
                }
            }
        }
        catch (Exception ex)
        {
            results.AppendLine($"GENERAL ERROR: {ex.Message}");
            _logger.LogError(ex, "Database test failed");
        }

        results.AppendLine("</pre>");
        results.AppendLine("<a href=\"/\" class=\"btn btn-primary\">Home</a>");
        results.AppendLine("</div></body></html>");

        return Content(results.ToString(), "text/html");
    }
}