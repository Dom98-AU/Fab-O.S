namespace SteelEstimation.Core.Entities;

public class EfficiencyRate
{
    public int Id { get; set; }
    
    public string Name { get; set; } = string.Empty;
    
    public decimal EfficiencyPercentage { get; set; }
    
    public string? Description { get; set; }
    
    public bool IsDefault { get; set; }
    
    public bool IsActive { get; set; } = true;
    
    public int CompanyId { get; set; }
    
    public DateTime CreatedDate { get; set; }
    
    public DateTime ModifiedDate { get; set; }
    
    // Navigation properties
    public virtual Company Company { get; set; } = null!;
    public virtual ICollection<Package> Packages { get; set; } = new List<Package>();
}