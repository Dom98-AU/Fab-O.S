using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities
{
    public class ProductRole
    {
        public int Id { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string ProductName { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string RoleName { get; set; }
        
        [MaxLength(500)]
        public string Description { get; set; }
        
        public Dictionary<string, object> Permissions { get; set; } = new Dictionary<string, object>();
        
        // Navigation properties
        public virtual ICollection<UserProductRole> UserProductRoles { get; set; } = new List<UserProductRole>();
        
        // Helper methods
        public bool HasPermission(string permission)
        {
            if (Permissions == null) return false;
            
            // Check if "all" permission is true
            if (Permissions.TryGetValue("all", out var allValue) && allValue is bool all && all)
                return true;
            
            // Check specific permission
            return Permissions.ContainsKey(permission);
        }
        
        public bool HasPermissionForResource(string resource, string action)
        {
            if (Permissions == null) return false;
            
            // Check if "all" permission is true
            if (Permissions.TryGetValue("all", out var allValue) && allValue is bool all && all)
                return true;
            
            // Check resource-specific permissions
            if (Permissions.TryGetValue(resource, out var resourcePerms))
            {
                if (resourcePerms is List<string> actions)
                {
                    return actions.Contains(action, StringComparer.OrdinalIgnoreCase);
                }
                else if (resourcePerms is string[] actionsArray)
                {
                    return Array.Exists(actionsArray, a => a.Equals(action, StringComparison.OrdinalIgnoreCase));
                }
            }
            
            return false;
        }
    }
}