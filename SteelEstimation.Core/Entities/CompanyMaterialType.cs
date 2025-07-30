using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities;

public class CompanyMaterialType
{
    public int Id { get; set; }
    
    public int CompanyId { get; set; }
    
    [Required, MaxLength(100)]
    public string TypeName { get; set; } = string.Empty;
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    public decimal HourlyRate { get; set; } = 65.00m;
    
    public decimal? DefaultWeightPerFoot { get; set; }
    
    [MaxLength(20)]
    public string? DefaultColor { get; set; } = "#6c757d";
    
    public int DisplayOrder { get; set; } = 0;
    
    public bool IsActive { get; set; } = true;
    
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public DateTime LastModified { get; set; } = DateTime.UtcNow;
    
    // Navigation property
    public virtual Company Company { get; set; } = null!;
}