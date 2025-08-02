using System;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities
{
    public class UserProfile
    {
        public int Id { get; set; }
        
        [Required]
        public int UserId { get; set; }
        
        [MaxLength(500)]
        public string? Bio { get; set; }
        
        [MaxLength(255)]
        public string? AvatarUrl { get; set; }
        
        [MaxLength(50)]
        public string? AvatarType { get; set; } // "font-awesome", "dicebear", "custom"
        
        [MaxLength(100)]
        public string? DiceBearStyle { get; set; } // DiceBear style ID (e.g., "adventurer", "avataaars")
        
        [MaxLength(100)]
        public string? DiceBearSeed { get; set; } // Seed for consistent DiceBear generation
        
        [MaxLength(500)]
        public string? DiceBearOptions { get; set; } // JSON string of DiceBear options
        
        [MaxLength(100)]
        public string? Location { get; set; }
        
        [MaxLength(50)]
        public string? Timezone { get; set; }
        
        [MaxLength(20)]
        public string? PhoneNumber { get; set; }
        
        [MaxLength(100)]
        public string? Department { get; set; }
        
        public DateTime? DateOfBirth { get; set; }
        
        public DateTime? StartDate { get; set; }
        
        // Professional Information
        [MaxLength(100)]
        public string? JobTitle { get; set; }
        
        [MaxLength(500)]
        public string? Skills { get; set; } // Comma-separated skills
        
        [MaxLength(1000)]
        public string? AboutMe { get; set; }
        
        // Preferences
        public bool IsProfilePublic { get; set; } = true;
        public bool ShowEmail { get; set; } = false;
        public bool ShowPhoneNumber { get; set; } = false;
        public bool AllowMentions { get; set; } = true;
        
        // Status
        [MaxLength(100)]
        public string? Status { get; set; } // e.g., "Available", "Busy", "Away"
        
        [MaxLength(255)]
        public string? StatusMessage { get; set; }
        
        // Tracking
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        public DateTime? LastActivityAt { get; set; }
        
        // Navigation properties
        public User User { get; set; } = null!;
    }
}