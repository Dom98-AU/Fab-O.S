using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities;

public class WeldingItemConnection
{
    public int Id { get; set; }
    
    public int WeldingItemId { get; set; }
    public int WeldingConnectionId { get; set; }
    
    // Quantity of this connection type
    public int Quantity { get; set; } = 1;
    
    // Override time values (null = use connection defaults)
    public decimal? AssembleFitTack { get; set; }
    public decimal? Weld { get; set; }
    public decimal? WeldCheck { get; set; }
    public decimal? WeldTest { get; set; }
    
    // Computed time values (use overrides if set, otherwise connection defaults)
    public decimal ActualAssembleFitTack => AssembleFitTack ?? WeldingConnection?.DefaultAssembleFitTack ?? 0;
    public decimal ActualWeld => Weld ?? WeldingConnection?.DefaultWeld ?? 0;
    public decimal ActualWeldCheck => WeldCheck ?? WeldingConnection?.DefaultWeldCheck ?? 0;
    public decimal ActualWeldTest => WeldTest ?? WeldingConnection?.DefaultWeldTest ?? 0;
    
    // Total minutes for this connection
    public decimal TotalMinutes => (ActualAssembleFitTack + ActualWeld + ActualWeldCheck + ActualWeldTest) * Quantity;
    
    // Navigation properties
    public virtual WeldingItem WeldingItem { get; set; } = null!;
    public virtual WeldingConnection WeldingConnection { get; set; } = null!;
}