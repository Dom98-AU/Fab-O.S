using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.DTOs
{
    public class CreateUserRequest
    {
        [Required]
        [StringLength(100, MinimumLength = 3)]
        public string Username { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        [StringLength(200)]
        public string Email { get; set; } = string.Empty;

        [Required]
        [StringLength(100, MinimumLength = 8)]
        public string Password { get; set; } = string.Empty;

        [Required]
        [StringLength(100)]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [StringLength(100)]
        public string LastName { get; set; } = string.Empty;

        [StringLength(200)]
        public string? CompanyName { get; set; }

        [StringLength(100)]
        public string? JobTitle { get; set; }

        [Phone]
        [StringLength(20)]
        public string? PhoneNumber { get; set; }

        public string RoleName { get; set; } = "Viewer";
        public bool SendWelcomeEmail { get; set; } = true;
        public bool RequireEmailConfirmation { get; set; } = true;
        public bool IsActive { get; set; } = true;
    }
}