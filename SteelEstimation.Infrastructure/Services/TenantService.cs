using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Interfaces;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services;

/// <summary>
/// Service for managing tenant information and connections
/// Note: This is disabled by default. Enable by setting EnableMultiTenantMode in configuration
/// </summary>
public class TenantService : ITenantService
{
    private readonly IKeyVaultService _keyVault;
    private readonly MasterDbContext _masterContext;
    private readonly IMemoryCache _cache;
    private readonly IConfiguration _configuration;
    private readonly ILogger<TenantService> _logger;
    private readonly bool _isEnabled;

    public TenantService(
        IKeyVaultService keyVault,
        MasterDbContext masterContext,
        IMemoryCache cache,
        IConfiguration configuration,
        ILogger<TenantService> logger)
    {
        _keyVault = keyVault;
        _masterContext = masterContext;
        _cache = cache;
        _configuration = configuration;
        _logger = logger;
        _isEnabled = configuration.GetValue<bool>("MultiTenant:EnableDatabasePerTenant", false);
    }

    public async Task<string> GetTenantConnectionStringAsync(string tenantId)
    {
        if (!_isEnabled)
        {
            // In single-tenant mode, return the default connection string
            return _configuration.GetConnectionString("DefaultConnection") 
                ?? throw new InvalidOperationException("No default connection string configured");
        }

        // Check cache first
        var cacheKey = $"tenant-{tenantId}-connection";
        if (_cache.TryGetValue<string>(cacheKey, out var cached) && cached != null)
        {
            return cached;
        }

        // Get from Key Vault
        var connectionString = await _keyVault.GetSecretAsync($"tenant-{tenantId}-connectionstring");

        // Cache for future requests
        _cache.Set(cacheKey, connectionString, TimeSpan.FromHours(1));

        return connectionString;
    }

    public async Task<TenantRegistry?> GetTenantAsync(string tenantId)
    {
        if (!_isEnabled)
        {
            return null;
        }

        return await _masterContext.TenantRegistries
            .FirstOrDefaultAsync(t => t.TenantId == tenantId);
    }

    public async Task<List<TenantRegistry>> GetAllTenantsAsync()
    {
        if (!_isEnabled)
        {
            return new List<TenantRegistry>();
        }

        return await _masterContext.TenantRegistries
            .Where(t => t.IsActive)
            .OrderBy(t => t.CompanyName)
            .ToListAsync();
    }

    public async Task<bool> TenantExistsAsync(string tenantId)
    {
        if (!_isEnabled)
        {
            return true; // In single-tenant mode, always return true
        }

        return await _masterContext.TenantRegistries
            .AnyAsync(t => t.TenantId == tenantId);
    }

    public async Task<bool> IsTenantActiveAsync(string tenantId)
    {
        if (!_isEnabled)
        {
            return true; // In single-tenant mode, always return true
        }

        return await _masterContext.TenantRegistries
            .AnyAsync(t => t.TenantId == tenantId && t.IsActive);
    }

    public async Task LogTenantUsageAsync(string tenantId, TenantUsageLog usageLog)
    {
        if (!_isEnabled)
        {
            return; // No usage logging in single-tenant mode
        }

        try
        {
            var tenant = await _masterContext.TenantRegistries
                .FirstOrDefaultAsync(t => t.TenantId == tenantId);

            if (tenant == null)
            {
                _logger.LogWarning("Attempted to log usage for non-existent tenant {TenantId}", tenantId);
                return;
            }

            usageLog.TenantRegistryId = tenant.Id;
            usageLog.TenantId = tenantId;
            usageLog.CreatedAt = DateTime.UtcNow;

            _masterContext.TenantUsageLogs.Add(usageLog);
            await _masterContext.SaveChangesAsync();

            _logger.LogInformation("Logged usage for tenant {TenantId}", tenantId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to log usage for tenant {TenantId}", tenantId);
        }
    }

    public async Task<List<TenantUsageLog>> GetTenantUsageLogsAsync(string tenantId, DateTime startDate, DateTime endDate)
    {
        if (!_isEnabled)
        {
            return new List<TenantUsageLog>();
        }

        return await _masterContext.TenantUsageLogs
            .Where(log => log.TenantId == tenantId 
                && log.LogDate >= startDate 
                && log.LogDate <= endDate)
            .OrderByDescending(log => log.LogDate)
            .ToListAsync();
    }
}