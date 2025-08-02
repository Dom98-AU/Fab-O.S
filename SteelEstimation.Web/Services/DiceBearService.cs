using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.Extensions.Caching.Memory;
using SteelEstimation.Web.Data;

namespace SteelEstimation.Web.Services
{
    public interface IDiceBearService
    {
        Task<string> GetAvatarDataUrlAsync(string style, string seed, Dictionary<string, object>? options = null);
    }

    public class DiceBearService : IDiceBearService
    {
        private readonly HttpClient _httpClient;
        private readonly IMemoryCache _cache;
        private readonly TimeSpan _cacheExpiration = TimeSpan.FromMinutes(30);

        public DiceBearService(HttpClient httpClient, IMemoryCache cache)
        {
            _httpClient = httpClient;
            _cache = cache;
        }

        public async Task<string> GetAvatarDataUrlAsync(string style, string seed, Dictionary<string, object>? options = null)
        {
            var url = "";
            try
            {
                // Generate URL for the avatar
                url = DiceBearAvatars.GenerateAvatarUrl(style, seed, "svg", options);
                
                // Create cache key from URL
                var cacheKey = $"dicebear_{url}";
                
                // Check cache first
                if (_cache.TryGetValue<string>(cacheKey, out var cachedDataUrl))
                {
                    return cachedDataUrl!;
                }
                
                // Fetch SVG content
                var svgContent = await _httpClient.GetStringAsync(url);
                
                // Convert to base64 data URL
                var base64 = Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(svgContent));
                var dataUrl = $"data:image/svg+xml;base64,{base64}";
                
                // Cache the result
                _cache.Set(cacheKey, dataUrl, _cacheExpiration);
                
                return dataUrl;
            }
            catch (Exception ex)
            {
                // Return a placeholder on error
                Console.WriteLine($"Error fetching DiceBear avatar from URL: {url}");
                Console.WriteLine($"Error details: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                return "data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHZpZXdCb3g9IjAgMCA2MCA2MCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHJlY3Qgd2lkdGg9IjYwIiBoZWlnaHQ9IjYwIiBmaWxsPSIjZjhmOWZhIi8+Cjx0ZXh0IHg9IjMwIiB5PSIzNSIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZmlsbD0iI2E5YTlhOSIgZm9udC1mYW1pbHk9InNhbnMtc2VyaWYiIGZvbnQtc2l6ZT0iMTQiPj88L3RleHQ+Cjwvc3ZnPg==";
            }
        }
    }
}