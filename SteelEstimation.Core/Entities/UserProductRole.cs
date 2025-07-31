using System;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities
{
    public class UserProductRole
    {
        public int Id { get; set; }
        
        [Required]
        public int UserId { get; set; }
        
        [Required]
        public int ProductRoleId { get; set; }
        
        public DateTime AssignedDate { get; set; } = DateTime.UtcNow;
        
        public int? AssignedBy { get; set; }
        
        // Navigation properties
        public virtual User User { get; set; }
        public virtual ProductRole ProductRole { get; set; }
        public virtual User AssignedByUser { get; set; }
    }
}