using System.Collections.Generic;

namespace SteelEstimation.Web.Data
{
    public class DiceBearAvatar
    {
        public string Id { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public List<string> CustomizationOptions { get; set; } = new();
        public string License { get; set; } = string.Empty;
        public string Creator { get; set; } = string.Empty;
    }

    public static class DiceBearAvatars
    {
        public static readonly List<DiceBearAvatar> AvailableStyles = new()
        {
            new DiceBearAvatar 
            { 
                Id = "bottts", 
                Name = "Robot Avatar", 
                Description = "Customizable robot-style avatars with various mechanical features",
                Category = "Avatars",
                CustomizationOptions = new() { "seed", "flip", "backgroundColor", "baseColor", "eyes", "face", "mouth", "sides", "texture", "top" },
                License = "CC BY 4.0",
                Creator = "Pablo Stanley"
            },
            new DiceBearAvatar 
            { 
                Id = "initials", 
                Name = "Text Initials", 
                Description = "Professional text-based avatars using initials",
                Category = "Avatars",
                CustomizationOptions = new() { "seed", "backgroundColor", "fontSize", "fontFamily", "fontWeight" },
                License = "MIT",
                Creator = "DiceBear"
            }
        };

        public static DiceBearAvatar? GetById(string id)
        {
            return AvailableStyles.FirstOrDefault(a => a.Id == id);
        }

        public static List<DiceBearAvatar> GetByCategory(string category)
        {
            return AvailableStyles.Where(a => a.Category == category).ToList();
        }

        // Overload for backward compatibility with simple string options
        public static string GenerateAvatarUrl(string styleId, string seed, string format = "svg")
        {
            return GenerateAvatarUrl(styleId, seed, format, null);
        }

        public static string GenerateAvatarUrl(string styleId, string seed, string format = "svg", Dictionary<string, object>? options = null)
        {
            var baseUrl = $"https://api.dicebear.com/9.x/{styleId}/{format}";
            var queryParams = new List<string> { $"seed={Uri.EscapeDataString(seed)}" };

            if (options != null)
            {
                foreach (var option in options)
                {
                    if (option.Value is bool boolValue)
                    {
                        queryParams.Add($"{option.Key}={boolValue.ToString().ToLower()}");
                    }
                    else if (option.Value is string[] stringArray)
                    {
                        // For single-value arrays, just use the first value
                        if (stringArray.Length == 1)
                        {
                            queryParams.Add($"{option.Key}={Uri.EscapeDataString(stringArray[0])}");
                        }
                        else
                        {
                            queryParams.Add($"{option.Key}={Uri.EscapeDataString(string.Join(",", stringArray))}");
                        }
                    }
                    else if (option.Value is string stringValue)
                    {
                        // For color values, remove the hash symbol
                        if ((option.Key == "primaryColor" || option.Key == "backgroundColor" || option.Key == "baseColor") && stringValue.StartsWith("#"))
                        {
                            queryParams.Add($"{option.Key}={stringValue.Substring(1)}");
                        }
                        else
                        {
                            queryParams.Add($"{option.Key}={Uri.EscapeDataString(stringValue)}");
                        }
                    }
                }
            }

            return $"{baseUrl}?{string.Join("&", queryParams)}";
        }

        public static string GenerateRandomSeed()
        {
            return Guid.NewGuid().ToString("N")[..8];
        }
    }
}