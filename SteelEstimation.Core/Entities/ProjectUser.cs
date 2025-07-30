using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities;

public class ProjectUser
{
    public int ProjectId { get; set; }
    public int UserId { get; set; }
    
    [MaxLength(20)]
    public string AccessLevel { get; set; } = "ReadWrite"; // ReadOnly, ReadWrite, Owner
    
    public DateTime GrantedDate { get; set; } = DateTime.UtcNow;
    public int? GrantedBy { get; set; }
    
    // Navigation properties
    public virtual Project Project { get; set; } = null!;
    public virtual User User { get; set; } = null!;
    public virtual User? GrantedByUser { get; set; }
}