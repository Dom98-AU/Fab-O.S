using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SteelEstimation.Core.Entities;

public class User
{
    public int Id { get; set; }
    
    [Required, MaxLength(100)]
    public string Username { get; set; } = string.Empty;
    
    [Required, EmailAddress, MaxLength(200)]
    public string Email { get; set; } = string.Empty;
    
    [Required, MaxLength(500)]
    public string PasswordHash { get; set; } = string.Empty;
    
    [Required, MaxLength(500)]
    public string SecurityStamp { get; set; } = Guid.NewGuid().ToString();
    
    [MaxLength(100)]
    public string? FirstName { get; set; }
    
    [MaxLength(100)]
    public string? LastName { get; set; }
    
    [MaxLength(200)]
    public string? CompanyName { get; set; }
    
    // Company relationship
    public int CompanyId { get; set; }
    
    [MaxLength(100)]
    public string? JobTitle { get; set; }
    
    [Phone, MaxLength(20)]
    public string? PhoneNumber { get; set; }
    
    // Account status
    public bool IsActive { get; set; } = true;
    public bool IsEmailConfirmed { get; set; } = false;
    public string? EmailConfirmationToken { get; set; }
    public string? PasswordResetToken { get; set; }
    public DateTime? PasswordResetExpiry { get; set; }
    
    // Login tracking
    public DateTime? LastLoginDate { get; set; }
    public int FailedLoginAttempts { get; set; } = 0;
    public DateTime? LockedOutUntil { get; set; }
    
    // Audit fields
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public DateTime LastModified { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public virtual Company Company { get; set; } = null!;
    public virtual ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
    public virtual ICollection<ProjectUser> ProjectAccess { get; set; } = new List<ProjectUser>();
    public virtual ICollection<Project> OwnedProjects { get; set; } = new List<Project>();
    
    // Computed properties
    [NotMapped]
    public string FullName => $"{FirstName} {LastName}".Trim();
    
    [NotMapped]
    public bool IsLockedOut => LockedOutUntil.HasValue && LockedOutUntil > DateTime.UtcNow;
    
    [NotMapped]
    public IEnumerable<string> RoleNames => UserRoles.Select(ur => ur.Role.RoleName);
}