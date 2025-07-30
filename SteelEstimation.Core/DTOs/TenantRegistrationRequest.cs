using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.DTOs;

public class TenantRegistrationRequest
{
    [Required]
    [StringLength(200)]
    public string CompanyName { get; set; } = string.Empty;
    
    [Required]
    [StringLength(50)]
    public string CompanyCode { get; set; } = string.Empty;
    
    [Required]
    [EmailAddress]
    public string AdminEmail { get; set; } = string.Empty;
    
    [Required]
    [StringLength(100)]
    public string AdminFirstName { get; set; } = string.Empty;
    
    [Required]
    [StringLength(100)]
    public string AdminLastName { get; set; } = string.Empty;
    
    [Phone]
    public string? PhoneNumber { get; set; }
    
    [StringLength(500)]
    public string? Address { get; set; }
    
    [StringLength(100)]
    public string? City { get; set; }
    
    [StringLength(100)]
    public string? State { get; set; }
    
    [StringLength(20)]
    public string? PostalCode { get; set; }
    
    [StringLength(100)]
    public string? Country { get; set; }
    
    [Required]
    public string SubscriptionTier { get; set; } = "Standard"; // Basic, Standard, Premium, Enterprise
    
    public int MaxUsers { get; set; } = 10;
    
    public bool EnableAdvancedFeatures { get; set; } = false;
    
    public Dictionary<string, string> AdditionalSettings { get; set; } = new();
}