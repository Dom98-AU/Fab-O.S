using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SteelEstimation.Core.Entities;

public class ProcessingItem
{
    public int Id { get; set; }
    public int ProjectId { get; set; }
    public int? PackageWorksheetId { get; set; }
    
    [MaxLength(100)]
    public string? DrawingNumber { get; set; }
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    [MaxLength(100)]
    public string? MaterialId { get; set; }  // This is the MBE ID imported from Excel
    
    public int Quantity { get; set; } = 0;
    public decimal Length { get; set; } = 0;
    public decimal Weight { get; set; } = 0;
    
    // Bundle and packaging info
    public int DeliveryBundleQty { get; set; } = 1;
    public int PackBundleQty { get; set; } = 1;
    
    [MaxLength(50)]
    public string? BundleGroup { get; set; }
    
    [MaxLength(50)]
    public string? PackGroup { get; set; }
    
    // Time estimations (in minutes)
    public int UnloadTimePerBundle { get; set; } = 15;
    public int MarkMeasureCut { get; set; } = 30;
    public int QualityCheckClean { get; set; } = 15;
    public int MoveToAssembly { get; set; } = 20;
    public int MoveAfterWeld { get; set; } = 20;
    public int LoadingTimePerBundle { get; set; } = 15;
    
    // Delivery Bundle fields
    public int? DeliveryBundleId { get; set; }
    public bool IsParentInBundle { get; set; } = false;
    
    // Pack Bundle fields
    public int? PackBundleId { get; set; }
    public bool IsParentInPackBundle { get; set; } = false;
    
    // Routing Operation link
    public int? RoutingOperationId { get; set; }
    
    // Audit fields
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public DateTime LastModified { get; set; } = DateTime.UtcNow;
    public bool IsDeleted { get; set; } = false;
    
    [Timestamp]
    public byte[]? RowVersion { get; set; }
    
    // Navigation properties
    public virtual Project Project { get; set; } = null!;
    public virtual PackageWorksheet? PackageWorksheet { get; set; }
    public virtual DeliveryBundle? DeliveryBundle { get; set; }
    public virtual PackBundle? PackBundle { get; set; }
    public virtual RoutingOperation? RoutingOperation { get; set; }
    public virtual ICollection<ProcessingItemWorkCenterTime> WorkCenterTimes { get; set; } = new List<ProcessingItemWorkCenterTime>();
    
    // Computed properties
    [NotMapped]
    public decimal TotalWeight => Weight * Quantity;
    
    [NotMapped]
    public int DeliveryBundles => Quantity > 0 && DeliveryBundleQty > 0 ? (int)Math.Ceiling((double)Quantity / DeliveryBundleQty) : 0;
    
    [NotMapped]
    public int PackBundles => Quantity > 0 && PackBundleQty > 0 ? (int)Math.Ceiling((double)Quantity / PackBundleQty) : 0;
    
    [NotMapped]
    public decimal TotalProcessingMinutes => 
        (DeliveryBundleId == null || IsParentInBundle ? UnloadTimePerBundle : 0) +
        (MarkMeasureCut * Quantity) +
        (QualityCheckClean * Quantity) +
        (PackBundleId == null || IsParentInPackBundle ? MoveToAssembly * PackBundles : 0) +
        (PackBundleId == null || IsParentInPackBundle ? MoveAfterWeld * PackBundles : 0) +
        (DeliveryBundleId == null || IsParentInBundle ? LoadingTimePerBundle : 0);
}