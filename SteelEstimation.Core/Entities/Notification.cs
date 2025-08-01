using System;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities
{
    public class Notification
    {
        public int Id { get; set; }
        
        [Required]
        public int UserId { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string Type { get; set; } = string.Empty; // e.g., "mention", "comment", "invite", "system"
        
        [Required]
        [MaxLength(255)]
        public string Title { get; set; } = string.Empty;
        
        [MaxLength(500)]
        public string? Message { get; set; }
        
        // Link to related entity
        [MaxLength(50)]
        public string? EntityType { get; set; }
        public int? EntityId { get; set; }
        
        // Product/Module context
        [MaxLength(50)]
        public string? ProductName { get; set; }
        
        // URL for navigation
        [MaxLength(255)]
        public string? ActionUrl { get; set; }
        
        // Status
        public bool IsRead { get; set; } = false;
        public DateTime? ReadAt { get; set; }
        public bool IsArchived { get; set; } = false;
        public DateTime? ArchivedAt { get; set; }
        
        // Priority
        [MaxLength(20)]
        public string Priority { get; set; } = "normal"; // low, normal, high, urgent
        
        // Sender information (for user-generated notifications)
        public int? FromUserId { get; set; }
        
        // Tracking
        public DateTime CreatedAt { get; set; }
        public DateTime? ExpiresAt { get; set; }
        
        // Navigation properties
        public User User { get; set; } = null!;
        public User? FromUser { get; set; }
    }
}