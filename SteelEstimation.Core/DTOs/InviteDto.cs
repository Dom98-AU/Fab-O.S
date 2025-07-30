using System;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.DTOs
{
    public class CreateInviteRequest
    {
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
        public int RoleId { get; set; }
        
        public string? Message { get; set; }
        
        public bool SendWelcomeEmail { get; set; } = true;
        
        public int ExpiryDays { get; set; } = 7;
    }
    
    public class InviteResult
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public string? InviteUrl { get; set; }
        public Entities.Invite? Invite { get; set; }
    }
    
    public class AcceptInviteRequest
    {
        [Required]
        public string Token { get; set; } = string.Empty;
        
        [Required]
        [MinLength(8)]
        public string Password { get; set; } = string.Empty;
        
        [Required]
        [Compare(nameof(Password))]
        public string ConfirmPassword { get; set; } = string.Empty;
        
        public string? PhoneNumber { get; set; }
        
        public bool AcceptTerms { get; set; }
    }
}