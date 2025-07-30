namespace SteelEstimation.Core.Entities;

public class WorksheetColumnOrder
{
    public int Id { get; set; }
    public int WorksheetColumnViewId { get; set; }
    public string ColumnName { get; set; } = string.Empty;
    public int DisplayOrder { get; set; }
    public bool IsVisible { get; set; }
    public bool IsFrozen { get; set; }
    public int? Width { get; set; } // Column width in pixels
    public string? DependentColumnName { get; set; } // For columns that should move together
    
    // Navigation properties
    public WorksheetColumnView WorksheetColumnView { get; set; } = null!;
}