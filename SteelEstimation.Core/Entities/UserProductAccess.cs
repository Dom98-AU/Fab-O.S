using System;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities
{
    public class UserProductAccess
    {
        public int Id { get; set; }
        
        [Required]
        public int UserId { get; set; }
        
        [Required]
        public int ProductLicenseId { get; set; }
        
        public DateTime LastAccessDate { get; set; } = DateTime.UtcNow;
        
        public bool IsCurrentlyActive { get; set; }
        
        // Navigation properties
        public virtual User User { get; set; }
        public virtual ProductLicense ProductLicense { get; set; }
        
        // Helper methods
        public void UpdateAccess()
        {
            LastAccessDate = DateTime.UtcNow;
            IsCurrentlyActive = true;
        }
        
        public void EndSession()
        {
            IsCurrentlyActive = false;
        }
    }
}