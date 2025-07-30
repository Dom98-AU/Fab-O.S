using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities;

public class WorksheetTemplate
{
    public int Id { get; set; }
    
    [Required, MaxLength(100)]
    public string Name { get; set; } = string.Empty;
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    [Required, MaxLength(50)]
    public string BaseType { get; set; } = string.Empty; // Processing or Welding
    
    public int CreatedByUserId { get; set; }
    
    public bool IsPublished { get; set; } = false; // Personal use only
    
    public bool IsGlobal { get; set; } = false; // Admin published for everyone
    
    public bool IsDefault { get; set; } = false; // Replaces current fixed worksheets
    
    public bool AllowColumnReorder { get; set; } = true;
    
    public int DisplayOrder { get; set; } = 0;
    
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    
    public DateTime LastModified { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public virtual User CreatedByUser { get; set; } = null!;
    public virtual ICollection<WorksheetTemplateField> Fields { get; set; } = new List<WorksheetTemplateField>();
    public virtual ICollection<PackageWorksheet> PackageWorksheets { get; set; } = new List<PackageWorksheet>();
}