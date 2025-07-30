namespace SteelEstimation.Core.Entities;

public class TenantRegistry
{
    public int Id { get; set; }
    public string TenantId { get; set; } = string.Empty;
    public string DatabaseName { get; set; } = string.Empty;
    public string CompanyName { get; set; } = string.Empty;
    public string CompanyCode { get; set; } = string.Empty;
    public string AdminEmail { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime LastModified { get; set; }
    public bool IsActive { get; set; } = true;
    public string SubscriptionTier { get; set; } = "Standard";
    public int MaxUsers { get; set; } = 10;
    public DateTime? SubscriptionExpiryDate { get; set; }
    public string? ConnectionStringKeyVaultName { get; set; }
    public string? DatabaseServer { get; set; }
    public string? ElasticPoolName { get; set; }
    public Dictionary<string, string> Settings { get; set; } = new();
    
    // Navigation properties
    public virtual ICollection<TenantUsageLog> UsageLogs { get; set; } = new List<TenantUsageLog>();
}