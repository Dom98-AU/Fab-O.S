using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities;

public class WeldingConnection
{
    public int Id { get; set; }
    
    [Required, MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [Required, MaxLength(50)]
    public string Category { get; set; } = string.Empty; // Baseplate, Stiffener, Gusset, Purlin, etc.
    
    [MaxLength(20)]
    public string Size { get; set; } = "Small"; // Small, Large
    
    // Default time values in minutes
    public decimal DefaultAssembleFitTack { get; set; }
    public decimal DefaultWeld { get; set; }
    public decimal DefaultWeldCheck { get; set; }
    public decimal DefaultWeldTest { get; set; } = 0;
    
    // Package-specific override (null = global/app-level)
    public int? PackageId { get; set; }
    
    // Sort order for display
    public int DisplayOrder { get; set; }
    
    public bool IsActive { get; set; } = true;
    
    // Audit fields
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public DateTime LastModified { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public virtual Package? Package { get; set; }
    public virtual ICollection<WeldingItem> WeldingItems { get; set; } = new List<WeldingItem>();
}