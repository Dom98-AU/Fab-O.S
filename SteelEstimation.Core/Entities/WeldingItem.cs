using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SteelEstimation.Core.Entities;

public class WeldingItem
{
    public int Id { get; set; }
    public int ProjectId { get; set; }
    public int? PackageWorksheetId { get; set; }
    
    [MaxLength(100)]
    public string? DrawingNumber { get; set; }
    
    [MaxLength(500)]
    public string? ItemDescription { get; set; }
    
    [MaxLength(50)]
    public string? WeldType { get; set; }
    
    public decimal WeldLength { get; set; } = 0;
    
    // Weight in kilograms for tonnage calculations
    public decimal Weight { get; set; } = 0;
    
    [MaxLength(500)]
    public string? LocationComments { get; set; }
    
    [MaxLength(200)]
    public string? PhotoReference { get; set; }
    
    // Connection reference
    public int? WeldingConnectionId { get; set; }
    
    public int ConnectionQty { get; set; } = 1;
    
    // Time estimations (in minutes)
    public decimal AssembleFitTack { get; set; } = 5;
    public decimal Weld { get; set; } = 3;
    public decimal WeldCheck { get; set; } = 2;
    public decimal WeldTest { get; set; } = 0;
    
    // Audit fields
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public DateTime LastModified { get; set; } = DateTime.UtcNow;
    public bool IsDeleted { get; set; } = false;
    
    [Timestamp]
    public byte[]? RowVersion { get; set; }
    
    // Navigation properties
    public virtual Project Project { get; set; } = null!;
    public virtual PackageWorksheet? PackageWorksheet { get; set; }
    public virtual WeldingConnection? WeldingConnection { get; set; } // Keep for backward compatibility
    public virtual ICollection<WeldingItemConnection> ItemConnections { get; set; } = new List<WeldingItemConnection>();
    public virtual ICollection<ImageUpload> Images { get; set; } = new List<ImageUpload>();
    
    // Computed properties
    [NotMapped]
    public decimal TotalWeldingMinutes 
    {
        get
        {
            // Only use ItemConnections for calculations per user request
            // Do not fall back to ConnectionQty
            if (ItemConnections != null && ItemConnections.Any())
            {
                return ItemConnections.Sum(ic => ic.TotalMinutes);
            }
            return 0;
        }
    }
}