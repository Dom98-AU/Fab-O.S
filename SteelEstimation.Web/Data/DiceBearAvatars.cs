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
            // People & Characters
            new DiceBearAvatar 
            { 
                Id = "adventurer", 
                Name = "Adventurer", 
                Description = "Modern character avatars with customizable features",
                Category = "People",
                CustomizationOptions = new() { "seed", "flip", "backgroundColor", "hair", "skinColor", "eyes", "mouth" },
                License = "CC BY 4.0",
                Creator = "Lisa Wischofsky"
            },
            new DiceBearAvatar 
            { 
                Id = "avataaars", 
                Name = "Avataaars", 
                Description = "Cartoon-style avatars inspired by Pablo Stanley's work",
                Category = "People",
                CustomizationOptions = new() { "seed", "flip", "backgroundColor", "hair", "eyes", "eyebrows", "mouth", "mustache", "beard", "accessories" },
                License = "Free for personal and commercial use",
                Creator = "Pablo Stanley"
            },
            new DiceBearAvatar 
            { 
                Id = "big-ears", 
                Name = "Big Ears", 
                Description = "Cute character avatars with prominent ears",
                Category = "People",
                CustomizationOptions = new() { "seed", "flip", "backgroundColor", "hair", "skinColor", "eyes", "mouth" },
                License = "CC BY 4.0",
                Creator = "Face Your Manga"
            },
            new DiceBearAvatar 
            { 
                Id = "big-smile", 
                Name = "Big Smile", 
                Description = "Happy character avatars with big smiles",
                Category = "People",
                CustomizationOptions = new() { "seed", "flip", "backgroundColor", "hair", "skinColor", "eyes", "mouth" },
                License = "CC BY 4.0",
                Creator = "Ashley Seo"
            },
            new DiceBearAvatar 
            { 
                Id = "dylan", 
                Name = "Dylan", 
                Description = "Minimalist character avatars",
                Category = "People",
                CustomizationOptions = new() { "seed", "flip", "backgroundColor", "hair", "skinColor", "eyes", "mouth" },
                License = "CC BY 4.0",
                Creator = "Natasha Remarchuk"
            },
            new DiceBearAvatar 
            { 
                Id = "lorelei", 
                Name = "Lorelei", 
                Description = "Elegant female character avatars",
                Category = "People",
                CustomizationOptions = new() { "seed", "flip", "backgroundColor", "hair", "skinColor", "eyes", "mouth" },
                License = "CC BY 4.0",
                Creator = "Lisa Wischofsky"
            },
            new DiceBearAvatar 
            { 
                Id = "micah", 
                Name = "Micah", 
                Description = "Simple and clean character avatars",
                Category = "People",
                CustomizationOptions = new() { "seed", "flip", "backgroundColor", "hair", "skinColor", "eyes", "mouth", "facialHair" },
                License = "CC BY 4.0",
                Creator = "Micah Lanier"
            },
            new DiceBearAvatar 
            { 
                Id = "miniavs", 
                Name = "Miniavs", 
                Description = "Tiny pixel-style character avatars",
                Category = "People",
                CustomizationOptions = new() { "seed", "flip", "backgroundColor", "hair", "skinColor", "eyes", "mouth" },
                License = "CC BY 4.0",
                Creator = "Webpixels"
            },
            new DiceBearAvatar 
            { 
                Id = "notionists", 
                Name = "Notionists", 
                Description = "Professional-looking character avatars",
                Category = "People",
                CustomizationOptions = new() { "seed", "flip", "backgroundColor", "hair", "skinColor", "eyes", "mouth", "beard" },
                License = "CC BY 4.0",
                Creator = "Zoish"
            },
            new DiceBearAvatar 
            { 
                Id = "open-peeps", 
                Name = "Open Peeps", 
                Description = "Hand-drawn character avatars with various poses",
                Category = "People",
                CustomizationOptions = new() { "seed", "flip", "backgroundColor", "hair", "skinColor", "eyes", "mouth", "body", "clothing" },
                License = "CC BY 4.0",
                Creator = "Pablo Stanley"
            },
            new DiceBearAvatar 
            { 
                Id = "personas", 
                Name = "Personas", 
                Description = "Diverse character avatars representing different personas",
                Category = "People",
                CustomizationOptions = new() { "seed", "flip", "backgroundColor", "hair", "skinColor", "eyes", "mouth" },
                License = "CC BY 4.0",
                Creator = "Draftbit"
            },

            // Fun & Creative
            new DiceBearAvatar 
            { 
                Id = "bottts", 
                Name = "Bottts", 
                Description = "Robot-style avatars with various mechanical features",
                Category = "Fun",
                CustomizationOptions = new() { "seed", "flip", "backgroundColor", "eyes", "mouth", "sides", "texture", "primaryColor" },
                License = "CC BY 4.0",
                Creator = "Pablo Stanley"
            },
            new DiceBearAvatar 
            { 
                Id = "croodles", 
                Name = "Croodles", 
                Description = "Doodle-style character avatars",
                Category = "Fun",
                CustomizationOptions = new() { "seed", "flip", "backgroundColor", "hair", "eyes", "mouth" },
                License = "CC BY 4.0",
                Creator = "vijay verma"
            },
            new DiceBearAvatar 
            { 
                Id = "fun-emoji", 
                Name = "Fun Emoji", 
                Description = "Emoji-style avatars with various expressions",
                Category = "Fun",
                CustomizationOptions = new() { "seed", "flip", "backgroundColor", "eyes", "mouth" },
                License = "CC BY 4.0",
                Creator = "Davis Uche"
            },

            // Abstract & Minimal
            new DiceBearAvatar 
            { 
                Id = "glass", 
                Name = "Glass", 
                Description = "Glassmorphism-style abstract avatars",
                Category = "Abstract",
                CustomizationOptions = new() { "seed", "flip", "backgroundColor" },
                License = "MIT",
                Creator = "DiceBear"
            },
            new DiceBearAvatar 
            { 
                Id = "icons", 
                Name = "Icons", 
                Description = "Simple icon-based avatars",
                Category = "Abstract",
                CustomizationOptions = new() { "seed", "flip", "backgroundColor" },
                License = "MIT",
                Creator = "The Bootstrap Team"
            },
            new DiceBearAvatar 
            { 
                Id = "identicon", 
                Name = "Identicon", 
                Description = "Geometric pattern avatars based on hash",
                Category = "Abstract",
                CustomizationOptions = new() { "seed", "backgroundColor" },
                License = "MIT",
                Creator = "DiceBear"
            },
            new DiceBearAvatar 
            { 
                Id = "initials", 
                Name = "Initials", 
                Description = "Text-based avatars using initials",
                Category = "Abstract",
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
                        queryParams.Add($"{option.Key}={Uri.EscapeDataString(string.Join(",", stringArray))}");
                    }
                    else if (option.Value is string stringValue)
                    {
                        queryParams.Add($"{option.Key}={Uri.EscapeDataString(stringValue)}");
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