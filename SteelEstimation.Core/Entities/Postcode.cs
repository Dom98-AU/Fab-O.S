using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities;

public class Postcode
{
    public int Id { get; set; }
    
    [Required]
    [MaxLength(4)]
    public string Code { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(100)]
    public string Suburb { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(3)]
    public string State { get; set; } = string.Empty;
    
    [MaxLength(100)]
    public string? Region { get; set; }
    
    public decimal? Latitude { get; set; }
    
    public decimal? Longitude { get; set; }
    
    public bool IsActive { get; set; } = true;
    
    // Computed property for display
    public string DisplayName => $"{Suburb}, {State} {Code}";
}