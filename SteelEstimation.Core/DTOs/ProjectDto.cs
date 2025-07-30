namespace SteelEstimation.Core.DTOs;

public class ProjectDto
{
    public int Id { get; set; }
    public string ProjectName { get; set; } = string.Empty;
    public string JobNumber { get; set; } = string.Empty;
    public string EstimationStage { get; set; } = string.Empty;
    public decimal LaborRate { get; set; }
    public DateTime CreatedDate { get; set; }
    public DateTime LastModified { get; set; }
    public string? OwnerName { get; set; }
    public string? LastModifiedByName { get; set; }
    public string UserAccessLevel { get; set; } = string.Empty;
    public int ProcessingItemCount { get; set; }
    public int WeldingItemCount { get; set; }
    public decimal TotalProcessingHours { get; set; }
    public decimal TotalWeldingHours { get; set; }
    public decimal TotalCost { get; set; }
}