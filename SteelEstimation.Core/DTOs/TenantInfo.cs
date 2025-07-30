namespace SteelEstimation.Core.DTOs;

public class TenantInfo
{
    public string TenantId { get; set; } = string.Empty;
    public string DatabaseName { get; set; } = string.Empty;
    public string ConnectionString { get; set; } = string.Empty;
    public string CompanyName { get; set; } = string.Empty;
    public string AdminEmail { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public string SubscriptionTier { get; set; } = string.Empty;
}