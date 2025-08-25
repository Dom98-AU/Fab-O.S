using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SteelEstimation.Core.Entities;

public class MachineCenter
{
    public int Id { get; set; }
    
    [Required]
    [MaxLength(50)]
    public string MachineCode { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(200)]
    public string MachineName { get; set; } = string.Empty;
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    // Work Center relationship
    public int WorkCenterId { get; set; }
    public virtual WorkCenter WorkCenter { get; set; } = null!;
    
    // Company relationship
    public int CompanyId { get; set; }
    public virtual Company Company { get; set; } = null!;
    
    // Machine specifications
    [MaxLength(100)]
    public string? Manufacturer { get; set; }
    
    [MaxLength(100)]
    public string? Model { get; set; }
    
    [MaxLength(50)]
    public string? SerialNumber { get; set; }
    
    public DateTime? PurchaseDate { get; set; }
    
    [Column(TypeName = "decimal(12,2)")]
    public decimal? PurchasePrice { get; set; }
    
    // Machine type and capabilities
    [Required]
    [MaxLength(50)]
    public string MachineType { get; set; } = string.Empty; // CNC, Laser, Press, Welding, etc.
    
    [MaxLength(100)]
    public string? MachineSubType { get; set; } // Specific sub-category
    
    // Capacity
    [Column(TypeName = "decimal(10,2)")]
    public decimal MaxCapacity { get; set; } // In relevant units (tons, pieces/hour, etc.)
    
    [MaxLength(20)]
    public string? CapacityUnit { get; set; } // tons, kg, pieces, etc.
    
    // Operating parameters
    [Column(TypeName = "decimal(10,2)")]
    public decimal SetupTimeMinutes { get; set; } = 0;
    
    [Column(TypeName = "decimal(10,2)")]
    public decimal WarmupTimeMinutes { get; set; } = 0;
    
    [Column(TypeName = "decimal(10,2)")]
    public decimal CooldownTimeMinutes { get; set; } = 0;
    
    // Cost rates
    [Column(TypeName = "decimal(10,2)")]
    public decimal HourlyRate { get; set; }
    
    [Column(TypeName = "decimal(10,2)")]
    public decimal PowerConsumptionKwh { get; set; } = 0;
    
    [Column(TypeName = "decimal(10,2)")]
    public decimal PowerCostPerKwh { get; set; } = 0;
    
    // Efficiency and OEE (Overall Equipment Effectiveness)
    [Column(TypeName = "decimal(5,2)")]
    public decimal EfficiencyPercentage { get; set; } = 85;
    
    [Column(TypeName = "decimal(5,2)")]
    public decimal QualityRate { get; set; } = 95; // % of good parts
    
    [Column(TypeName = "decimal(5,2)")]
    public decimal AvailabilityRate { get; set; } = 90; // % uptime
    
    // Status
    public bool IsActive { get; set; } = true;
    public bool IsDeleted { get; set; } = false;
    
    [MaxLength(50)]
    public string CurrentStatus { get; set; } = "Available"; // Available, InUse, Maintenance, Breakdown
    
    // Maintenance
    public DateTime? LastMaintenanceDate { get; set; }
    public DateTime? NextMaintenanceDate { get; set; }
    public int MaintenanceIntervalHours { get; set; } = 500;
    public int CurrentOperatingHours { get; set; } = 0;
    
    // Tooling
    public bool RequiresTooling { get; set; } = false;
    
    [MaxLength(500)]
    public string? ToolingRequirements { get; set; }
    
    // Audit fields
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public int? CreatedByUserId { get; set; }
    public virtual User? CreatedByUser { get; set; }
    
    public DateTime LastModified { get; set; } = DateTime.UtcNow;
    public int? LastModifiedByUserId { get; set; }
    public virtual User? LastModifiedByUser { get; set; }
    
    // Navigation properties
    public virtual ICollection<MachineCapability> Capabilities { get; set; } = new List<MachineCapability>();
    public virtual ICollection<MachineOperator> Operators { get; set; } = new List<MachineOperator>();
}

public class MachineCapability
{
    public int Id { get; set; }
    
    public int MachineCenterId { get; set; }
    public virtual MachineCenter MachineCenter { get; set; } = null!;
    
    [Required]
    [MaxLength(100)]
    public string CapabilityName { get; set; } = string.Empty;
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    // Capability parameters
    [Column(TypeName = "decimal(10,2)")]
    public decimal? MinValue { get; set; }
    
    [Column(TypeName = "decimal(10,2)")]
    public decimal? MaxValue { get; set; }
    
    [MaxLength(20)]
    public string? Unit { get; set; }
    
    // Material compatibility
    [MaxLength(200)]
    public string? CompatibleMaterials { get; set; } // Steel, Aluminum, etc.
    
    public bool IsActive { get; set; } = true;
}

public class MachineOperator
{
    public int Id { get; set; }
    
    public int MachineCenterId { get; set; }
    public virtual MachineCenter MachineCenter { get; set; } = null!;
    
    public int UserId { get; set; }
    public virtual User User { get; set; } = null!;
    
    [MaxLength(50)]
    public string CertificationLevel { get; set; } = "Operator"; // Operator, Supervisor, Technician
    
    public DateTime? CertificationDate { get; set; }
    public DateTime? CertificationExpiry { get; set; }
    
    public bool IsActive { get; set; } = true;
    public bool IsPrimary { get; set; } = false; // Primary operator for this machine
}