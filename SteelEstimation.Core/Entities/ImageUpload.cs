using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities;

public class ImageUpload
{
    public int Id { get; set; }
    
    [Required, MaxLength(255)]
    public string FileName { get; set; } = string.Empty;
    
    [Required, MaxLength(255)]
    public string OriginalFileName { get; set; } = string.Empty;
    
    [Required, MaxLength(500)]
    public string FilePath { get; set; } = string.Empty;
    
    [MaxLength(100)]
    public string ContentType { get; set; } = string.Empty;
    
    public long FileSize { get; set; }
    
    // Dimensions
    public int? Width { get; set; }
    public int? Height { get; set; }
    
    // Thumbnail path (if generated)
    [MaxLength(500)]
    public string? ThumbnailPath { get; set; }
    
    // Foreign keys
    public int? WeldingItemId { get; set; }
    
    // User who uploaded
    public int? UploadedBy { get; set; }
    
    // Audit fields
    public DateTime UploadedDate { get; set; } = DateTime.UtcNow;
    public bool IsDeleted { get; set; } = false;
    
    // Navigation properties
    public virtual WeldingItem? WeldingItem { get; set; }
    public virtual User? UploadedByUser { get; set; }
}