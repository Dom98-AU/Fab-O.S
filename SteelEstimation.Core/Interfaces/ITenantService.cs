using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Interfaces;

public interface ITenantService
{
    Task<string> GetTenantConnectionStringAsync(string tenantId);
    Task<TenantRegistry?> GetTenantAsync(string tenantId);
    Task<List<TenantRegistry>> GetAllTenantsAsync();
    Task<bool> TenantExistsAsync(string tenantId);
    Task<bool> IsTenantActiveAsync(string tenantId);
    Task LogTenantUsageAsync(string tenantId, TenantUsageLog usageLog);
    Task<List<TenantUsageLog>> GetTenantUsageLogsAsync(string tenantId, DateTime startDate, DateTime endDate);
}