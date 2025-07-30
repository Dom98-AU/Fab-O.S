using SteelEstimation.Core.DTOs;

namespace SteelEstimation.Core.Services;

public interface IDashboardMetricsService
{
    Task<DashboardMetrics> GetHomeDashboardMetricsAsync();
    Task<decimal> GetFabricationTonneRateAsync(bool useEfficiencyRates = false);
    Task<TimeEstimationMetrics> GetTimeEstimationMetricsAsync();
    Task<ProcessingTimeBreakdown> GetProcessingTimeBreakdownAsync();
    Task<WeldingTimeAnalysis> GetWeldingTimeAnalysisAsync();
    Task<MaterialTypeDistribution> GetMaterialTypeDistributionAsync();
    Task<UserProductivityMetrics> GetUserProductivityMetricsAsync();
    Task<List<EstimationSummary>> GetRecentEstimationsAsync(int count = 10);
    Task<TimeCalculationVelocity> GetTimeCalculationVelocityAsync();
    Task<TimeAccuracyAnalysis> GetTimeAccuracyAnalysisAsync();
    Task<List<TimeEfficiencyTrend>> GetTimeEfficiencyTrendsAsync(int days = 30);
    Task<BundleEfficiencyAnalysis> GetBundleEfficiencyAnalysisAsync();
    Task<UserTimePerformance> GetUserTimePerformanceAsync(int userId);
    Task<List<UserTimePerformance>> GetAllUserTimePerformanceAsync();
}

public class DashboardMetrics
{
    public int TotalActiveEstimations { get; set; }
    public decimal TotalEstimatedHours { get; set; }
    public decimal TotalTonnage { get; set; }
    public decimal AverageTimePerTonne { get; set; }
    public decimal FabricationTonneRate { get; set; }
    public decimal AdjustedFabricationTonneRate { get; set; }
    public int CompletedEstimationsThisMonth { get; set; }
    public int ActiveEstimators { get; set; }
    public decimal TotalEstimationValue { get; set; }
}

public class TimeEstimationMetrics
{
    public decimal TotalProcessingHours { get; set; }
    public decimal TotalWeldingHours { get; set; }
    public decimal ProcessingToWeldingRatio { get; set; }
    public decimal AverageEstimationTime { get; set; }
    public int EstimationsCompletedThisWeek { get; set; }
    public int EstimationsCompletedThisMonth { get; set; }
}

public class ProcessingTimeBreakdown
{
    public decimal UnloadTime { get; set; }
    public decimal MarkMeasureCutTime { get; set; }
    public decimal QualityCheckTime { get; set; }
    public decimal MoveToAssemblyTime { get; set; }
    public decimal MoveAfterWeldTime { get; set; }
    public decimal LoadingTime { get; set; }
    public decimal TotalProcessingTime { get; set; }
}

public class WeldingTimeAnalysis
{
    public decimal AssembleFitTackTime { get; set; }
    public decimal WeldTime { get; set; }
    public decimal WeldCheckTime { get; set; }
    public decimal WeldTestTime { get; set; }
    public decimal TotalWeldingTime { get; set; }
    public Dictionary<string, decimal> TimeByConnectionType { get; set; } = new();
    public decimal AverageTimePerConnection { get; set; }
    public decimal TotalWeldLength { get; set; }
    public decimal TimePerMeterWeld { get; set; }
}

public class MaterialTypeDistribution
{
    public int BeamCount { get; set; }
    public int PlateCount { get; set; }
    public int PurlinCount { get; set; }
    public int MiscCount { get; set; }
    public decimal BeamTonnage { get; set; }
    public decimal PlateTonnage { get; set; }
    public decimal PurlinTonnage { get; set; }
    public decimal MiscTonnage { get; set; }
}

public class UserProductivityMetrics
{
    public Dictionary<string, decimal> TimeByUser { get; set; } = new();
    public Dictionary<string, int> EstimationsByUser { get; set; } = new();
    public Dictionary<string, decimal> EfficiencyByUser { get; set; } = new();
    public int TotalActiveUsers { get; set; }
}

public class EstimationSummary
{
    public int Id { get; set; }
    public string ProjectName { get; set; } = "";
    public string JobNumber { get; set; } = "";
    public string CustomerName { get; set; } = "";
    public string Status { get; set; } = "";
    public DateTime LastModified { get; set; }
    public decimal TotalHours { get; set; }
    public decimal TotalTonnage { get; set; }
    public decimal TonneRate { get; set; }
    public int PackageCount { get; set; }
}

public class TimeCalculationVelocity
{
    public decimal AverageTimeToCompleteEstimation { get; set; } // Days
    public decimal AverageTimePerPackage { get; set; } // Hours
    public decimal AverageItemsPerHour { get; set; }
    public decimal AverageProcessingTimePerItem { get; set; } // Minutes
    public decimal AverageWeldingTimePerItem { get; set; } // Minutes
    public Dictionary<string, decimal> VelocityByUser { get; set; } = new();
    public Dictionary<string, decimal> VelocityByMaterialType { get; set; } = new();
    public int TotalEstimationsCompleted { get; set; }
    public int TotalPackagesCompleted { get; set; }
}

public class TimeAccuracyAnalysis
{
    public decimal AverageRevisionCount { get; set; }
    public decimal ProcessingTimeVariance { get; set; } // Percentage
    public decimal WeldingTimeVariance { get; set; } // Percentage
    public Dictionary<string, decimal> AccuracyByUser { get; set; } = new();
    public Dictionary<string, decimal> AccuracyByMaterialType { get; set; } = new();
    public List<TimeRevisionPattern> RecentRevisions { get; set; } = new();
    public decimal OverallAccuracyScore { get; set; } // 0-100
    public decimal ImprovementTrend { get; set; } // Percentage change
}

public class TimeRevisionPattern
{
    public DateTime Date { get; set; }
    public string ProjectName { get; set; } = "";
    public string ChangeType { get; set; } = "";
    public decimal OldValue { get; set; }
    public decimal NewValue { get; set; }
    public decimal PercentageChange { get; set; }
    public string UserName { get; set; } = "";
}

public class TimeEfficiencyTrend
{
    public DateTime Date { get; set; }
    public decimal ProcessingHours { get; set; }
    public decimal WeldingHours { get; set; }
    public decimal TotalHours { get; set; }
    public decimal Tonnage { get; set; }
    public decimal HoursPerTonne { get; set; }
    public decimal TonneRate { get; set; }
    public int EstimationsCompleted { get; set; }
    public int ItemsProcessed { get; set; }
}

public class BundleEfficiencyAnalysis
{
    public decimal AverageDeliveryBundleSize { get; set; }
    public decimal AveragePackBundleSize { get; set; }
    public decimal DeliveryBundleTimeSavings { get; set; } // Minutes saved
    public decimal PackBundleTimeSavings { get; set; } // Minutes saved
    public decimal BundleUtilizationRate { get; set; } // Percentage
    public Dictionary<string, decimal> BundleEfficiencyByMaterial { get; set; } = new();
    public List<BundlePerformance> TopPerformingBundles { get; set; } = new();
    public decimal OptimalBundleSize { get; set; }
    public decimal TimeSavingsPercentage { get; set; }
}

public class BundlePerformance
{
    public string BundleName { get; set; } = "";
    public int ItemCount { get; set; }
    public decimal Weight { get; set; }
    public decimal TimeSaved { get; set; }
    public decimal EfficiencyGain { get; set; }
    public string MaterialType { get; set; } = "";
}

public class UserTimePerformance
{
    public int UserId { get; set; }
    public string UserName { get; set; } = "";
    public decimal TotalHoursWorked { get; set; }
    public decimal AverageTimePerEstimation { get; set; }
    public decimal AverageTimePerItem { get; set; }
    public decimal AccuracyScore { get; set; }
    public decimal VelocityScore { get; set; }
    public decimal EfficiencyRating { get; set; }
    public int EstimationsCompleted { get; set; }
    public int ItemsProcessed { get; set; }
    public decimal ProcessingTimeRatio { get; set; }
    public decimal WeldingTimeRatio { get; set; }
    public List<SkillArea> SkillAreas { get; set; } = new();
    public decimal ImprovementTrend { get; set; }
}

public class SkillArea
{
    public string Area { get; set; } = ""; // Processing, Welding, Material Type
    public decimal Score { get; set; }
    public decimal Trend { get; set; }
    public int ItemCount { get; set; }
}