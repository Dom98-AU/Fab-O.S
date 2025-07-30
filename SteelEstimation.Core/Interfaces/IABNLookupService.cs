using SteelEstimation.Core.DTOs;

namespace SteelEstimation.Core.Interfaces;

public interface IABNLookupService
{
    /// <summary>
    /// Lookup business details by ABN using the Australian Business Register
    /// </summary>
    /// <param name="abn">The ABN to lookup (11 digits)</param>
    /// <returns>Business details if found, null otherwise</returns>
    Task<ABNLookupResult?> LookupABNAsync(string abn);
    
    /// <summary>
    /// Validate if an ABN is correctly formatted and passes checksum validation
    /// </summary>
    /// <param name="abn">The ABN to validate</param>
    /// <returns>True if valid, false otherwise</returns>
    bool ValidateABN(string abn);
    
    /// <summary>
    /// Search for businesses by name
    /// </summary>
    /// <param name="businessName">The business name to search for</param>
    /// <param name="maxResults">Maximum number of results to return</param>
    /// <returns>List of matching businesses</returns>
    Task<List<ABNSearchResult>> SearchByNameAsync(string businessName, int maxResults = 10);
}