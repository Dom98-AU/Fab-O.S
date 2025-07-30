using System;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities
{
    public class Invite
    {
        public int Id { get; set; }
        
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
        
        [Required]
        public string FirstName { get; set; } = string.Empty;
        
        [Required]
        public string LastName { get; set; } = string.Empty;
        
        public string? CompanyName { get; set; }
        
        public string? JobTitle { get; set; }
        
        [Required]
        public string Token { get; set; } = string.Empty;
        
        public DateTime CreatedDate { get; set; }
        
        public DateTime ExpiryDate { get; set; }
        
        public bool IsUsed { get; set; }
        
        public DateTime? UsedDate { get; set; }
        
        // Navigation properties
        public int InvitedByUserId { get; set; }
        public User InvitedByUser { get; set; } = null!;
        
        public int RoleId { get; set; }
        public Role Role { get; set; } = null!;
        
        public int? UserId { get; set; }
        public User? User { get; set; }
        
        // Additional properties
        public string? Message { get; set; }
        public bool SendWelcomeEmail { get; set; } = true;
        public string Status => IsUsed ? "Used" : (ExpiryDate < DateTime.UtcNow ? "Expired" : "Pending");
    }
}