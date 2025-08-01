using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities
{
    public class ProductLicense
    {
        public int Id { get; set; }
        
        [Required]
        public int CompanyId { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string ProductName { get; set; }
        
        [Required]
        [MaxLength(20)]
        public string LicenseType { get; set; } = "Standard";
        
        public int MaxConcurrentUsers { get; set; } = 5;
        
        public DateTime ValidFrom { get; set; } = DateTime.UtcNow;
        
        [Required]
        public DateTime ValidUntil { get; set; }
        
        public bool IsActive { get; set; } = true;
        
        public List<string> Features { get; set; } = new List<string>();
        
        public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
        
        public DateTime LastModified { get; set; } = DateTime.UtcNow;
        
        public int? CreatedBy { get; set; }
        
        public int? ModifiedBy { get; set; }
        
        // Navigation properties
        public virtual Company Company { get; set; }
        public virtual User CreatedByUser { get; set; }
        public virtual User ModifiedByUser { get; set; }
        public virtual ICollection<UserProductAccess> UserAccess { get; set; } = new List<UserProductAccess>();
        
        // Helper methods
        public bool IsValid()
        {
            return IsActive && ValidUntil > DateTime.UtcNow && ValidFrom <= DateTime.UtcNow;
        }
        
        public bool HasFeature(string featureName)
        {
            return Features != null && Features.Contains(featureName, StringComparer.OrdinalIgnoreCase);
        }
    }
}