using SteelEstimation.Core.DTOs;

namespace SteelEstimation.Core.Interfaces;

public interface ITenantProvisioningService
{
    Task<TenantInfo> ProvisionTenantAsync(string tenantId, TenantRegistrationRequest request);
    Task<bool> DeprovisionTenantAsync(string tenantId);
    Task<bool> UpdateTenantSubscriptionAsync(string tenantId, string newTier, int maxUsers);
    Task<bool> SuspendTenantAsync(string tenantId);
    Task<bool> ReactivateTenantAsync(string tenantId);
    Task<bool> BackupTenantDatabaseAsync(string tenantId);
    Task<bool> RestoreTenantDatabaseAsync(string tenantId, string backupPath);
}