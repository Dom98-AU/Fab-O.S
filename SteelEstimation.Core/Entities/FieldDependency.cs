using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities;

public class FieldDependency
{
    public int Id { get; set; }
    
    [Required, MaxLength(50)]
    public string BaseType { get; set; } = string.Empty; // Processing or Welding
    
    [Required, MaxLength(100)]
    public string FieldName { get; set; } = string.Empty;
    
    [Required, MaxLength(100)]
    public string DependsOnField { get; set; } = string.Empty;
    
    [Required, MaxLength(50)]
    public string DependencyType { get; set; } = string.Empty; // Required or Calculated
    
    [MaxLength(500)]
    public string? CalculationRule { get; set; }
}