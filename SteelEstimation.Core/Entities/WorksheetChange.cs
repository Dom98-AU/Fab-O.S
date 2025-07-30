using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities;

public class WorksheetChange
{
    public int Id { get; set; }
    
    public int PackageWorksheetId { get; set; }
    
    public int? UserId { get; set; }
    
    [Required, MaxLength(50)]
    public string ChangeType { get; set; } = string.Empty; // Add, Update, Delete
    
    [Required, MaxLength(50)]
    public string EntityType { get; set; } = string.Empty; // ProcessingItem, WeldingItem, FabricationItem
    
    public int EntityId { get; set; }
    
    // JSON serialized values
    public string? OldValues { get; set; }
    public string? NewValues { get; set; }
    
    // Change description for UI
    [MaxLength(500)]
    public string? Description { get; set; }
    
    // For undo/redo tracking
    public bool IsUndone { get; set; } = false;
    
    // Timestamp
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public virtual PackageWorksheet PackageWorksheet { get; set; } = null!;
    public virtual User? User { get; set; }
}