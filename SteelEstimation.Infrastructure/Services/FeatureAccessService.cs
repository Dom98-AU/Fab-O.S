using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SteelEstimation.Core.DTOs.Admin;
using SteelEstimation.Core.Interfaces;
using SteelEstimation.Core.Services;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services
{
    public class FeatureAccessService : IFeatureAccessService
    {
        private readonly ApplicationDbContext _context;
        private readonly IAuthenticationService _authService;
        private readonly IMemoryCache _cache;
        private readonly IConfiguration _configuration;
        private readonly ILogger<FeatureAccessService> _logger;
        private const string CACHE_KEY_PREFIX = "features_";
        private readonly TimeSpan _cacheExpiration = TimeSpan.FromMinutes(30);

        public FeatureAccessService(
            ApplicationDbContext context,
            IAuthenticationService authService,
            IMemoryCache cache,
            IConfiguration configuration,
            ILogger<FeatureAccessService> logger)
        {
            _context = context;
            _authService = authService;
            _cache = cache;
            _configuration = configuration;
            _logger = logger;
        }

        public async Task<bool> HasAccessAsync(string featureCode)
        {
            var companyId = await _authService.GetUserCompanyIdAsync();
            if (!companyId.HasValue)
            {
                _logger.LogWarning("No company ID found for current user");
                return false;
            }

            return await HasAccessAsync(companyId.Value, featureCode);
        }

        public async Task<bool> HasAccessAsync(int companyId, string featureCode)
        {
            try
            {
                // Check cache first
                var cacheKey = $"{CACHE_KEY_PREFIX}{companyId}";
                if (_cache.TryGetValue<List<FeatureDto>>(cacheKey, out var cachedFeatures))
                {
                    return cachedFeatures.Any(f => f.Code.Equals(featureCode, StringComparison.OrdinalIgnoreCase) && f.IsEnabled);
                }

                // Load from database
                var features = await LoadFeaturesFromDatabaseAsync(companyId);
                
                // Cache the results
                _cache.Set(cacheKey, features, _cacheExpiration);
                
                return features.Any(f => f.Code.Equals(featureCode, StringComparison.OrdinalIgnoreCase) && f.IsEnabled);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking feature access for company {CompanyId}, feature {FeatureCode}", companyId, featureCode);
                // In case of error, default to false (deny access)
                return false;
            }
        }

        public async Task<List<FeatureDto>> GetEnabledFeaturesAsync()
        {
            var companyId = await _authService.GetUserCompanyIdAsync();
            if (!companyId.HasValue)
            {
                return new List<FeatureDto>();
            }

            return await GetEnabledFeaturesAsync(companyId.Value);
        }

        public async Task<List<FeatureDto>> GetEnabledFeaturesAsync(int companyId)
        {
            try
            {
                // Check cache first
                var cacheKey = $"{CACHE_KEY_PREFIX}{companyId}";
                if (_cache.TryGetValue<List<FeatureDto>>(cacheKey, out var cachedFeatures))
                {
                    return cachedFeatures.Where(f => f.IsEnabled).ToList();
                }

                // Load from database
                var features = await LoadFeaturesFromDatabaseAsync(companyId);
                
                // Cache the results
                _cache.Set(cacheKey, features, _cacheExpiration);
                
                return features.Where(f => f.IsEnabled).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting enabled features for company {CompanyId}", companyId);
                return new List<FeatureDto>();
            }
        }

        public async Task<List<FeatureGroupDto>> GetFeatureGroupsAsync()
        {
            var companyId = await _authService.GetUserCompanyIdAsync();
            if (!companyId.HasValue)
            {
                return new List<FeatureGroupDto>();
            }

            try
            {
                var features = await GetEnabledFeaturesAsync(companyId.Value);
                var groups = await _context.FeatureGroups
                    .Where(g => g.IsActive)
                    .OrderBy(g => g.DisplayOrder)
                    .ToListAsync();

                return groups.Select(g => new FeatureGroupDto
                {
                    Code = g.Code,
                    Name = g.Name,
                    Description = g.Description ?? string.Empty,
                    DisplayOrder = g.DisplayOrder,
                    Features = features.Where(f => f.GroupCode == g.Code).ToList()
                }).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting feature groups");
                return new List<FeatureGroupDto>();
            }
        }

        public async Task<bool> SyncFeaturesAsync()
        {
            var companyId = await _authService.GetUserCompanyIdAsync();
            if (!companyId.HasValue)
            {
                return false;
            }

            return await SyncFeaturesAsync(companyId.Value);
        }

        public async Task<bool> SyncFeaturesAsync(int companyId)
        {
            try
            {
                // TODO: Implement API call to admin portal to sync features
                // For now, we'll simulate with a placeholder
                _logger.LogInformation("Feature sync requested for company {CompanyId}", companyId);
                
                // Clear cache to force reload
                await ClearCacheAsync(companyId);
                
                // In a real implementation, this would:
                // 1. Call the admin portal API
                // 2. Get the latest feature access
                // 3. Update the local FeatureCache table
                // 4. Return success/failure
                
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error syncing features for company {CompanyId}", companyId);
                return false;
            }
        }

        public async Task ClearCacheAsync(int companyId)
        {
            var cacheKey = $"{CACHE_KEY_PREFIX}{companyId}";
            _cache.Remove(cacheKey);
            await Task.CompletedTask;
        }

        public async Task TrackFeatureUsageAsync(string featureCode, string? context = null)
        {
            try
            {
                var userId = await _authService.GetCurrentUserIdAsync();
                var companyId = await _authService.GetUserCompanyIdAsync();
                
                if (!userId.HasValue || !companyId.HasValue)
                {
                    return;
                }

                // TODO: Implement usage tracking
                // This could write to a local table or send to admin portal
                _logger.LogInformation("Feature usage tracked: {FeatureCode} by user {UserId} in company {CompanyId}", 
                    featureCode, userId.Value, companyId.Value);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error tracking feature usage for {FeatureCode}", featureCode);
                // Don't throw - feature tracking should not break the application
            }
        }

        private async Task<List<FeatureDto>> LoadFeaturesFromDatabaseAsync(int companyId)
        {
            // Check if features need to be synced (expired or missing)
            var needsSync = await _context.FeatureCache
                .Where(f => f.CompanyId == companyId)
                .AnyAsync(f => f.ExpiresAt < DateTime.UtcNow || !_context.FeatureCache.Any(fc => fc.CompanyId == companyId));

            if (needsSync)
            {
                // Try to sync, but don't fail if it doesn't work
                await SyncFeaturesAsync(companyId);
            }

            // Load features from cache table
            var features = await _context.FeatureCache
                .Where(f => f.CompanyId == companyId)
                .Where(f => f.ExpiresAt == null || f.ExpiresAt > DateTime.UtcNow)
                .Select(f => new FeatureDto
                {
                    Code = f.FeatureCode,
                    Name = f.FeatureName,
                    GroupCode = f.GroupCode,
                    IsEnabled = f.IsEnabled && (f.EnabledUntil == null || f.EnabledUntil > DateTime.UtcNow),
                    EnabledUntil = f.EnabledUntil
                })
                .ToListAsync();

            // If no features found, return default set (could be configured)
            if (!features.Any())
            {
                // Return basic features that all companies should have
                return GetDefaultFeatures();
            }

            return features;
        }

        private List<FeatureDto> GetDefaultFeatures()
        {
            // Define default features available to all companies
            // These can be overridden by the admin portal
            return new List<FeatureDto>
            {
                new FeatureDto 
                { 
                    Code = "CORE.DASHBOARD", 
                    Name = "Dashboard", 
                    GroupCode = "CORE", 
                    IsEnabled = true 
                },
                new FeatureDto 
                { 
                    Code = "CORE.ESTIMATIONS", 
                    Name = "Basic Estimations", 
                    GroupCode = "CORE", 
                    IsEnabled = true 
                },
                new FeatureDto 
                { 
                    Code = "CORE.CUSTOMERS", 
                    Name = "Customer Management", 
                    GroupCode = "CORE", 
                    IsEnabled = true 
                }
            };
        }
    }
}