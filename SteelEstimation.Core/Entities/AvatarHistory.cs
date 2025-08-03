using System;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities
{
    public class AvatarHistory
    {
        public int Id { get; set; }
        
        [Required]
        public int UserId { get; set; }
        
        [MaxLength(255)]
        public string? AvatarUrl { get; set; }
        
        [MaxLength(50)]
        public string? AvatarType { get; set; } // "font-awesome", "dicebear", "custom"
        
        [MaxLength(100)]
        public string? DiceBearStyle { get; set; }
        
        [MaxLength(100)]
        public string? DiceBearSeed { get; set; }
        
        [MaxLength(500)]
        public string? DiceBearOptions { get; set; }
        
        [MaxLength(100)]
        public string? ChangeReason { get; set; } // "user_change", "admin_change", "system_update"
        
        public DateTime CreatedAt { get; set; }
        
        public bool IsActive { get; set; }
        
        // Navigation properties
        public User User { get; set; } = null!;
    }
}