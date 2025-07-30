namespace SteelEstimation.Core.Configuration;

public class BundleSettings
{
    public int DefaultMaxBundleWeight { get; set; } = 3000;
    public int BeamsMaxWeight { get; set; } = 3000;
    public int PlatesMaxWeight { get; set; } = 3000;
    public int PurlinsMaxWeight { get; set; } = 2000;
    public int MiscMaxWeight { get; set; } = 2000;
}