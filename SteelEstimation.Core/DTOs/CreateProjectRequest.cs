using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.DTOs;

public class CreateProjectRequest
{
    [Required, MaxLength(200)]
    public string ProjectName { get; set; } = string.Empty;
    
    [Required, MaxLength(50)]
    public string JobNumber { get; set; } = string.Empty;
    
    [MaxLength(20)]
    public string EstimationStage { get; set; } = "Preliminary";
    
    [Range(0.01, 999.99)]
    public decimal LaborRate { get; set; } = 75.00m;
}