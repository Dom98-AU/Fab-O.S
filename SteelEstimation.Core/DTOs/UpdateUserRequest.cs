using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.DTOs
{
    public class UpdateUserRequest
    {
        [EmailAddress]
        [StringLength(200)]
        public string? Email { get; set; }

        [StringLength(100)]
        public string? FirstName { get; set; }

        [StringLength(100)]
        public string? LastName { get; set; }

        [StringLength(200)]
        public string? CompanyName { get; set; }

        [StringLength(100)]
        public string? JobTitle { get; set; }

        [Phone]
        [StringLength(20)]
        public string? PhoneNumber { get; set; }

        public bool? IsActive { get; set; }
    }
}