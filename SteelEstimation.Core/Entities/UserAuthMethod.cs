using System;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities
{
    /// <summary>
    /// Represents an authentication method linked to a user account
    /// Allows users to have multiple ways to sign in (email/password, Microsoft, Google, etc.)
    /// </summary>
    public class UserAuthMethod
    {
        public int Id { get; set; }
        
        [Required]
        public int UserId { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string AuthProvider { get; set; } = "Local"; // Local, Microsoft, Google, LinkedIn
        
        [MaxLength(256)]
        public string? ExternalUserId { get; set; } // ID from the external provider
        
        [EmailAddress]
        [MaxLength(256)]
        public string? Email { get; set; } // Email from provider (might differ from primary)
        
        [MaxLength(256)]
        public string? DisplayName { get; set; } // Display name from provider
        
        [MaxLength(500)]
        public string? ProfilePictureUrl { get; set; }
        
        public DateTime LinkedDate { get; set; } = DateTime.UtcNow;
        
        public DateTime? LastUsedDate { get; set; }
        
        public bool IsActive { get; set; } = true;
        
        // Navigation properties
        public virtual User User { get; set; } = null!;
        
        // Helper methods
        public void UpdateLastUsed()
        {
            LastUsedDate = DateTime.UtcNow;
        }
        
        public bool IsExpired(int daysUntilExpiry = 365)
        {
            if (!LastUsedDate.HasValue) return false;
            return LastUsedDate.Value.AddDays(daysUntilExpiry) < DateTime.UtcNow;
        }
    }
}