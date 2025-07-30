using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities;

public class CompanyMaterialPattern
{
    public int Id { get; set; }
    
    public int CompanyId { get; set; }
    
    [Required, MaxLength(200)]
    public string Pattern { get; set; } = string.Empty;
    
    [Required, MaxLength(100)]
    public string MaterialType { get; set; } = string.Empty;
    
    [Required, MaxLength(50)]
    public string PatternType { get; set; } = "StartsWith"; // 'StartsWith', 'Contains', 'Regex'
    
    public int Priority { get; set; } = 0;
    
    public bool IsActive { get; set; } = true;
    
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public DateTime LastModified { get; set; } = DateTime.UtcNow;
    
    // Navigation property
    public virtual Company Company { get; set; } = null!;
}