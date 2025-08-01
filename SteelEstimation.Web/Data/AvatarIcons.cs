using System.Collections.Generic;

namespace SteelEstimation.Web.Data
{
    public static class AvatarIcons
    {
        public static readonly List<AvatarIcon> AvailableAvatars = new()
        {
            // People & Users
            new AvatarIcon { Id = "user-circle", Icon = "fas fa-user-circle", Name = "User Circle", Category = "People" },
            new AvatarIcon { Id = "user", Icon = "fas fa-user", Name = "User", Category = "People" },
            new AvatarIcon { Id = "user-tie", Icon = "fas fa-user-tie", Name = "Business Person", Category = "People" },
            new AvatarIcon { Id = "user-graduate", Icon = "fas fa-user-graduate", Name = "Graduate", Category = "People" },
            new AvatarIcon { Id = "user-ninja", Icon = "fas fa-user-ninja", Name = "Ninja", Category = "People" },
            new AvatarIcon { Id = "user-secret", Icon = "fas fa-user-secret", Name = "Secret Agent", Category = "People" },
            new AvatarIcon { Id = "user-astronaut", Icon = "fas fa-user-astronaut", Name = "Astronaut", Category = "People" },
            new AvatarIcon { Id = "user-robot", Icon = "fas fa-robot", Name = "Robot", Category = "People" },
            
            // Construction & Tools
            new AvatarIcon { Id = "hard-hat", Icon = "fas fa-hard-hat", Name = "Hard Hat", Category = "Construction" },
            new AvatarIcon { Id = "hammer", Icon = "fas fa-hammer", Name = "Hammer", Category = "Construction" },
            new AvatarIcon { Id = "wrench", Icon = "fas fa-wrench", Name = "Wrench", Category = "Construction" },
            new AvatarIcon { Id = "tools", Icon = "fas fa-tools", Name = "Tools", Category = "Construction" },
            new AvatarIcon { Id = "toolbox", Icon = "fas fa-toolbox", Name = "Toolbox", Category = "Construction" },
            new AvatarIcon { Id = "screwdriver", Icon = "fas fa-screwdriver", Name = "Screwdriver", Category = "Construction" },
            
            // Animals
            new AvatarIcon { Id = "cat", Icon = "fas fa-cat", Name = "Cat", Category = "Animals" },
            new AvatarIcon { Id = "dog", Icon = "fas fa-dog", Name = "Dog", Category = "Animals" },
            new AvatarIcon { Id = "dove", Icon = "fas fa-dove", Name = "Dove", Category = "Animals" },
            new AvatarIcon { Id = "dragon", Icon = "fas fa-dragon", Name = "Dragon", Category = "Animals" },
            new AvatarIcon { Id = "fish", Icon = "fas fa-fish", Name = "Fish", Category = "Animals" },
            new AvatarIcon { Id = "hippo", Icon = "fas fa-hippo", Name = "Hippo", Category = "Animals" },
            new AvatarIcon { Id = "horse", Icon = "fas fa-horse", Name = "Horse", Category = "Animals" },
            new AvatarIcon { Id = "otter", Icon = "fas fa-otter", Name = "Otter", Category = "Animals" },
            new AvatarIcon { Id = "paw", Icon = "fas fa-paw", Name = "Paw", Category = "Animals" },
            
            // Fun & Misc
            new AvatarIcon { Id = "smile", Icon = "fas fa-smile", Name = "Smile", Category = "Fun" },
            new AvatarIcon { Id = "laugh", Icon = "fas fa-laugh", Name = "Laugh", Category = "Fun" },
            new AvatarIcon { Id = "grin", Icon = "fas fa-grin", Name = "Grin", Category = "Fun" },
            new AvatarIcon { Id = "star", Icon = "fas fa-star", Name = "Star", Category = "Fun" },
            new AvatarIcon { Id = "heart", Icon = "fas fa-heart", Name = "Heart", Category = "Fun" },
            new AvatarIcon { Id = "bolt", Icon = "fas fa-bolt", Name = "Lightning", Category = "Fun" },
            new AvatarIcon { Id = "fire", Icon = "fas fa-fire", Name = "Fire", Category = "Fun" },
            new AvatarIcon { Id = "snowflake", Icon = "fas fa-snowflake", Name = "Snowflake", Category = "Fun" },
            
            // Professional
            new AvatarIcon { Id = "briefcase", Icon = "fas fa-briefcase", Name = "Briefcase", Category = "Professional" },
            new AvatarIcon { Id = "building", Icon = "fas fa-building", Name = "Building", Category = "Professional" },
            new AvatarIcon { Id = "industry", Icon = "fas fa-industry", Name = "Industry", Category = "Professional" },
            new AvatarIcon { Id = "chart-line", Icon = "fas fa-chart-line", Name = "Chart", Category = "Professional" },
            new AvatarIcon { Id = "cogs", Icon = "fas fa-cogs", Name = "Gears", Category = "Professional" },
            new AvatarIcon { Id = "shield-alt", Icon = "fas fa-shield-alt", Name = "Shield", Category = "Professional" }
        };

        public static AvatarIcon GetDefault()
        {
            return AvailableAvatars[0]; // Default to user-circle
        }

        public static AvatarIcon? GetById(string id)
        {
            return AvailableAvatars.Find(a => a.Id == id);
        }
    }

    public class AvatarIcon
    {
        public string Id { get; set; } = string.Empty;
        public string Icon { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
    }
}