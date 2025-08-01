using System;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.DTOs
{
    public class CreateNotificationRequest
    {
        [Required]
        public int UserId { get; set; }
        
        [Required, MaxLength(100)]
        public string Type { get; set; } = string.Empty;
        
        [Required, MaxLength(255)]
        public string Title { get; set; } = string.Empty;
        
        [MaxLength(500)]
        public string? Message { get; set; }
        
        [MaxLength(50)]
        public string? EntityType { get; set; }
        
        public int? EntityId { get; set; }
        
        [MaxLength(50)]
        public string? ProductName { get; set; }
        
        [MaxLength(255)]
        public string? ActionUrl { get; set; }
        
        [MaxLength(20)]
        public string Priority { get; set; } = "normal";
        
        public int? FromUserId { get; set; }
        
        public DateTime? ExpiresAt { get; set; }
    }
    
    public class NotificationDto
    {
        public int Id { get; set; }
        public string Type { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string? Message { get; set; }
        public string? EntityType { get; set; }
        public int? EntityId { get; set; }
        public string? ProductName { get; set; }
        public string? ActionUrl { get; set; }
        public bool IsRead { get; set; }
        public DateTime? ReadAt { get; set; }
        public bool IsArchived { get; set; }
        public string Priority { get; set; } = string.Empty;
        public int? FromUserId { get; set; }
        public string? FromUsername { get; set; }
        public string? FromUserFullName { get; set; }
        public string? FromUserAvatarUrl { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? ExpiresAt { get; set; }
        public string TimeAgo { get; set; } = string.Empty;
        public string Icon { get; set; } = string.Empty;
        public string ColorClass { get; set; } = string.Empty;
    }
    
    public class NotificationSummaryDto
    {
        public int TotalCount { get; set; }
        public int UnreadCount { get; set; }
        public Dictionary<string, int> UnreadByType { get; set; } = new();
        public DateTime? LastReadAt { get; set; }
    }
}