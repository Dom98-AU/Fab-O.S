using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities;

public class CompanyMbeIdMapping
{
    public int Id { get; set; }
    
    public int CompanyId { get; set; }
    
    [Required, MaxLength(50)]
    public string MbeId { get; set; } = string.Empty;
    
    [Required, MaxLength(100)]
    public string MaterialType { get; set; } = string.Empty;
    
    public decimal? WeightPerFoot { get; set; }
    
    [MaxLength(500)]
    public string? Notes { get; set; }
    
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public DateTime LastModified { get; set; } = DateTime.UtcNow;
    
    // Navigation property
    public virtual Company Company { get; set; } = null!;
}