using System;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.DTOs
{
    public class UserStats
    {
        public int TotalUsers { get; set; }
        public int ActiveUsers { get; set; }
        public int InactiveUsers { get; set; }
        public int LockedUsers { get; set; }
        public int AdminCount { get; set; }
        public int ProjectManagerCount { get; set; }
        public int EstimatorCount { get; set; }
        public int ViewerCount { get; set; }
        public DateTime? LastUserCreated { get; set; }
    }
    
    public class ResetPasswordRequest
    {
        [Required]
        public int UserId { get; set; }
        
        [Required]
        [StringLength(100, MinimumLength = 8)]
        public string NewPassword { get; set; } = string.Empty;
        
        public bool RequirePasswordChange { get; set; } = true;
    }
}