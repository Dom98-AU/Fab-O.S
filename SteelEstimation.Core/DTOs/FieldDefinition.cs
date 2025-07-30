namespace SteelEstimation.Core.DTOs;

public class FieldDefinition
{
    public string Name { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public bool IsRequired { get; set; }
    public bool IsCalculated { get; set; }
    public bool HasDependencies { get; set; }
    public List<string> Dependencies { get; set; } = new();
    public string? CalculationFormula { get; set; }
}