using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SteelEstimation.Core.Entities;

public class ProcessingItemWorkCenterTime
{
    public int Id { get; set; }
    
    // Link to ProcessingItem
    public int ProcessingItemId { get; set; }
    public virtual ProcessingItem ProcessingItem { get; set; } = null!;
    
    // Link to WorkCenter
    public int WorkCenterId { get; set; }
    public virtual WorkCenter WorkCenter { get; set; } = null!;
    
    // Manual time entry in minutes
    [Column(TypeName = "decimal(10,2)")]
    public decimal ManualTimeMinutes { get; set; } = 0;
    
    // Override rates (optional - if null, use WorkCenter defaults)
    [Column(TypeName = "decimal(10,2)")]
    public decimal? OverrideHourlyRate { get; set; }
    
    // Dependency factor for this specific item/workcenter combination
    [Column(TypeName = "decimal(5,2)")]
    public decimal DependencyFactor { get; set; } = 1.0m;
    
    // Notes for this operation
    [MaxLength(500)]
    public string? Notes { get; set; }
    
    // Calculated fields (stored for performance)
    [Column(TypeName = "decimal(12,2)")]
    public decimal CalculatedCost { get; set; } = 0;
    
    [Column(TypeName = "decimal(10,2)")]
    public decimal EffectiveTimeMinutes { get; set; } = 0; // After applying dependencies
    
    // Status tracking
    public bool IsCompleted { get; set; } = false;
    public DateTime? CompletedDate { get; set; }
    
    // Audit fields
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public DateTime LastModified { get; set; } = DateTime.UtcNow;
    public int? LastModifiedByUserId { get; set; }
    public virtual User? LastModifiedByUser { get; set; }
    
    // For optimistic concurrency
    [Timestamp]
    public byte[]? RowVersion { get; set; }
}