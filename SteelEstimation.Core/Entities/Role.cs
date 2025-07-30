using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities;

public class Role
{
    public int Id { get; set; }
    
    [Required, MaxLength(50)]
    public string RoleName { get; set; } = string.Empty;
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    // Permissions
    public bool CanCreateProjects { get; set; } = true;
    public bool CanEditProjects { get; set; } = true;
    public bool CanDeleteProjects { get; set; } = false;
    public bool CanViewAllProjects { get; set; } = false;
    public bool CanManageUsers { get; set; } = false;
    public bool CanExportData { get; set; } = true;
    public bool CanImportData { get; set; } = true;
    
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public virtual ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
}