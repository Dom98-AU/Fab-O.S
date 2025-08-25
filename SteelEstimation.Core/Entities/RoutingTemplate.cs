using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SteelEstimation.Core.Entities;

public class RoutingTemplate
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
    
    // Template type
    [Required]
    [MaxLength(50)]
    public string TemplateType { get; set; } = "Standard"; // Standard, Custom, Express, Complex
    
    // Product category this template applies to
    [MaxLength(100)]
    public string? ProductCategory { get; set; } // Steel Beams, Plates, Pipes, etc.
    
    // Material type this template is optimized for
    [MaxLength(100)]
    public string? MaterialType { get; set; } // Carbon Steel, Stainless Steel, Aluminum, etc.
    
    // Complexity level
    [MaxLength(20)]
    public string ComplexityLevel { get; set; } = "Medium"; // Simple, Medium, Complex
    
    // Estimated total hours (sum of all operations)
    [Column(TypeName = "decimal(10,2)")]
    public decimal EstimatedTotalHours { get; set; } = 0;
    
    // Default efficiency percentage for this template
    [Column(TypeName = "decimal(5,2)")]
    public decimal DefaultEfficiencyPercentage { get; set; } = 100;
    
    // Whether this template includes welding operations
    public bool IncludesWelding { get; set; } = false;
    
    // Whether this template includes quality control
    public bool IncludesQualityControl { get; set; } = true;
    
    // Version control
    [MaxLength(20)]
    public string Version { get; set; } = "1.0";
    
    // Status
    public bool IsActive { get; set; } = true;
    public bool IsDefault { get; set; } = false; // Default template for the company
    public bool IsDeleted { get; set; } = false;
    
    // Usage tracking
    public int UsageCount { get; set; } = 0;
    public DateTime? LastUsedDate { get; set; }
    
    // Approval status
    [MaxLength(50)]
    public string ApprovalStatus { get; set; } = "Draft"; // Draft, Pending, Approved, Rejected
    public int? ApprovedByUserId { get; set; }
    public virtual User? ApprovedByUser { get; set; }
    public DateTime? ApprovalDate { get; set; }
    
    // Notes and special instructions
    [MaxLength(2000)]
    public string? Notes { get; set; }
    
    // Audit fields
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public int? CreatedByUserId { get; set; }
    public virtual User? CreatedByUser { get; set; }
    
    public DateTime LastModified { get; set; } = DateTime.UtcNow;
    public int? LastModifiedByUserId { get; set; }
    public virtual User? LastModifiedByUser { get; set; }
    
    // Navigation properties
    public virtual ICollection<RoutingOperation> Operations { get; set; } = new List<RoutingOperation>();
    public virtual ICollection<Package> Packages { get; set; } = new List<Package>();
}