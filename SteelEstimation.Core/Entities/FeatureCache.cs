using System;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities
{
    public class FeatureCache
    {
        public int Id { get; set; }
        
        [Required]
        public int CompanyId { get; set; }
        
        [Required, MaxLength(100)]
        public string FeatureCode { get; set; } = string.Empty;
        
        [MaxLength(200)]
        public string FeatureName { get; set; } = string.Empty;
        
        [MaxLength(50)]
        public string GroupCode { get; set; } = string.Empty;
        
        public bool IsEnabled { get; set; }
        
        public DateTime? EnabledUntil { get; set; }
        
        public DateTime LastSyncedAt { get; set; }
        
        public DateTime? ExpiresAt { get; set; }
        
        // Navigation property
        public virtual Company Company { get; set; } = null!;
    }
}