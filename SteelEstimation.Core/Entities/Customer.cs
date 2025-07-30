using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities;

public class Customer
{
    public int Id { get; set; }
    
    public int CompanyId { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string CompanyName { get; set; } = string.Empty;
    
    [MaxLength(200)]
    public string? TradingName { get; set; }
    
    [Required]
    [MaxLength(11)]
    [RegularExpression(@"^\d{11}$", ErrorMessage = "ABN must be exactly 11 digits")]
    public string ABN { get; set; } = string.Empty;
    
    [MaxLength(9)]
    [RegularExpression(@"^\d{9}$", ErrorMessage = "ACN must be exactly 9 digits")]
    public string? ACN { get; set; }
    
    public bool IsActive { get; set; } = true;
    
    // Address references
    public int? BillingAddressId { get; set; }
    public int? ShippingAddressId { get; set; }
    
    [MaxLength(1000)]
    public string? Notes { get; set; }
    
    // Audit fields
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public DateTime ModifiedDate { get; set; } = DateTime.UtcNow;
    public int CreatedById { get; set; }
    public int? ModifiedById { get; set; }
    
    // Navigation properties
    public virtual Company Company { get; set; } = null!;
    public virtual Address? BillingAddress { get; set; }
    public virtual Address? ShippingAddress { get; set; }
    public virtual User CreatedBy { get; set; } = null!;
    public virtual User? ModifiedBy { get; set; }
    public virtual ICollection<Contact> Contacts { get; set; } = new List<Contact>();
    public virtual ICollection<Project> Projects { get; set; } = new List<Project>();
}