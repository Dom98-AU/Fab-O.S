using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SteelEstimation.Core.DTOs.Admin;
using SteelEstimation.Infrastructure.Data;
using SteelEstimation.Web.Authentication;

namespace SteelEstimation.Web.Controllers.Api
{
    [ApiController]
    [Route("api/admin/[controller]")]
    [ApiKey]
    public class UsageMetricsController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<UsageMetricsController> _logger;

        public UsageMetricsController(
            ApplicationDbContext context,
            ILogger<UsageMetricsController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Get usage metrics for a specific company
        /// </summary>
        [HttpGet("{companyId}")]
        public async Task<ActionResult<CompanyUsageSummaryDto>> GetCompanyMetrics(
            int companyId, 
            [FromQuery] DateTime? startDate = null, 
            [FromQuery] DateTime? endDate = null)
        {
            try
            {
                var company = await _context.Companies.FindAsync(companyId);
                if (company == null)
                {
                    return NotFound($"Company with ID {companyId} not found");
                }

                // Default to last 30 days if no dates provided
                var end = endDate ?? DateTime.UtcNow;
                var start = startDate ?? end.AddDays(-30);

                // Get user metrics
                var activeUsers = await _context.Users
                    .Where(u => u.CompanyId == companyId && u.IsActive)
                    .Where(u => u.LastLoginDate >= start)
                    .CountAsync();

                var totalUsers = await _context.Users
                    .Where(u => u.CompanyId == companyId)
                    .CountAsync();

                // Get project metrics
                var projectQuery = _context.Projects
                    .Where(p => p.Owner.CompanyId == companyId);

                var activeProjects = await projectQuery
                    .Where(p => !p.IsDeleted && p.EstimationStage != "Approved")
                    .CountAsync();

                var totalProjects = await projectQuery
                    .Where(p => !p.IsDeleted)
                    .CountAsync();

                var projectsCreatedInPeriod = await projectQuery
                    .Where(p => p.CreatedDate >= start && p.CreatedDate <= end)
                    .CountAsync();

                // Calculate storage (simplified - count images)
                var imageCount = await _context.ImageUploads
                    .Where(i => i.WeldingItem.Project.Owner.CompanyId == companyId)
                    .CountAsync();
                
                // Estimate storage (assume average 1MB per image)
                var storageGB = Math.Round(imageCount / 1024.0, 2);

                // Get feature usage (from time logs as a proxy)
                var featureUsage = await _context.EstimationTimeLogs
                    .Where(t => t.User.CompanyId == companyId)
                    .Where(t => t.StartTime >= start && t.StartTime <= end)
                    .GroupBy(t => t.PageName)
                    .Select(g => new { Type = g.Key, Count = g.Count() })
                    .ToDictionaryAsync(x => x.Type ?? "Unknown", x => x.Count);

                return Ok(new CompanyUsageSummaryDto
                {
                    CompanyId = companyId,
                    CompanyCode = company.Code,
                    PeriodStart = start,
                    PeriodEnd = end,
                    ActiveUsers = activeUsers,
                    TotalUsers = totalUsers,
                    ActiveProjects = activeProjects,
                    TotalProjects = totalProjects,
                    ProjectsCreatedInPeriod = projectsCreatedInPeriod,
                    FeatureUsageCount = featureUsage,
                    StorageUsedGB = (decimal)storageGB,
                    ApiCallsCount = 0 // Would need to implement API call tracking
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting usage metrics for company {CompanyId}", companyId);
                return StatusCode(500, "An error occurred while retrieving usage metrics");
            }
        }

        /// <summary>
        /// Record a usage metric
        /// </summary>
        [HttpPost("record")]
        public async Task<ActionResult> RecordMetric([FromBody] UsageMetricDto metric)
        {
            try
            {
                // Validate company exists
                var company = await _context.Companies.FindAsync(metric.CompanyId);
                if (company == null)
                {
                    return NotFound($"Company with ID {metric.CompanyId} not found");
                }

                // TODO: Store metrics in a dedicated table
                // For now, just log it
                _logger.LogInformation("Metric recorded: {MetricType} = {Value} for company {CompanyId}", 
                    metric.MetricType, metric.Value, metric.CompanyId);

                return Ok(new { message = "Metric recorded successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error recording metric");
                return StatusCode(500, "An error occurred while recording metric");
            }
        }

        /// <summary>
        /// Get aggregated metrics across all companies
        /// </summary>
        [HttpGet("aggregate")]
        public async Task<ActionResult<object>> GetAggregateMetrics([FromQuery] DateTime? date = null)
        {
            try
            {
                var targetDate = date ?? DateTime.UtcNow.Date;

                var totalCompanies = await _context.Companies.CountAsync(c => c.IsActive);
                var totalUsers = await _context.Users.CountAsync(u => u.IsActive);
                var totalProjects = await _context.Projects.CountAsync(p => !p.IsDeleted);
                
                // Active in last 30 days
                var activeCompanies = await _context.Companies
                    .Where(c => c.IsActive)
                    .Where(c => c.Users.Any(u => u.LastLoginDate >= targetDate.AddDays(-30)))
                    .CountAsync();

                return Ok(new
                {
                    date = targetDate,
                    totalCompanies,
                    activeCompanies,
                    totalUsers,
                    totalProjects,
                    timestamp = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting aggregate metrics");
                return StatusCode(500, "An error occurred while retrieving aggregate metrics");
            }
        }
    }
}