using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities;

public class PackBundle
{
    public int Id { get; set; }
    
    public int PackageId { get; set; }
    
    [Required]
    [MaxLength(20)]
    public string BundleNumber { get; set; } = string.Empty; // Auto-generated: PB001, PB002, etc.
    
    [MaxLength(100)]
    public string BundleName { get; set; } = string.Empty; // User-editable name
    
    // Summary fields (calculated from items)
    public decimal TotalWeight { get; set; }
    public int ItemCount { get; set; }
    
    // Timestamps
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public DateTime LastModified { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public virtual Package Package { get; set; } = null!;
    public virtual ICollection<ProcessingItem> ProcessingItems { get; set; } = new List<ProcessingItem>();
}