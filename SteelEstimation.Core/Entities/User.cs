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
    
    // Made nullable for social login users
    [MaxLength(500)]
    public string? PasswordHash { get; set; }
    
    [MaxLength(100)]
    public string? PasswordSalt { get; set; }
    
    [Required, MaxLength(500)]
    public string SecurityStamp { get; set; } = Guid.NewGuid().ToString();
    
    // Authentication provider support
    [Required, MaxLength(50)]
    public string AuthProvider { get; set; } = "Local"; // Local, Microsoft, Google, etc.
    
    [MaxLength(256)]
    public string? ExternalUserId { get; set; } // ID from external provider
    
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
    public virtual ICollection<UserAuthMethod> AuthMethods { get; set; } = new List<UserAuthMethod>();
    
    // New user system navigation properties
    public virtual UserProfile? Profile { get; set; }
    public virtual UserPreference? Preferences { get; set; }
    public virtual ICollection<Comment> Comments { get; set; } = new List<Comment>();
    public virtual ICollection<CommentMention> Mentions { get; set; } = new List<CommentMention>();
    public virtual ICollection<CommentReaction> Reactions { get; set; } = new List<CommentReaction>();
    public virtual ICollection<Notification> Notifications { get; set; } = new List<Notification>();
    public virtual ICollection<UserActivity> Activities { get; set; } = new List<UserActivity>();
    
    // Computed properties
    [NotMapped]
    public string FullName => $"{FirstName} {LastName}".Trim();
    
    [NotMapped]
    public bool IsLockedOut => LockedOutUntil.HasValue && LockedOutUntil > DateTime.UtcNow;
    
    [NotMapped]
    public IEnumerable<string> RoleNames => UserRoles.Select(ur => ur.Role.RoleName);
    
    [NotMapped]
    public bool IsSocialLogin => AuthProvider != "Local";
    
    [NotMapped]
    public bool HasPassword => !string.IsNullOrEmpty(PasswordHash);
}