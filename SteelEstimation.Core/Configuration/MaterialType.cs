namespace SteelEstimation.Core.Configuration;

public class MaterialType
{
    public int MaxBundleWeight { get; set; }
    public string Color { get; set; } = "secondary";
    public bool ShowInQuickFilter { get; set; } = true;
    public int DisplayOrder { get; set; }
}