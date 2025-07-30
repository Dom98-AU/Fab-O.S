namespace SteelEstimation.Core.Entities;

public class TenantUsageLog
{
    public int Id { get; set; }
    public int TenantRegistryId { get; set; }
    public string TenantId { get; set; } = string.Empty;
    public DateTime LogDate { get; set; }
    public int ActiveUsers { get; set; }
    public long StorageUsedBytes { get; set; }
    public int ProjectCount { get; set; }
    public int EstimationCount { get; set; }
    public decimal DatabaseSizeGB { get; set; }
    public int ApiCallCount { get; set; }
    public DateTime CreatedAt { get; set; }
    
    // Navigation property
    public virtual TenantRegistry TenantRegistry { get; set; } = null!;
}