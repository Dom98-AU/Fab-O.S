using System;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities
{
    public class UserActivity
    {
        public int Id { get; set; }
        
        [Required]
        public int UserId { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string ActivityType { get; set; } = string.Empty; // e.g., "created_estimation", "updated_package", "commented"
        
        [MaxLength(500)]
        public string? Description { get; set; }
        
        // Related entity
        [MaxLength(50)]
        public string? EntityType { get; set; }
        public int? EntityId { get; set; }
        
        // Product/Module context
        [Required]
        [MaxLength(50)]
        public string ProductName { get; set; } = string.Empty;
        
        // Additional metadata (JSON)
        public string? Metadata { get; set; }
        
        // IP and browser info for security tracking
        [MaxLength(45)]
        public string? IpAddress { get; set; }
        
        [MaxLength(255)]
        public string? UserAgent { get; set; }
        
        // Tracking
        public DateTime CreatedAt { get; set; }
        
        // Navigation properties
        public User User { get; set; } = null!;
    }
}