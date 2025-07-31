using System;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities
{
    /// <summary>
    /// Audit trail for social login attempts and account linking
    /// </summary>
    public class SocialLoginAudit
    {
        public int Id { get; set; }
        
        public int? UserId { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string AuthProvider { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(50)]
        public string EventType { get; set; } = string.Empty; // Login, SignUp, Link, Unlink, Failed
        
        public bool Success { get; set; }
        
        [MaxLength(500)]
        public string? ErrorMessage { get; set; }
        
        [MaxLength(45)]
        public string? IpAddress { get; set; }
        
        [MaxLength(500)]
        public string? UserAgent { get; set; }
        
        public DateTime EventDate { get; set; } = DateTime.UtcNow;
        
        // Navigation
        public virtual User? User { get; set; }
    }
}