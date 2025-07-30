namespace SteelEstimation.Core.DTOs;

public class ABNLookupResult
{
    public string ABN { get; set; } = string.Empty;
    public string? ACN { get; set; }
    public string BusinessName { get; set; } = string.Empty;
    public string? TradingName { get; set; }
    public string EntityTypeName { get; set; } = string.Empty;
    public string EntityTypeCode { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTime? GST { get; set; }
    public BusinessAddress? MainBusinessAddress { get; set; }
    public DateTime LastUpdated { get; set; }
}

public class ABNSearchResult
{
    public string ABN { get; set; } = string.Empty;
    public string BusinessName { get; set; } = string.Empty;
    public string? TradingName { get; set; }
    public string State { get; set; } = string.Empty;
    public string Postcode { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}

public class BusinessAddress
{
    public string? AddressLine1 { get; set; }
    public string? AddressLine2 { get; set; }
    public string? Suburb { get; set; }
    public string State { get; set; } = string.Empty;
    public string Postcode { get; set; } = string.Empty;
}