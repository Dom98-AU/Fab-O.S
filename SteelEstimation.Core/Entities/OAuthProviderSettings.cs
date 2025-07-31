using System;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities
{
    /// <summary>
    /// Configuration for OAuth providers shown on login/signup pages
    /// </summary>
    public class OAuthProviderSettings
    {
        public int Id { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string ProviderName { get; set; } = string.Empty;
        
        public bool IsEnabled { get; set; }
        
        [Required]
        [MaxLength(100)]
        public string DisplayName { get; set; } = string.Empty;
        
        [MaxLength(100)]
        public string? IconClass { get; set; } // Font Awesome class like "fab fa-microsoft"
        
        [MaxLength(20)]
        public string? ButtonColor { get; set; } // CSS color like "#0078d4"
        
        public int SortOrder { get; set; }
        
        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
        
        public DateTime ModifiedDate { get; set; } = DateTime.UtcNow;
    }
}