using SteelEstimation.Core.DTOs;

namespace SteelEstimation.Core.Interfaces;

public interface IPostcodeLookupService
{
    /// <summary>
    /// Lookup suburb and state by postcode
    /// </summary>
    /// <param name="postcode">The postcode to lookup</param>
    /// <returns>List of matching locations</returns>
    Task<List<PostcodeLookupResult>> LookupByPostcodeAsync(string postcode);
    
    /// <summary>
    /// Search for postcodes by suburb name
    /// </summary>
    /// <param name="suburb">The suburb name to search for</param>
    /// <param name="state">Optional state filter</param>
    /// <returns>List of matching locations</returns>
    Task<List<PostcodeLookupResult>> SearchBySuburbAsync(string suburb, string? state = null);
    
    /// <summary>
    /// Get all suburbs for autocomplete
    /// </summary>
    /// <param name="searchTerm">The search term</param>
    /// <param name="maxResults">Maximum number of results</param>
    /// <returns>List of matching locations</returns>
    Task<List<PostcodeLookupResult>> GetAutocompleteSuggestionsAsync(string searchTerm, int maxResults = 10);
}