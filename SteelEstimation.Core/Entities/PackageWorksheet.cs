using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities;

public class PackageWorksheet
{
    public int Id { get; set; }
    
    public int PackageId { get; set; }
    
    [Required, MaxLength(50)]
    public string WorksheetType { get; set; } = string.Empty; // Processing, Welding, Fabrication, Other
    
    [Required, MaxLength(200)]
    public string Name { get; set; } = string.Empty;
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    // Worksheet-level totals (calculated from items)
    public decimal TotalHours { get; set; } = 0;
    public decimal TotalCost { get; set; } = 0;
    public int ItemCount { get; set; } = 0;
    
    // Display order
    public int DisplayOrder { get; set; } = 0;
    
    // Tracking
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public DateTime LastModified { get; set; } = DateTime.UtcNow;
    
    // Template reference
    public int? WorksheetTemplateId { get; set; }
    
    // Navigation properties
    public virtual Package Package { get; set; } = null!;
    public virtual WorksheetTemplate? WorksheetTemplate { get; set; }
    public virtual ICollection<ProcessingItem> ProcessingItems { get; set; } = new List<ProcessingItem>();
    public virtual ICollection<WeldingItem> WeldingItems { get; set; } = new List<WeldingItem>();
    public virtual ICollection<WorksheetChange> Changes { get; set; } = new List<WorksheetChange>();
}

// Enum for worksheet types
public static class WorksheetTypes
{
    public const string Processing = "Processing";
    public const string Welding = "Welding";
    public const string Fabrication = "Fabrication";
    public const string Other = "Other";
    
    public static readonly string[] All = { Processing, Welding, Fabrication, Other };
}