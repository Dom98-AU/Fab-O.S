using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities
{
    public class FeatureGroup
    {
        public int Id { get; set; }
        
        [Required, MaxLength(50)]
        public string Code { get; set; } = string.Empty;
        
        [Required, MaxLength(200)]
        public string Name { get; set; } = string.Empty;
        
        [MaxLength(500)]
        public string? Description { get; set; }
        
        public int DisplayOrder { get; set; }
        
        public bool IsActive { get; set; } = true;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime LastModified { get; set; } = DateTime.UtcNow;
    }
}