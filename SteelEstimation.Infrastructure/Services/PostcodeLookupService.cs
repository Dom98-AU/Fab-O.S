using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SteelEstimation.Core.DTOs;
using SteelEstimation.Core.Interfaces;
using SteelEstimation.Infrastructure.Data;
using System.Net.Http.Json;

namespace SteelEstimation.Infrastructure.Services;

public class PostcodeLookupService : IPostcodeLookupService
{
    private readonly IDbContextFactory<ApplicationDbContext> _dbFactory;
    private readonly HttpClient _httpClient;
    private readonly ILogger<PostcodeLookupService> _logger;
    private readonly bool _useExternalApi;
    private readonly string? _externalApiUrl;

    public PostcodeLookupService(
        IDbContextFactory<ApplicationDbContext> dbFactory,
        HttpClient httpClient,
        IConfiguration configuration,
        ILogger<PostcodeLookupService> logger)
    {
        _dbFactory = dbFactory;
        _httpClient = httpClient;
        _logger = logger;
        _useExternalApi = configuration.GetValue<bool>("PostcodeLookup:UseExternalApi", false);
        _externalApiUrl = configuration["PostcodeLookup:ExternalApiUrl"];
    }

    public async Task<List<PostcodeLookupResult>> LookupByPostcodeAsync(string postcode)
    {
        if (string.IsNullOrWhiteSpace(postcode))
            return new List<PostcodeLookupResult>();

        // Clean the postcode
        postcode = postcode.Trim();

        // Try local database first
        using var context = await _dbFactory.CreateDbContextAsync();
        var localResults = await context.Postcodes
            .Where(p => p.Code == postcode && p.IsActive)
            .Select(p => new PostcodeLookupResult
            {
                Postcode = p.Code,
                Suburb = p.Suburb,
                State = p.State,
                Region = p.Region,
                Latitude = p.Latitude,
                Longitude = p.Longitude
            })
            .ToListAsync();

        if (localResults.Any())
        {
            _logger.LogInformation("Found {Count} results for postcode {Postcode} in local database", 
                localResults.Count, postcode);
            return localResults;
        }

        // If not found locally and external API is configured, try external API
        if (_useExternalApi && !string.IsNullOrEmpty(_externalApiUrl))
        {
            try
            {
                var response = await _httpClient.GetAsync($"{_externalApiUrl}/postcode/{postcode}");
                if (response.IsSuccessStatusCode)
                {
                    var apiResults = await response.Content.ReadFromJsonAsync<List<ExternalPostcodeResult>>();
                    if (apiResults != null && apiResults.Any())
                    {
                        _logger.LogInformation("Found {Count} results for postcode {Postcode} from external API", 
                            apiResults.Count, postcode);
                        
                        // Convert and cache the results
                        var results = apiResults.Select(r => new PostcodeLookupResult
                        {
                            Postcode = r.postcode ?? postcode,
                            Suburb = r.place_name?.ToUpper() ?? "",
                            State = r.state_abbreviation?.ToUpper() ?? "",
                            Latitude = r.latitude,
                            Longitude = r.longitude
                        }).ToList();

                        // Cache the results in local database
                        await CacheResults(results);
                        
                        return results;
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error calling external postcode API for postcode {Postcode}", postcode);
            }
        }

        return new List<PostcodeLookupResult>();
    }

    public async Task<List<PostcodeLookupResult>> SearchBySuburbAsync(string suburb, string? state = null)
    {
        if (string.IsNullOrWhiteSpace(suburb))
            return new List<PostcodeLookupResult>();

        suburb = suburb.ToUpper().Trim();

        using var context = await _dbFactory.CreateDbContextAsync();
        var query = context.Postcodes
            .Where(p => p.Suburb.Contains(suburb) && p.IsActive);

        if (!string.IsNullOrEmpty(state))
        {
            state = state.ToUpper().Trim();
            query = query.Where(p => p.State == state);
        }

        var results = await query
            .OrderBy(p => p.Suburb)
            .ThenBy(p => p.Code)
            .Select(p => new PostcodeLookupResult
            {
                Postcode = p.Code,
                Suburb = p.Suburb,
                State = p.State,
                Region = p.Region,
                Latitude = p.Latitude,
                Longitude = p.Longitude
            })
            .Take(50)
            .ToListAsync();

        return results;
    }

    public async Task<List<PostcodeLookupResult>> GetAutocompleteSuggestionsAsync(string searchTerm, int maxResults = 10)
    {
        if (string.IsNullOrWhiteSpace(searchTerm) || searchTerm.Length < 2)
            return new List<PostcodeLookupResult>();

        searchTerm = searchTerm.ToUpper().Trim();

        using var context = await _dbFactory.CreateDbContextAsync();
        
        // Search by suburb name or postcode
        var results = await context.Postcodes
            .Where(p => p.IsActive && 
                (p.Suburb.StartsWith(searchTerm) || p.Code.StartsWith(searchTerm)))
            .OrderBy(p => p.Suburb)
            .ThenBy(p => p.Code)
            .Select(p => new PostcodeLookupResult
            {
                Postcode = p.Code,
                Suburb = p.Suburb,
                State = p.State,
                Region = p.Region,
                Latitude = p.Latitude,
                Longitude = p.Longitude
            })
            .Take(maxResults)
            .ToListAsync();

        return results;
    }

    private async Task CacheResults(List<PostcodeLookupResult> results)
    {
        try
        {
            using var context = await _dbFactory.CreateDbContextAsync();
            
            foreach (var result in results)
            {
                // Check if already exists
                var exists = await context.Postcodes
                    .AnyAsync(p => p.Code == result.Postcode && 
                                  p.Suburb == result.Suburb && 
                                  p.State == result.State);

                if (!exists)
                {
                    context.Postcodes.Add(new Core.Entities.Postcode
                    {
                        Code = result.Postcode,
                        Suburb = result.Suburb,
                        State = result.State,
                        Region = result.Region,
                        Latitude = result.Latitude,
                        Longitude = result.Longitude,
                        IsActive = true
                    });
                }
            }

            await context.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error caching postcode results");
        }
    }

    // DTO for external API response (adjust based on actual API)
    private class ExternalPostcodeResult
    {
        public string? postcode { get; set; }
        public string? place_name { get; set; }
        public string? state_abbreviation { get; set; }
        public decimal? latitude { get; set; }
        public decimal? longitude { get; set; }
    }
}