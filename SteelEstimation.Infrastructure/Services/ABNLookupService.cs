using System.Xml.Linq;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SteelEstimation.Core.DTOs;
using SteelEstimation.Core.Interfaces;

namespace SteelEstimation.Infrastructure.Services;

public class ABNLookupService : IABNLookupService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<ABNLookupService> _logger;
    private readonly string _guid;
    private readonly string _baseUrl = "https://abr.business.gov.au/abrxmlsearch/AbrXmlSearch.asmx";
    
    public ABNLookupService(HttpClient httpClient, IConfiguration configuration, ILogger<ABNLookupService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
        _guid = configuration["ABRWebServices:GUID"] ?? "";
        
        if (string.IsNullOrEmpty(_guid) || _guid.Contains("YOUR") || _guid.Contains("GUID_HERE"))
        {
            _logger.LogWarning("ABR Web Services GUID not configured. ABN lookup functionality will be disabled.");
            _guid = "";
        }
    }
    
    public async Task<ABNLookupResult?> LookupABNAsync(string abn)
    {
        try
        {
            // Check if GUID is configured
            if (string.IsNullOrEmpty(_guid))
            {
                _logger.LogWarning("ABN lookup attempted but GUID not configured");
                return null;
            }
            
            // Clean the ABN
            abn = abn.Replace(" ", "").Replace("-", "");
            
            if (!ValidateABN(abn))
            {
                _logger.LogWarning("Invalid ABN format: {ABN}", abn);
                return null;
            }
            
            var url = $"{_baseUrl}/ABRSearchByABN?searchString={abn}&includeHistoricalDetails=N&authenticationGuid={_guid}";
            
            var response = await _httpClient.GetAsync(url);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError("ABR API returned status code {StatusCode}", response.StatusCode);
                return null;
            }
            
            var xml = await response.Content.ReadAsStringAsync();
            var doc = XDocument.Parse(xml);
            
            var ns = XNamespace.Get("http://abr.business.gov.au/ABRXMLSearch/");
            var businessEntity = doc.Descendants(ns + "businessEntity").FirstOrDefault();
            
            if (businessEntity == null)
            {
                _logger.LogInformation("No business entity found for ABN: {ABN}", abn);
                return null;
            }
            
            var result = new ABNLookupResult
            {
                ABN = abn,
                ACN = businessEntity.Element(ns + "ASICNumber")?.Value,
                EntityTypeName = businessEntity.Element(ns + "entityTypeName")?.Value ?? "Unknown",
                EntityTypeCode = businessEntity.Element(ns + "entityTypeCode")?.Value ?? "Unknown",
                IsActive = businessEntity.Element(ns + "entityStatus")?.Element(ns + "entityStatusCode")?.Value == "Active"
            };
            
            // Get main business name
            var mainName = businessEntity.Element(ns + "mainName");
            if (mainName != null)
            {
                result.BusinessName = mainName.Element(ns + "organisationName")?.Value ?? "";
            }
            
            // Get main trading name
            var mainTradingName = businessEntity.Element(ns + "mainTradingName");
            if (mainTradingName != null)
            {
                result.TradingName = mainTradingName.Element(ns + "organisationName")?.Value;
            }
            
            // Get GST status
            var gst = businessEntity.Element(ns + "goodsAndServicesTax");
            if (gst != null)
            {
                var effectiveFrom = gst.Element(ns + "effectiveFrom")?.Value;
                if (!string.IsNullOrEmpty(effectiveFrom) && DateTime.TryParse(effectiveFrom, out var gstDate))
                {
                    result.GST = gstDate;
                }
            }
            
            // Get business address
            var addressElement = businessEntity.Element(ns + "mainBusinessPhysicalAddress");
            if (addressElement != null)
            {
                result.MainBusinessAddress = new BusinessAddress
                {
                    AddressLine1 = addressElement.Element(ns + "addressLine1")?.Value,
                    AddressLine2 = addressElement.Element(ns + "addressLine2")?.Value,
                    Suburb = addressElement.Element(ns + "suburb")?.Value,
                    State = addressElement.Element(ns + "stateCode")?.Value ?? "",
                    Postcode = addressElement.Element(ns + "postcode")?.Value ?? ""
                };
            }
            
            result.LastUpdated = DateTime.UtcNow;
            
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error looking up ABN {ABN}", abn);
            return null;
        }
    }
    
    public bool ValidateABN(string abn)
    {
        // Remove spaces and hyphens
        abn = abn.Replace(" ", "").Replace("-", "");
        
        // Check if it's 11 digits
        if (abn.Length != 11 || !abn.All(char.IsDigit))
        {
            return false;
        }
        
        // ABN checksum validation
        int[] weights = { 10, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19 };
        int checksum = 0;
        
        // Subtract 1 from the first digit
        int[] digits = abn.Select(c => int.Parse(c.ToString())).ToArray();
        digits[0] -= 1;
        
        // Calculate weighted sum
        for (int i = 0; i < 11; i++)
        {
            checksum += digits[i] * weights[i];
        }
        
        // Check if divisible by 89
        return checksum % 89 == 0;
    }
    
    public async Task<List<ABNSearchResult>> SearchByNameAsync(string businessName, int maxResults = 10)
    {
        try
        {
            // Check if GUID is configured
            if (string.IsNullOrEmpty(_guid))
            {
                _logger.LogWarning("ABN search attempted but GUID not configured");
                return new List<ABNSearchResult>();
            }
            
            if (string.IsNullOrWhiteSpace(businessName))
            {
                return new List<ABNSearchResult>();
            }
            
            var url = $"{_baseUrl}/ABRSearchByName?name={Uri.EscapeDataString(businessName)}&maxSearchResults={maxResults}&authenticationGuid={_guid}";
            
            var response = await _httpClient.GetAsync(url);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError("ABR API returned status code {StatusCode}", response.StatusCode);
                return new List<ABNSearchResult>();
            }
            
            var xml = await response.Content.ReadAsStringAsync();
            var doc = XDocument.Parse(xml);
            
            var ns = XNamespace.Get("http://abr.business.gov.au/ABRXMLSearch/");
            var searchResults = new List<ABNSearchResult>();
            
            foreach (var record in doc.Descendants(ns + "searchResultsRecord"))
            {
                var abn = record.Element(ns + "ABN")?.Element(ns + "identifierValue")?.Value;
                if (string.IsNullOrEmpty(abn)) continue;
                
                var result = new ABNSearchResult
                {
                    ABN = abn,
                    IsActive = record.Element(ns + "ABN")?.Element(ns + "identifierStatus")?.Value == "Active"
                };
                
                // Get business name
                var mainName = record.Element(ns + "mainName");
                if (mainName != null)
                {
                    result.BusinessName = mainName.Element(ns + "organisationName")?.Value ?? "";
                }
                
                // Get trading name
                var tradingName = record.Element(ns + "mainTradingName");
                if (tradingName != null)
                {
                    result.TradingName = tradingName.Element(ns + "organisationName")?.Value;
                }
                
                // Get location
                var address = record.Element(ns + "mainBusinessPhysicalAddress");
                if (address != null)
                {
                    result.State = address.Element(ns + "stateCode")?.Value ?? "";
                    result.Postcode = address.Element(ns + "postcode")?.Value ?? "";
                }
                
                searchResults.Add(result);
            }
            
            return searchResults;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error searching for businesses with name {BusinessName}", businessName);
            return new List<ABNSearchResult>();
        }
    }
}