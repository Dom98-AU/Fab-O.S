using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SteelEstimation.Core.Entities;

public class Project
{
    public int Id { get; set; }
    
    [Required, MaxLength(200)]
    public string ProjectName { get; set; } = string.Empty;
    
    [Required, MaxLength(50)]
    public string JobNumber { get; set; } = string.Empty;
    
    // Customer relationship
    public int? CustomerId { get; set; }
    
    [MaxLength(200)]
    public string? ProjectLocation { get; set; }
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    [MaxLength(20)]
    public string EstimationStage { get; set; } = "Preliminary";
    
    public decimal LaborRate { get; set; } = 75.00m;
    
    public decimal ContingencyPercentage { get; set; } = 10.00m;
    
    public string? Notes { get; set; }
    
    // Time tracking fields
    public decimal? EstimatedHours { get; set; }
    public DateTime? EstimatedCompletionDate { get; set; }
    
    public int? OwnerId { get; set; }
    public int? LastModifiedBy { get; set; }
    
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public DateTime LastModified { get; set; } = DateTime.UtcNow;
    
    [NotMapped]
    public DateTime ModifiedDate 
    { 
        get => LastModified;
        set => LastModified = value;
    }
    
    public bool IsDeleted { get; set; } = false;
    
    // Navigation properties
    public virtual Customer? Customer { get; set; }
    public virtual User? Owner { get; set; }
    public virtual User? LastModifiedByUser { get; set; }
    public virtual ICollection<ProjectUser> ProjectUsers { get; set; } = new List<ProjectUser>();
    public virtual ICollection<Package> Packages { get; set; } = new List<Package>();
    public virtual ICollection<ProcessingItem> ProcessingItems { get; set; } = new List<ProcessingItem>();
    public virtual ICollection<WeldingItem> WeldingItems { get; set; } = new List<WeldingItem>();
}