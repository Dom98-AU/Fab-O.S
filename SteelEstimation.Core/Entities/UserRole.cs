namespace SteelEstimation.Core.Entities;

public class UserRole
{
    public int UserId { get; set; }
    public int RoleId { get; set; }
    public DateTime AssignedDate { get; set; } = DateTime.UtcNow;
    public int? AssignedBy { get; set; }
    
    // Navigation properties
    public virtual User User { get; set; } = null!;
    public virtual Role Role { get; set; } = null!;
    public virtual User? AssignedByUser { get; set; }
}