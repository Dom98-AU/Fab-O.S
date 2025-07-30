using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities;

public class EstimationTimeLog
{
    public int Id { get; set; }
    
    public int EstimationId { get; set; }
    public int UserId { get; set; }
    
    public DateTime StartTime { get; set; }
    public DateTime? EndTime { get; set; }
    
    // Duration in seconds
    public int Duration { get; set; }
    
    // Is this session currently active
    public bool IsActive { get; set; }
    
    // Session identifier to group time segments
    public Guid SessionId { get; set; }
    
    // Page or area being worked on
    [MaxLength(100)]
    public string? PageName { get; set; }
    
    // Audit fields
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public virtual Project Estimation { get; set; } = null!;
    public virtual User User { get; set; } = null!;
}