using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SteelEstimation.Core.Entities;

public class RoutingOperation
{
    public int Id { get; set; }
    
    // Link to routing template
    public int RoutingTemplateId { get; set; }
    public virtual RoutingTemplate RoutingTemplate { get; set; } = null!;
    
    // Link to work center where this operation is performed
    public int WorkCenterId { get; set; }
    public virtual WorkCenter WorkCenter { get; set; } = null!;
    
    // Optional link to specific machine center
    public int? MachineCenterId { get; set; }
    public virtual MachineCenter? MachineCenter { get; set; }
    
    // Operation details
    [Required]
    [MaxLength(50)]
    public string OperationCode { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(200)]
    public string OperationName { get; set; } = string.Empty;
    
    [MaxLength(1000)]
    public string? Description { get; set; }
    
    // Sequence in the routing
    public int SequenceNumber { get; set; }
    
    // Operation type
    [Required]
    [MaxLength(50)]
    public string OperationType { get; set; } = "Processing"; // Processing, Setup, QualityControl, Movement, Waiting
    
    // Time estimates (in minutes)
    [Column(TypeName = "decimal(10,2)")]
    public decimal SetupTimeMinutes { get; set; } = 0;
    
    [Column(TypeName = "decimal(10,2)")]
    public decimal ProcessingTimePerUnit { get; set; } = 0; // Time per unit/piece
    
    [Column(TypeName = "decimal(10,2)")]
    public decimal ProcessingTimePerKg { get; set; } = 0; // Time per kilogram (for weight-based calculations)
    
    [Column(TypeName = "decimal(10,2)")]
    public decimal MovementTimeMinutes { get; set; } = 0;
    
    [Column(TypeName = "decimal(10,2)")]
    public decimal WaitingTimeMinutes { get; set; } = 0;
    
    // Whether this uses per-unit or per-weight calculation
    [MaxLength(20)]
    public string CalculationMethod { get; set; } = "PerUnit"; // PerUnit, PerWeight, Fixed
    
    // Labor requirements
    public int RequiredOperators { get; set; } = 1;
    
    [MaxLength(100)]
    public string? RequiredSkillLevel { get; set; } // Basic, Intermediate, Advanced, Expert
    
    // Quality control
    public bool RequiresInspection { get; set; } = false;
    
    [Column(TypeName = "decimal(5,2)")]
    public decimal InspectionPercentage { get; set; } = 0; // Percentage of items to inspect (0-100)
    
    // Dependencies
    public int? PreviousOperationId { get; set; }
    public virtual RoutingOperation? PreviousOperation { get; set; }
    
    public bool CanRunInParallel { get; set; } = false; // Can run simultaneously with previous operation
    
    // Cost factors
    [Column(TypeName = "decimal(10,2)")]
    public decimal? OverrideHourlyRate { get; set; } // Override WorkCenter hourly rate if needed
    
    [Column(TypeName = "decimal(10,2)")]
    public decimal MaterialCostPerUnit { get; set; } = 0; // Additional material cost for this operation
    
    [Column(TypeName = "decimal(10,2)")]
    public decimal ToolingCost { get; set; } = 0; // Tooling/consumables cost
    
    // Efficiency factors
    [Column(TypeName = "decimal(5,2)")]
    public decimal EfficiencyFactor { get; set; } = 100; // Operation-specific efficiency (100 = normal)
    
    [Column(TypeName = "decimal(5,2)")]
    public decimal ScrapPercentage { get; set; } = 0; // Expected scrap rate
    
    // Instructions and notes
    [MaxLength(2000)]
    public string? WorkInstructions { get; set; }
    
    [MaxLength(1000)]
    public string? SafetyNotes { get; set; }
    
    [MaxLength(500)]
    public string? QualityNotes { get; set; }
    
    // Status
    public bool IsActive { get; set; } = true;
    public bool IsOptional { get; set; } = false; // Can be skipped based on product requirements
    public bool IsCriticalPath { get; set; } = false; // Part of critical path in production
    
    // Audit fields
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public int? CreatedByUserId { get; set; }
    public virtual User? CreatedByUser { get; set; }
    
    public DateTime LastModified { get; set; } = DateTime.UtcNow;
    public int? LastModifiedByUserId { get; set; }
    public virtual User? LastModifiedByUser { get; set; }
    
    // Navigation properties
    public virtual ICollection<RoutingOperation> NextOperations { get; set; } = new List<RoutingOperation>();
    public virtual ICollection<ProcessingItem> ProcessingItems { get; set; } = new List<ProcessingItem>();
    
    // Computed properties
    [NotMapped]
    public decimal EstimatedTimePerUnit
    {
        get
        {
            if (CalculationMethod == "PerUnit")
                return ProcessingTimePerUnit + (SetupTimeMinutes / 100); // Amortize setup over 100 units
            else if (CalculationMethod == "Fixed")
                return SetupTimeMinutes + MovementTimeMinutes + WaitingTimeMinutes;
            else
                return 0; // Weight-based calculated separately
        }
    }
    
    [NotMapped]
    public decimal HourlyRate => OverrideHourlyRate ?? WorkCenter?.HourlyRate ?? 0;
}