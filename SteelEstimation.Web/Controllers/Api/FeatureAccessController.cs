using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SteelEstimation.Core.DTOs.Admin;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Services;
using SteelEstimation.Infrastructure.Data;
using SteelEstimation.Web.Authentication;

namespace SteelEstimation.Web.Controllers.Api
{
    [ApiController]
    [Route("api/admin/[controller]")]
    [ApiKey]
    public class FeatureAccessController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IFeatureAccessService _featureService;
        private readonly ILogger<FeatureAccessController> _logger;

        public FeatureAccessController(
            ApplicationDbContext context,
            IFeatureAccessService featureService,
            ILogger<FeatureAccessController> logger)
        {
            _context = context;
            _featureService = featureService;
            _logger = logger;
        }

        /// <summary>
        /// Get feature access for a specific company
        /// </summary>
        [HttpGet("{companyId}")]
        public async Task<ActionResult<FeatureAccessDto>> GetFeatureAccess(int companyId)
        {
            try
            {
                var company = await _context.Companies.FindAsync(companyId);
                if (company == null)
                {
                    return NotFound($"Company with ID {companyId} not found");
                }

                var features = await _featureService.GetEnabledFeaturesAsync(companyId);
                
                return Ok(new FeatureAccessDto
                {
                    CompanyId = companyId,
                    CompanyCode = company.Code,
                    EnabledFeatures = features,
                    SyncedAt = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting feature access for company {CompanyId}", companyId);
                return StatusCode(500, "An error occurred while retrieving feature access");
            }
        }

        /// <summary>
        /// Update feature access for a company
        /// </summary>
        [HttpPost("update")]
        public async Task<ActionResult> UpdateFeatureAccess([FromBody] TenantFeatureUpdateDto updateDto)
        {
            try
            {
                var company = await _context.Companies.FindAsync(updateDto.CompanyId);
                if (company == null)
                {
                    return NotFound($"Company with ID {updateDto.CompanyId} not found");
                }

                // Remove existing features for this company
                var existingFeatures = await _context.FeatureCache
                    .Where(f => f.CompanyId == updateDto.CompanyId)
                    .ToListAsync();
                
                _context.FeatureCache.RemoveRange(existingFeatures);

                // Add updated features
                foreach (var feature in updateDto.Features)
                {
                    _context.FeatureCache.Add(new FeatureCache
                    {
                        CompanyId = updateDto.CompanyId,
                        FeatureCode = feature.FeatureCode,
                        FeatureName = feature.FeatureCode, // Will be updated by sync
                        IsEnabled = feature.IsEnabled,
                        EnabledUntil = feature.EnabledUntil,
                        LastSyncedAt = DateTime.UtcNow,
                        ExpiresAt = DateTime.UtcNow.AddDays(7) // Cache for 7 days
                    });
                }

                await _context.SaveChangesAsync();

                // Clear cache
                await _featureService.ClearCacheAsync(updateDto.CompanyId);

                _logger.LogInformation("Updated feature access for company {CompanyId}", updateDto.CompanyId);
                
                return Ok(new { message = "Feature access updated successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating feature access for company {CompanyId}", updateDto.CompanyId);
                return StatusCode(500, "An error occurred while updating feature access");
            }
        }

        /// <summary>
        /// Bulk update features for multiple companies
        /// </summary>
        [HttpPost("bulk-update")]
        public async Task<ActionResult> BulkUpdateFeatureAccess([FromBody] BulkFeatureUpdateDto bulkUpdateDto)
        {
            try
            {
                var companies = await _context.Companies
                    .Where(c => bulkUpdateDto.CompanyIds.Contains(c.Id))
                    .ToListAsync();

                if (companies.Count != bulkUpdateDto.CompanyIds.Count)
                {
                    return BadRequest("One or more company IDs are invalid");
                }

                foreach (var companyId in bulkUpdateDto.CompanyIds)
                {
                    // Remove existing features
                    var existingFeatures = await _context.FeatureCache
                        .Where(f => f.CompanyId == companyId)
                        .ToListAsync();
                    
                    _context.FeatureCache.RemoveRange(existingFeatures);

                    // Add updated features
                    foreach (var feature in bulkUpdateDto.Features)
                    {
                        _context.FeatureCache.Add(new FeatureCache
                        {
                            CompanyId = companyId,
                            FeatureCode = feature.FeatureCode,
                            FeatureName = feature.FeatureCode,
                            IsEnabled = feature.IsEnabled,
                            EnabledUntil = feature.EnabledUntil,
                            LastSyncedAt = DateTime.UtcNow,
                            ExpiresAt = DateTime.UtcNow.AddDays(7)
                        });
                    }

                    // Clear cache for this company
                    await _featureService.ClearCacheAsync(companyId);
                }

                await _context.SaveChangesAsync();

                _logger.LogInformation("Bulk updated feature access for {Count} companies", bulkUpdateDto.CompanyIds.Count);
                
                return Ok(new { message = $"Feature access updated for {bulkUpdateDto.CompanyIds.Count} companies" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during bulk feature update");
                return StatusCode(500, "An error occurred during bulk update");
            }
        }

        /// <summary>
        /// Get all feature groups
        /// </summary>
        [HttpGet("groups")]
        public async Task<ActionResult<List<FeatureGroupDto>>> GetFeatureGroups()
        {
            try
            {
                var groups = await _context.FeatureGroups
                    .Where(g => g.IsActive)
                    .OrderBy(g => g.DisplayOrder)
                    .Select(g => new FeatureGroupDto
                    {
                        Code = g.Code,
                        Name = g.Name,
                        Description = g.Description ?? string.Empty,
                        DisplayOrder = g.DisplayOrder,
                        Features = new List<FeatureDto>() // Admin portal will populate this
                    })
                    .ToListAsync();

                return Ok(groups);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting feature groups");
                return StatusCode(500, "An error occurred while retrieving feature groups");
            }
        }
    }
}