using System;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities
{
    public class ApiKey
    {
        public int Id { get; set; }
        
        [Required, MaxLength(100)]
        public string Name { get; set; } = string.Empty;
        
        [Required, MaxLength(500)]
        public string KeyHash { get; set; } = string.Empty;
        
        [Required, MaxLength(100)]
        public string KeyPrefix { get; set; } = string.Empty; // First 8 chars of key for identification
        
        public bool IsActive { get; set; } = true;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime? ExpiresAt { get; set; }
        
        public DateTime? LastUsedAt { get; set; }
        
        public int? RateLimitPerHour { get; set; }
        
        // Scopes/permissions for this API key
        [MaxLength(1000)]
        public string? Scopes { get; set; } // Comma-separated list of allowed operations
    }
}