using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SteelEstimation.Core.Entities;

public class WorkCenter
{
    public int Id { get; set; }
    
    [Required]
    [MaxLength(50)]
    public string Code { get; set; } = string.Empty;
    
    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    // Company relationship for multi-tenant support
    public int CompanyId { get; set; }
    public virtual Company Company { get; set; } = null!;
    
    // Work center type
    [Required]
    [MaxLength(50)]
    public string WorkCenterType { get; set; } = "Production"; // Production, Assembly, QC, Packaging, etc.
    
    // Capacity and scheduling
    public decimal DailyCapacityHours { get; set; } = 8;
    public int SimultaneousOperations { get; set; } = 1;
    
    // Cost rates
    [Column(TypeName = "decimal(10,2)")]
    public decimal HourlyRate { get; set; }
    
    [Column(TypeName = "decimal(10,2)")]
    public decimal OverheadRate { get; set; }
    
    // Efficiency
    [Column(TypeName = "decimal(5,2)")]
    public decimal EfficiencyPercentage { get; set; } = 100;
    
    // Location
    [MaxLength(100)]
    public string? Department { get; set; }
    
    [MaxLength(100)]
    public string? Building { get; set; }
    
    [MaxLength(50)]
    public string? Floor { get; set; }
    
    // Status
    public bool IsActive { get; set; } = true;
    public bool IsDeleted { get; set; } = false;
    
    // Maintenance
    public DateTime? LastMaintenanceDate { get; set; }
    public DateTime? NextMaintenanceDate { get; set; }
    public int MaintenanceIntervalDays { get; set; } = 90;
    
    // Audit fields
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public int? CreatedByUserId { get; set; }
    public virtual User? CreatedByUser { get; set; }
    
    public DateTime LastModified { get; set; } = DateTime.UtcNow;
    public int? LastModifiedByUserId { get; set; }
    public virtual User? LastModifiedByUser { get; set; }
    
    // Navigation properties
    public virtual ICollection<MachineCenter> MachineCenters { get; set; } = new List<MachineCenter>();
    public virtual ICollection<WorkCenterSkill> RequiredSkills { get; set; } = new List<WorkCenterSkill>();
    public virtual ICollection<WorkCenterShift> Shifts { get; set; } = new List<WorkCenterShift>();
}

public class WorkCenterSkill
{
    public int Id { get; set; }
    
    public int WorkCenterId { get; set; }
    public virtual WorkCenter WorkCenter { get; set; } = null!;
    
    [Required]
    [MaxLength(100)]
    public string SkillName { get; set; } = string.Empty;
    
    [MaxLength(50)]
    public string? SkillLevel { get; set; } = "Basic"; // Basic, Intermediate, Advanced, Expert
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    public bool IsRequired { get; set; } = true;
}

public class WorkCenterShift
{
    public int Id { get; set; }
    
    public int WorkCenterId { get; set; }
    public virtual WorkCenter WorkCenter { get; set; } = null!;
    
    [Required]
    [MaxLength(50)]
    public string ShiftName { get; set; } = string.Empty; // Day, Night, Weekend
    
    public TimeSpan StartTime { get; set; }
    public TimeSpan EndTime { get; set; }
    
    public int BreakDurationMinutes { get; set; } = 0; // Break time in minutes
    
    [MaxLength(20)]
    public string DaysOfWeek { get; set; } = "Mon-Fri"; // Mon-Fri, Sat-Sun, etc.
    
    [Column(TypeName = "decimal(5,2)")]
    public decimal EfficiencyMultiplier { get; set; } = 1.0m; // Efficiency multiplier for this shift
    
    public bool IsActive { get; set; } = true;
}