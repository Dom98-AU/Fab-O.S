using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities;

public class Package
{
    public int Id { get; set; }
    
    public int ProjectId { get; set; }
    
    [Required, MaxLength(50)]
    public string PackageNumber { get; set; } = string.Empty;
    
    [Required, MaxLength(200)]
    public string PackageName { get; set; } = string.Empty;
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    [MaxLength(50)]
    public string Status { get; set; } = "Draft"; // Draft, InProgress, Completed, Approved
    
    // Schedule
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    
    // Package-level estimations
    public decimal EstimatedHours { get; set; } = 0;
    public decimal EstimatedCost { get; set; } = 0;
    public decimal ActualHours { get; set; } = 0;
    public decimal ActualCost { get; set; } = 0;
    
    // Labor rate
    public decimal LaborRatePerHour { get; set; } = 0;
    
    // Processing efficiency percentage (100 = normal, <100 = faster, >100 = slower)
    public decimal? ProcessingEfficiency { get; set; }
    
    // Reference to efficiency rate configuration
    public int? EfficiencyRateId { get; set; }
    
    // Reference to routing (renamed from RoutingTemplateId)
    public int? RoutingId { get; set; }
    
    // Tracking
    public int? CreatedBy { get; set; }
    public int? LastModifiedBy { get; set; }
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public DateTime LastModified { get; set; } = DateTime.UtcNow;
    public bool IsDeleted { get; set; } = false;
    
    // Navigation properties
    public virtual Project Project { get; set; } = null!;
    public virtual User? CreatedByUser { get; set; }
    public virtual User? LastModifiedByUser { get; set; }
    public virtual EfficiencyRate? EfficiencyRate { get; set; }
    public virtual RoutingTemplate? Routing { get; set; }
    public virtual ICollection<PackageWorksheet> Worksheets { get; set; } = new List<PackageWorksheet>();
    public virtual ICollection<DeliveryBundle> DeliveryBundles { get; set; } = new List<DeliveryBundle>();
    public virtual ICollection<PackBundle> PackBundles { get; set; } = new List<PackBundle>();
    public virtual ICollection<WeldingConnection> WeldingConnections { get; set; } = new List<WeldingConnection>();
}