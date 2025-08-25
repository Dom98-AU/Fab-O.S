using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SteelEstimation.Core.Entities;

public class WorkCenterDependency
{
    public int Id { get; set; }
    
    // The WorkCenter that depends on another
    public int DependentWorkCenterId { get; set; }
    public virtual WorkCenter DependentWorkCenter { get; set; } = null!;
    
    // The WorkCenter that must be completed first
    public int RequiredWorkCenterId { get; set; }
    public virtual WorkCenter RequiredWorkCenter { get; set; } = null!;
    
    // Routing context (dependencies can be routing-specific)
    public int? RoutingId { get; set; }
    public virtual RoutingTemplate? Routing { get; set; }
    
    // Dependency type
    [Required]
    [MaxLength(50)]
    public string DependencyType { get; set; } = "Sequential"; // Sequential, Parallel, Conditional
    
    // How the dependency affects the dependent WorkCenter
    [Column(TypeName = "decimal(5,2)")]
    public decimal TimeMultiplier { get; set; } = 1.0m; // Multiplier for time based on previous operation
    
    [Column(TypeName = "decimal(5,2)")]
    public decimal QualityFactor { get; set; } = 1.0m; // Quality impact from previous operation
    
    // Minimum time gap between operations (in minutes)
    [Column(TypeName = "decimal(10,2)")]
    public decimal MinimumGapMinutes { get; set; } = 0;
    
    // Maximum time gap between operations (in minutes, 0 = no limit)
    [Column(TypeName = "decimal(10,2)")]
    public decimal MaximumGapMinutes { get; set; } = 0;
    
    // Conditional logic (JSON string for complex conditions)
    [MaxLength(1000)]
    public string? ConditionExpression { get; set; }
    
    // Whether this dependency is mandatory
    public bool IsMandatory { get; set; } = true;
    
    // Description of the dependency
    [MaxLength(500)]
    public string? Description { get; set; }
    
    // Company relationship for multi-tenant
    public int CompanyId { get; set; }
    public virtual Company Company { get; set; } = null!;
    
    // Status
    public bool IsActive { get; set; } = true;
    
    // Audit fields
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public int? CreatedByUserId { get; set; }
    public virtual User? CreatedByUser { get; set; }
    
    public DateTime LastModified { get; set; } = DateTime.UtcNow;
    public int? LastModifiedByUserId { get; set; }
    public virtual User? LastModifiedByUser { get; set; }
}