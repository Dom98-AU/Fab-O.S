using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities;

public class Contact
{
    public int Id { get; set; }
    
    public int CustomerId { get; set; }
    
    [Required]
    [MaxLength(100)]
    public string FirstName { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(100)]
    public string LastName { get; set; } = string.Empty;
    
    [MaxLength(200)]
    [EmailAddress]
    public string? Email { get; set; }
    
    [MaxLength(20)]
    [Phone]
    public string? Phone { get; set; }
    
    [MaxLength(20)]
    [Phone]
    public string? Mobile { get; set; }
    
    [MaxLength(100)]
    public string? Position { get; set; }
    
    public bool IsPrimary { get; set; } = false;
    
    public bool IsBillingContact { get; set; } = false;
    
    public bool IsActive { get; set; } = true;
    
    [MaxLength(500)]
    public string? Notes { get; set; }
    
    // Audit fields
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public DateTime ModifiedDate { get; set; } = DateTime.UtcNow;
    
    // Computed properties
    public string FullName => $"{FirstName} {LastName}";
    
    public string DisplayName => string.IsNullOrEmpty(Position) 
        ? FullName 
        : $"{FullName} - {Position}";
    
    // Navigation properties
    public virtual Customer Customer { get; set; } = null!;
}