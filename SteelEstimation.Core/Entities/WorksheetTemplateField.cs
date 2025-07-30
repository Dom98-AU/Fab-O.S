using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities;

public class WorksheetTemplateField
{
    public int Id { get; set; }
    
    public int WorksheetTemplateId { get; set; }
    
    [Required, MaxLength(100)]
    public string FieldName { get; set; } = string.Empty; // Matches property names
    
    [MaxLength(200)]
    public string? DisplayName { get; set; } // Custom label override
    
    public bool IsVisible { get; set; } = true;
    
    public bool IsRequired { get; set; } = false;
    
    public int DisplayOrder { get; set; } = 0;
    
    public int? ColumnWidth { get; set; } // pixels
    
    public bool IsFrozen { get; set; } = false;
    
    // Navigation properties
    public virtual WorksheetTemplate WorksheetTemplate { get; set; } = null!;
}