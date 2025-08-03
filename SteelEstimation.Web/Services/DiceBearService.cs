using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using SteelEstimation.Web.Data;

namespace SteelEstimation.Web.Services
{
    public interface IDiceBearService
    {
        Task<string> GetAvatarDataUrlAsync(string style, string seed, Dictionary<string, object>? options = null);
        Task<(bool Success, string? DataUrl, string? ErrorMessage)> TryGetAvatarDataUrlAsync(string style, string seed, Dictionary<string, object>? options = null);
    }

    public class DiceBearService : IDiceBearService
    {
        private readonly HttpClient _httpClient;
        private readonly IMemoryCache _cache;
        private readonly ILogger<DiceBearService> _logger;
        private readonly TimeSpan _cacheExpiration = TimeSpan.FromMinutes(30);

        public DiceBearService(HttpClient httpClient, IMemoryCache cache, ILogger<DiceBearService> logger)
        {
            _httpClient = httpClient;
            _cache = cache;
            _logger = logger;
        }

        public async Task<string> GetAvatarDataUrlAsync(string style, string seed, Dictionary<string, object>? options = null)
        {
            var result = await TryGetAvatarDataUrlAsync(style, seed, options);
            return result.DataUrl ?? GetPlaceholderDataUrl();
        }

        public async Task<(bool Success, string? DataUrl, string? ErrorMessage)> TryGetAvatarDataUrlAsync(string style, string seed, Dictionary<string, object>? options = null)
        {
            if (string.IsNullOrWhiteSpace(style))
            {
                return (false, null, "Avatar style is required");
            }

            if (string.IsNullOrWhiteSpace(seed))
            {
                return (false, null, "Avatar seed is required");
            }

            // Validate style exists
            var avatarStyle = DiceBearAvatars.GetById(style);
            if (avatarStyle == null)
            {
                return (false, null, $"Avatar style '{style}' is not supported");
            }

            var url = "";
            try
            {
                // Generate URL for the avatar
                url = DiceBearAvatars.GenerateAvatarUrl(style, seed, "svg", options);
                _logger.LogInformation("Generated DiceBear URL: {Url}", url);
                
                // Create cache key from URL content hash to prevent collisions
                var cacheKey = $"dicebear_{style}_{seed}_{GetOptionsHash(options)}";
                
                // Check cache first
                if (_cache.TryGetValue<string>(cacheKey, out var cachedDataUrl))
                {
                    _logger.LogDebug("Retrieved DiceBear avatar from cache for style: {Style}, seed: {Seed}", style, seed);
                    return (true, cachedDataUrl, null);
                }
                
                // Fetch SVG content with timeout
                using var response = await _httpClient.GetAsync(url);
                
                if (!response.IsSuccessStatusCode)
                {
                    var errorMessage = $"DiceBear API returned {response.StatusCode}: {response.ReasonPhrase}";
                    _logger.LogWarning("Failed to fetch DiceBear avatar: {ErrorMessage}. URL: {Url}", errorMessage, url);
                    return (false, null, errorMessage);
                }

                var svgContent = await response.Content.ReadAsStringAsync();
                
                if (string.IsNullOrWhiteSpace(svgContent))
                {
                    _logger.LogWarning("DiceBear API returned empty content for URL: {Url}", url);
                    return (false, null, "Received empty avatar content from DiceBear API");
                }

                // Validate that we received valid SVG content
                if (!svgContent.TrimStart().StartsWith("<svg", StringComparison.OrdinalIgnoreCase))
                {
                    _logger.LogWarning("DiceBear API returned invalid SVG content for URL: {Url}", url);
                    return (false, null, "Received invalid SVG content from DiceBear API");
                }
                
                // Use direct SVG data URL (no base64 encoding needed for SVG)
                var encodedSvg = Uri.EscapeDataString(svgContent);
                var dataUrl = $"data:image/svg+xml,{encodedSvg}";
                
                // Cache the result
                _cache.Set(cacheKey, dataUrl, _cacheExpiration);
                
                _logger.LogDebug("Successfully generated DiceBear avatar for style: {Style}, seed: {Seed}", style, seed);
                return (true, dataUrl, null);
            }
            catch (TaskCanceledException ex) when (ex.InnerException is TimeoutException)
            {
                var errorMessage = "Request to DiceBear API timed out";
                _logger.LogWarning(ex, "DiceBear API request timed out for URL: {Url}", url);
                return (false, null, errorMessage);
            }
            catch (HttpRequestException ex)
            {
                var errorMessage = $"Network error while contacting DiceBear API: {ex.Message}";
                _logger.LogError(ex, "HTTP error fetching DiceBear avatar from URL: {Url}", url);
                return (false, null, errorMessage);
            }
            catch (Exception ex)
            {
                var errorMessage = $"Unexpected error generating avatar: {ex.Message}";
                _logger.LogError(ex, "Unexpected error fetching DiceBear avatar from URL: {Url}. Options: {Options}", 
                    url, options != null ? string.Join(", ", options.Select(kv => $"{kv.Key}={kv.Value}")) : "none");
                return (false, null, errorMessage);
            }
        }

        private string GetOptionsHash(Dictionary<string, object>? options)
        {
            if (options == null || !options.Any())
                return "none";

            // Create a consistent hash from options
            var sortedOptions = options.OrderBy(kvp => kvp.Key);
            var optionsString = string.Join("|", sortedOptions.Select(kvp => 
                $"{kvp.Key}={SerializeOptionValue(kvp.Value)}"));
            
            return optionsString.GetHashCode().ToString("X");
        }

        private string SerializeOptionValue(object value)
        {
            return value switch
            {
                string[] array => string.Join(",", array),
                bool boolean => boolean.ToString().ToLower(),
                _ => value?.ToString() ?? "null"
            };
        }

        private string GetPlaceholderDataUrl()
        {
            // Generate a more visually appealing placeholder using direct SVG
            var placeholderSvg = @"<svg width=""60"" height=""60"" viewBox=""0 0 60 60"" fill=""none"" xmlns=""http://www.w3.org/2000/svg"">
  <defs>
    <linearGradient id=""gradient"" x1=""0%"" y1=""0%"" x2=""100%"" y2=""100%"">
      <stop offset=""0%"" stop-color=""#667eea""/>
      <stop offset=""100%"" stop-color=""#764ba2""/>
    </linearGradient>
  </defs>
  <rect width=""60"" height=""60"" fill=""url(#gradient)"" rx=""30""/>
  <circle cx=""30"" cy=""22"" r=""8"" fill=""white"" opacity=""0.8""/>
  <path d=""M15 45c0-8 7-8 15-8s15 0 15 8v5H15v-5z"" fill=""white"" opacity=""0.8""/>
</svg>";
            
            var encodedSvg = Uri.EscapeDataString(placeholderSvg);
            return $"data:image/svg+xml,{encodedSvg}";
        }
    }
}