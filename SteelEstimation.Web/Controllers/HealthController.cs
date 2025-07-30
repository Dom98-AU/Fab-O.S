using Microsoft.AspNetCore.Mvc;

namespace SteelEstimation.Web.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HealthController : ControllerBase
{
    [HttpGet]
    [Route("/health")]
    public IActionResult Health()
    {
        return Ok(new { status = "healthy", timestamp = DateTime.UtcNow });
    }
    
    [HttpGet]
    [Route("/api/health")]
    public IActionResult ApiHealth()
    {
        return Ok(new { status = "healthy", timestamp = DateTime.UtcNow });
    }
}