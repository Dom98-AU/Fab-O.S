namespace SteelEstimation.Core.Configuration;

public class MaterialMappingSettings
{
    // MBE ID to Type mappings (e.g., "PL" -> "Plate", "B" -> "Beam")
    public Dictionary<string, string> MbeIdMappings { get; set; } = new();
    
    // Material ID pattern mappings (for full material descriptions)
    public MaterialIdPatterns MaterialIdPatterns { get; set; } = new();
    
    public string GetMaterialTypeFromMbeId(string? mbeId)
    {
        if (string.IsNullOrEmpty(mbeId))
            return "Misc";
            
        var upper = mbeId.ToUpper().Trim();
        
        // Check MBE ID mappings
        if (MbeIdMappings.TryGetValue(upper, out var type))
            return type;
            
        return "Misc";
    }
    
    public string GetMaterialTypeFromMaterialId(string? materialId)
    {
        if (string.IsNullOrEmpty(materialId))
            return "Misc";
            
        var upper = materialId.ToUpper();
        
        // Check patterns
        if (MaterialIdPatterns.BeamPatterns.Any(pattern => upper.Contains(pattern)))
            return "Beam";
            
        if (MaterialIdPatterns.PlatePatterns.Any(pattern => upper.Contains(pattern)))
            return "Plate";
            
        if (MaterialIdPatterns.PurlinPatterns.Any(pattern => upper.Contains(pattern)))
            return "Purlin";
            
        return "Misc";
    }
}

public class MaterialIdPatterns
{
    public List<string> BeamPatterns { get; set; } = new();
    public List<string> PlatePatterns { get; set; } = new();
    public List<string> PurlinPatterns { get; set; } = new();
}