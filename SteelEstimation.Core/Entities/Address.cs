using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities;

public class Address
{
    public int Id { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string AddressLine1 { get; set; } = string.Empty;
    
    [MaxLength(200)]
    public string? AddressLine2 { get; set; }
    
    [Required]
    [MaxLength(100)]
    public string Suburb { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(50)]
    public string State { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(10)]
    [RegularExpression(@"^\d{4}$", ErrorMessage = "Postcode must be 4 digits")]
    public string PostCode { get; set; } = string.Empty;
    
    [MaxLength(100)]
    public string Country { get; set; } = "Australia";
    
    public AddressType AddressType { get; set; }
    
    // Computed properties
    public string FullAddress => string.IsNullOrEmpty(AddressLine2)
        ? $"{AddressLine1}, {Suburb} {State} {PostCode}"
        : $"{AddressLine1}, {AddressLine2}, {Suburb} {State} {PostCode}";
    
    public string ShortAddress => $"{Suburb} {State} {PostCode}";
    
    // Navigation properties
    public virtual ICollection<Customer> BillingCustomers { get; set; } = new List<Customer>();
    public virtual ICollection<Customer> ShippingCustomers { get; set; } = new List<Customer>();
}

public enum AddressType
{
    Billing = 1,
    Shipping = 2,
    Other = 3
}