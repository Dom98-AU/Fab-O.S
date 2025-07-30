namespace SteelEstimation.Core.DTOs;

public class PostcodeLookupResult
{
    public string Postcode { get; set; } = string.Empty;
    public string Suburb { get; set; } = string.Empty;
    public string State { get; set; } = string.Empty;
    public string? Region { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
    
    public string DisplayName => $"{Suburb}, {State} {Postcode}";
}