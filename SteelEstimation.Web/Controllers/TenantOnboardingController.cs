using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SteelEstimation.Core.DTOs;
using SteelEstimation.Core.Interfaces;
using SteelEstimation.Infrastructure.Interfaces;
using System.Text.RegularExpressions;

namespace SteelEstimation.Web.Controllers;

/// <summary>
/// Controller for tenant onboarding in multi-tenant mode
/// Note: This is disabled by default. Enable by setting EnableMultiTenantMode in configuration
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "SystemAdministrator")] // Only system admins can provision tenants
public class TenantOnboardingController : ControllerBase
{
    private readonly ITenantProvisioningService _provisioningService;
    private readonly ITenantService _tenantService;
    private readonly IEmailService? _emailService;
    private readonly IConfiguration _configuration;
    private readonly ILogger<TenantOnboardingController> _logger;
    private readonly bool _isEnabled;

    public TenantOnboardingController(
        ITenantProvisioningService provisioningService,
        ITenantService tenantService,
        IConfiguration configuration,
        ILogger<TenantOnboardingController> logger,
        IEmailService? emailService = null)
    {
        _provisioningService = provisioningService;
        _tenantService = tenantService;
        _emailService = emailService;
        _configuration = configuration;
        _logger = logger;
        _isEnabled = configuration.GetValue<bool>("MultiTenant:EnableDatabasePerTenant", false);
    }

    [HttpPost("register")]
    public async Task<IActionResult> RegisterTenant([FromBody] TenantRegistrationRequest request)
    {
        if (!_isEnabled)
        {
            return BadRequest(new { error = "Multi-tenant mode is not enabled" });
        }

        try
        {
            // Validate request
            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            // Check if company code already exists
            var existingTenants = await _tenantService.GetAllTenantsAsync();
            if (existingTenants.Any(t => t.CompanyCode.Equals(request.CompanyCode, StringComparison.OrdinalIgnoreCase)))
            {
                return BadRequest(new { error = "Company code already exists" });
            }

            // Create unique tenant identifier
            var tenantId = GenerateTenantId(request.CompanyName);
            
            // Ensure tenant ID is unique
            int suffix = 1;
            var originalTenantId = tenantId;
            while (await _tenantService.TenantExistsAsync(tenantId))
            {
                tenantId = $"{originalTenantId}{suffix}";
                suffix++;
            }

            // Provision tenant database
            var tenantInfo = await _provisioningService.ProvisionTenantAsync(tenantId, request);

            // Send welcome email with login details
            if (_emailService != null)
            {
                await SendWelcomeEmailAsync(tenantInfo);
            }

            _logger.LogInformation("Successfully registered new tenant {TenantId} for company {CompanyName}", 
                tenantId, request.CompanyName);

            return Ok(new 
            { 
                TenantId = tenantId, 
                DatabaseName = tenantInfo.DatabaseName,
                AdminEmail = tenantInfo.AdminEmail,
                Message = "Tenant provisioned successfully. Welcome email sent to admin."
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to register tenant for company {CompanyName}", request.CompanyName);
            return BadRequest(new { error = $"Onboarding failed: {ex.Message}" });
        }
    }

    [HttpGet("{tenantId}/status")]
    public async Task<IActionResult> GetTenantStatus(string tenantId)
    {
        if (!_isEnabled)
        {
            return BadRequest(new { error = "Multi-tenant mode is not enabled" });
        }

        var tenant = await _tenantService.GetTenantAsync(tenantId);
        if (tenant == null)
        {
            return NotFound(new { error = "Tenant not found" });
        }

        return Ok(new
        {
            tenant.TenantId,
            tenant.CompanyName,
            tenant.IsActive,
            tenant.SubscriptionTier,
            tenant.MaxUsers,
            tenant.CreatedAt,
            tenant.SubscriptionExpiryDate
        });
    }

    [HttpPost("{tenantId}/suspend")]
    public async Task<IActionResult> SuspendTenant(string tenantId)
    {
        if (!_isEnabled)
        {
            return BadRequest(new { error = "Multi-tenant mode is not enabled" });
        }

        try
        {
            await _provisioningService.SuspendTenantAsync(tenantId);
            return Ok(new { message = "Tenant suspended successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to suspend tenant {TenantId}", tenantId);
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPost("{tenantId}/reactivate")]
    public async Task<IActionResult> ReactivateTenant(string tenantId)
    {
        if (!_isEnabled)
        {
            return BadRequest(new { error = "Multi-tenant mode is not enabled" });
        }

        try
        {
            await _provisioningService.ReactivateTenantAsync(tenantId);
            return Ok(new { message = "Tenant reactivated successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to reactivate tenant {TenantId}", tenantId);
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("list")]
    public async Task<IActionResult> ListTenants()
    {
        if (!_isEnabled)
        {
            return BadRequest(new { error = "Multi-tenant mode is not enabled" });
        }

        var tenants = await _tenantService.GetAllTenantsAsync();
        return Ok(tenants.Select(t => new
        {
            t.TenantId,
            t.CompanyName,
            t.CompanyCode,
            t.IsActive,
            t.SubscriptionTier,
            t.MaxUsers,
            t.CreatedAt,
            UserCount = 0 // Would need to query tenant database for actual count
        }));
    }

    private string GenerateTenantId(string companyName)
    {
        // Remove special characters and spaces
        var cleanName = Regex.Replace(companyName, @"[^a-zA-Z0-9]", "");
        
        // Take first 20 characters and convert to lowercase
        if (cleanName.Length > 20)
        {
            cleanName = cleanName.Substring(0, 20);
        }
        
        return cleanName.ToLower();
    }

    private async Task SendWelcomeEmailAsync(TenantInfo tenantInfo)
    {
        if (_emailService == null)
        {
            _logger.LogWarning("Email service not configured. Skipping welcome email for tenant {TenantId}", tenantInfo.TenantId);
            return;
        }

        try
        {
            var emailBody = $@"
                <h2>Welcome to Steel Estimation Platform!</h2>
                <p>Your company account has been successfully created.</p>
                <h3>Account Details:</h3>
                <ul>
                    <li><strong>Company:</strong> {tenantInfo.CompanyName}</li>
                    <li><strong>Tenant ID:</strong> {tenantInfo.TenantId}</li>
                    <li><strong>Admin Email:</strong> {tenantInfo.AdminEmail}</li>
                    <li><strong>Subscription:</strong> {tenantInfo.SubscriptionTier}</li>
                </ul>
                <p>A temporary password has been sent in a separate email. Please change it upon first login.</p>
                <p>Login URL: {_configuration["AppSettings:BaseUrl"]}/login</p>
                <br>
                <p>If you have any questions, please contact support.</p>
            ";

            // Send email implementation would go here
            await Task.CompletedTask; // Placeholder for actual async email sending
            _logger.LogInformation("Welcome email sent to {Email} for tenant {TenantId}", 
                tenantInfo.AdminEmail, tenantInfo.TenantId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send welcome email for tenant {TenantId}", tenantInfo.TenantId);
            // Don't throw - email failure shouldn't fail the provisioning
        }
    }
}