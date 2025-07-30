using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities;

public class Company
{
    public int Id { get; set; }
    
    [Required, MaxLength(200)]
    public string Name { get; set; } = string.Empty;
    
    [Required, MaxLength(50)]
    public string Code { get; set; } = string.Empty; // For subdomain/tenant identification
    
    public bool IsActive { get; set; } = true;
    
    [MaxLength(50)]
    public string SubscriptionLevel { get; set; } = "Standard";
    
    public int MaxUsers { get; set; } = 10;
    
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public DateTime LastModified { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public virtual ICollection<User> Users { get; set; } = new List<User>();
    public virtual ICollection<CompanyMaterialType> MaterialTypes { get; set; } = new List<CompanyMaterialType>();
    public virtual ICollection<CompanyMbeIdMapping> MbeIdMappings { get; set; } = new List<CompanyMbeIdMapping>();
    public virtual ICollection<CompanyMaterialPattern> MaterialPatterns { get; set; } = new List<CompanyMaterialPattern>();
}