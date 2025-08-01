using System;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.DTOs
{
    public class LogActivityRequest
    {
        [Required]
        public int UserId { get; set; }
        
        [Required, MaxLength(100)]
        public string ActivityType { get; set; } = string.Empty;
        
        [MaxLength(500)]
        public string? Description { get; set; }
        
        [MaxLength(50)]
        public string? EntityType { get; set; }
        
        public int? EntityId { get; set; }
        
        [Required, MaxLength(50)]
        public string ProductName { get; set; } = string.Empty;
        
        public string? Metadata { get; set; }
        
        [MaxLength(45)]
        public string? IpAddress { get; set; }
        
        [MaxLength(255)]
        public string? UserAgent { get; set; }
    }
    
    public class UserActivityDto
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Username { get; set; } = string.Empty;
        public string UserFullName { get; set; } = string.Empty;
        public string? UserAvatarUrl { get; set; }
        public string ActivityType { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? EntityType { get; set; }
        public int? EntityId { get; set; }
        public string ProductName { get; set; } = string.Empty;
        public string? Metadata { get; set; }
        public DateTime CreatedAt { get; set; }
        public string TimeAgo { get; set; } = string.Empty;
        public string Icon { get; set; } = string.Empty;
        public string ColorClass { get; set; } = string.Empty;
    }
    
    public class UserActivitySummary
    {
        public int UserId { get; set; }
        public string Username { get; set; } = string.Empty;
        public string UserFullName { get; set; } = string.Empty;
        public string? UserAvatarUrl { get; set; }
        public int TotalActivities { get; set; }
        public Dictionary<string, int> ActivitiesByType { get; set; } = new();
        public Dictionary<string, int> ActivitiesByProduct { get; set; } = new();
        public DateTime? LastActivityAt { get; set; }
    }
    
    public class ActivityTimelineEntry
    {
        public DateTime Date { get; set; }
        public int ActivityCount { get; set; }
        public Dictionary<string, int> ByType { get; set; } = new();
        public Dictionary<string, int> ByProduct { get; set; } = new();
    }
}