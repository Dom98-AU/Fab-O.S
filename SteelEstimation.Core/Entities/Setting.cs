using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities;

public class Setting
{
    public int Id { get; set; }
    
    [Required]
    [MaxLength(100)]
    public string Key { get; set; } = string.Empty;
    
    [Required]
    public string Value { get; set; } = string.Empty;
    
    [MaxLength(50)]
    public string ValueType { get; set; } = "string"; // string, bool, int, decimal, json
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    [MaxLength(50)]
    public string? Category { get; set; }
    
    public bool IsSystemSetting { get; set; } = false;
    
    // Audit fields
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public DateTime LastModified { get; set; } = DateTime.UtcNow;
    public int? LastModifiedBy { get; set; }
    
    // Navigation properties
    public virtual User? LastModifiedByUser { get; set; }
}