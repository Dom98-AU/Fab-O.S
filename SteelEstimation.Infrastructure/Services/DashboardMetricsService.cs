using Microsoft.EntityFrameworkCore;
using SteelEstimation.Core.DTOs;
using SteelEstimation.Core.Services;
using SteelEstimation.Core.Entities;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services;

public class DashboardMetricsService : IDashboardMetricsService
{
    private readonly IDbContextFactory<ApplicationDbContext> _dbContextFactory;
    private readonly ITimeTrackingService _timeTrackingService;

    public DashboardMetricsService(
        IDbContextFactory<ApplicationDbContext> dbContextFactory,
        ITimeTrackingService timeTrackingService)
    {
        _dbContextFactory = dbContextFactory;
        _timeTrackingService = timeTrackingService;
    }

    public async Task<DashboardMetrics> GetHomeDashboardMetricsAsync()
    {
        using var context = await _dbContextFactory.CreateDbContextAsync();

        var estimations = await context.Projects
            .Include(p => p.Packages)
            .ThenInclude(pkg => pkg.Worksheets)
            .ThenInclude(ws => ws.ProcessingItems)
            .Include(p => p.Packages)
            .ThenInclude(pkg => pkg.Worksheets)
            .ThenInclude(ws => ws.WeldingItems)
            .Where(p => !p.IsDeleted)
            .ToListAsync();

        var metrics = new DashboardMetrics();

        // Calculate basic metrics
        metrics.TotalActiveEstimations = estimations.Count;
        
        decimal totalProcessingHours = 0;
        decimal totalWeldingHours = 0;
        decimal totalTonnage = 0;
        decimal totalLaborCost = 0;
        decimal totalAdjustedLaborCost = 0;

        foreach (var estimation in estimations)
        {
            foreach (var package in estimation.Packages.Where(p => !p.IsDeleted))
            {
                // Calculate processing time
                var processingMinutes = package.Worksheets.SelectMany(ws => ws.ProcessingItems).Sum(p => p.TotalProcessingMinutes);
                var processingHours = processingMinutes / 60m;
                
                // Calculate welding time
                var weldingMinutes = package.Worksheets.SelectMany(ws => ws.WeldingItems).Sum(w => w.TotalWeldingMinutes);
                var weldingHours = weldingMinutes / 60m;
                
                totalProcessingHours += processingHours;
                totalWeldingHours += weldingHours;
                
                // Calculate tonnage (including welding items)
                var processingTonnage = package.Worksheets.SelectMany(ws => ws.ProcessingItems).Sum(p => p.TotalWeight) / 1000m;
                var weldingTonnage = package.Worksheets.SelectMany(ws => ws.WeldingItems).Sum(w => w.Weight) / 1000m;
                totalTonnage += processingTonnage + weldingTonnage;
                
                // Calculate labor costs
                var packageLaborCost = (processingHours + weldingHours) * package.LaborRatePerHour;
                totalLaborCost += packageLaborCost;
                
                // Calculate adjusted labor cost with efficiency
                var adjustedProcessingHours = processingHours;
                var adjustedWeldingHours = weldingHours;
                
                if (package.ProcessingEfficiency.HasValue)
                {
                    var efficiency = package.ProcessingEfficiency.Value / 100m;
                    adjustedProcessingHours *= efficiency;
                    adjustedWeldingHours *= efficiency;
                }
                
                var adjustedPackageLaborCost = (adjustedProcessingHours + adjustedWeldingHours) * package.LaborRatePerHour;
                totalAdjustedLaborCost += adjustedPackageLaborCost;
            }
        }

        metrics.TotalEstimatedHours = totalProcessingHours + totalWeldingHours;
        metrics.TotalTonnage = totalTonnage;
        metrics.AverageTimePerTonne = totalTonnage > 0 ? metrics.TotalEstimatedHours / totalTonnage : 0;
        metrics.FabricationTonneRate = totalTonnage > 0 ? totalLaborCost / totalTonnage : 0;
        metrics.AdjustedFabricationTonneRate = totalTonnage > 0 ? totalAdjustedLaborCost / totalTonnage : 0;
        metrics.TotalEstimationValue = totalLaborCost;

        // Calculate completed estimations this month
        var thisMonth = DateTime.Now.Month;
        var thisYear = DateTime.Now.Year;
        metrics.CompletedEstimationsThisMonth = estimations.Count(e => 
            e.LastModified.Month == thisMonth && e.LastModified.Year == thisYear);

        // Calculate active estimators (users who have worked on estimations recently)
        var recentActivity = await context.EstimationTimeLogs
            .Where(log => log.StartTime >= DateTime.Now.AddDays(-30))
            .Select(log => log.UserId)
            .Distinct()
            .CountAsync();
        
        metrics.ActiveEstimators = recentActivity;

        return metrics;
    }

    public async Task<decimal> GetFabricationTonneRateAsync(bool useEfficiencyRates = false)
    {
        using var context = await _dbContextFactory.CreateDbContextAsync();

        decimal totalLaborCost = 0;
        decimal totalTonnage = 0;

        var estimations = await context.Projects
            .Include(p => p.Packages)
            .ThenInclude(pkg => pkg.Worksheets)
            .ThenInclude(ws => ws.ProcessingItems)
            .Include(p => p.Packages)
            .ThenInclude(pkg => pkg.Worksheets)
            .ThenInclude(ws => ws.WeldingItems)
            .Where(p => !p.IsDeleted)
            .ToListAsync();

        foreach (var estimation in estimations)
        {
            foreach (var package in estimation.Packages.Where(p => !p.IsDeleted))
            {
                // Calculate processing time and cost
                var processingMinutes = package.Worksheets.SelectMany(ws => ws.ProcessingItems).Sum(p => p.TotalProcessingMinutes);
                var processingHours = processingMinutes / 60m;

                // Calculate welding time and cost
                var weldingMinutes = package.Worksheets.SelectMany(ws => ws.WeldingItems).Sum(w => w.TotalWeldingMinutes);
                var weldingHours = weldingMinutes / 60m;

                // Apply efficiency rates if requested
                if (useEfficiencyRates && package.ProcessingEfficiency.HasValue)
                {
                    var efficiency = package.ProcessingEfficiency.Value / 100m;
                    processingHours *= efficiency;
                    weldingHours *= efficiency;
                }

                // Calculate total labor cost for this package
                var packageLaborCost = (processingHours + weldingHours) * package.LaborRatePerHour;
                totalLaborCost += packageLaborCost;

                // Calculate total tonnage for this package
                var processingTonnage = package.Worksheets.SelectMany(ws => ws.ProcessingItems).Sum(p => p.TotalWeight) / 1000m;
                var weldingTonnage = package.Worksheets.SelectMany(ws => ws.WeldingItems).Sum(w => w.Weight) / 1000m;
                totalTonnage += processingTonnage + weldingTonnage;
            }
        }

        return totalTonnage > 0 ? totalLaborCost / totalTonnage : 0;
    }

    public async Task<TimeEstimationMetrics> GetTimeEstimationMetricsAsync()
    {
        using var context = await _dbContextFactory.CreateDbContextAsync();

        var estimations = await context.Projects
            .Include(p => p.Packages)
            .ThenInclude(pkg => pkg.Worksheets)
            .ThenInclude(ws => ws.ProcessingItems)
            .Include(p => p.Packages)
            .ThenInclude(pkg => pkg.Worksheets)
            .ThenInclude(ws => ws.WeldingItems)
            .Where(p => !p.IsDeleted)
            .ToListAsync();

        var metrics = new TimeEstimationMetrics();

        decimal totalProcessingHours = 0;
        decimal totalWeldingHours = 0;

        foreach (var estimation in estimations)
        {
            foreach (var package in estimation.Packages.Where(p => !p.IsDeleted))
            {
                totalProcessingHours += package.Worksheets.SelectMany(ws => ws.ProcessingItems).Sum(p => p.TotalProcessingMinutes) / 60m;
                totalWeldingHours += package.Worksheets.SelectMany(ws => ws.WeldingItems).Sum(w => w.TotalWeldingMinutes) / 60m;
            }
        }

        metrics.TotalProcessingHours = totalProcessingHours;
        metrics.TotalWeldingHours = totalWeldingHours;
        metrics.ProcessingToWeldingRatio = totalWeldingHours > 0 ? totalProcessingHours / totalWeldingHours : 0;
        metrics.AverageEstimationTime = estimations.Count > 0 ? (totalProcessingHours + totalWeldingHours) / estimations.Count : 0;

        // Calculate completed estimations this week and month
        var thisWeek = DateTime.Now.AddDays(-7);
        var thisMonth = DateTime.Now.AddDays(-30);
        
        metrics.EstimationsCompletedThisWeek = estimations.Count(e => e.LastModified >= thisWeek);
        metrics.EstimationsCompletedThisMonth = estimations.Count(e => e.LastModified >= thisMonth);

        return metrics;
    }

    public async Task<ProcessingTimeBreakdown> GetProcessingTimeBreakdownAsync()
    {
        using var context = await _dbContextFactory.CreateDbContextAsync();

        var processingItems = await context.ProcessingItems
            .Include(p => p.PackageWorksheet)
            .ThenInclude(pw => pw.Package)
            .Where(p => !p.IsDeleted && p.PackageWorksheet != null && p.PackageWorksheet.Package != null && !p.PackageWorksheet.Package.IsDeleted)
            .ToListAsync();

        var breakdown = new ProcessingTimeBreakdown();

        foreach (var item in processingItems)
        {
            var quantity = item.Quantity;
            var deliveryBundles = item.DeliveryBundles;
            var packBundles = item.PackBundles;

            // Calculate time contributions based on bundle logic
            breakdown.UnloadTime += (item.DeliveryBundleId == null || item.IsParentInBundle) ? 
                item.UnloadTimePerBundle * deliveryBundles : 0;
            
            breakdown.MarkMeasureCutTime += item.MarkMeasureCut * quantity;
            breakdown.QualityCheckTime += item.QualityCheckClean * quantity;
            
            breakdown.MoveToAssemblyTime += (item.PackBundleId == null || item.IsParentInPackBundle) ? 
                item.MoveToAssembly * packBundles : 0;
            
            breakdown.MoveAfterWeldTime += (item.PackBundleId == null || item.IsParentInPackBundle) ? 
                item.MoveAfterWeld * packBundles : 0;
            
            breakdown.LoadingTime += (item.DeliveryBundleId == null || item.IsParentInBundle) ? 
                item.LoadingTimePerBundle * deliveryBundles : 0;
        }

        breakdown.TotalProcessingTime = breakdown.UnloadTime + breakdown.MarkMeasureCutTime + 
            breakdown.QualityCheckTime + breakdown.MoveToAssemblyTime + 
            breakdown.MoveAfterWeldTime + breakdown.LoadingTime;

        return breakdown;
    }

    public async Task<WeldingTimeAnalysis> GetWeldingTimeAnalysisAsync()
    {
        using var context = await _dbContextFactory.CreateDbContextAsync();

        var weldingItems = await context.WeldingItems
            .Include(w => w.ItemConnections)
            .ThenInclude(ic => ic.WeldingConnection)
            .Include(w => w.PackageWorksheet)
            .ThenInclude(pw => pw.Package)
            .Where(w => !w.IsDeleted && w.PackageWorksheet != null && w.PackageWorksheet.Package != null && !w.PackageWorksheet.Package.IsDeleted)
            .ToListAsync();

        var analysis = new WeldingTimeAnalysis();

        foreach (var item in weldingItems)
        {
            if (item.ItemConnections != null && item.ItemConnections.Any())
            {
                foreach (var connection in item.ItemConnections)
                {
                    analysis.AssembleFitTackTime += (connection.AssembleFitTack ?? 0) * connection.Quantity;
                    analysis.WeldTime += (connection.Weld ?? 0) * connection.Quantity;
                    analysis.WeldCheckTime += (connection.WeldCheck ?? 0) * connection.Quantity;
                    analysis.WeldTestTime += (connection.WeldTest ?? 0) * connection.Quantity;

                    // Track time by connection type
                    if (connection.WeldingConnection != null)
                    {
                        var connectionType = connection.WeldingConnection.Name ?? "Unknown";
                        if (!analysis.TimeByConnectionType.ContainsKey(connectionType))
                            analysis.TimeByConnectionType[connectionType] = 0;
                        
                        analysis.TimeByConnectionType[connectionType] += connection.TotalMinutes;
                    }
                }
            }

            analysis.TotalWeldLength += item.WeldLength;
        }

        analysis.TotalWeldingTime = analysis.AssembleFitTackTime + analysis.WeldTime + 
            analysis.WeldCheckTime + analysis.WeldTestTime;

        var totalConnections = weldingItems.SelectMany(w => w.ItemConnections ?? new List<WeldingItemConnection>()).Count();
        analysis.AverageTimePerConnection = totalConnections > 0 ? analysis.TotalWeldingTime / totalConnections : 0;
        analysis.TimePerMeterWeld = analysis.TotalWeldLength > 0 ? analysis.TotalWeldingTime / analysis.TotalWeldLength : 0;

        return analysis;
    }

    public async Task<MaterialTypeDistribution> GetMaterialTypeDistributionAsync()
    {
        using var context = await _dbContextFactory.CreateDbContextAsync();

        var processingItems = await context.ProcessingItems
            .Include(p => p.PackageWorksheet)
            .ThenInclude(pw => pw.Package)
            .Where(p => !p.IsDeleted && p.PackageWorksheet != null && p.PackageWorksheet.Package != null && !p.PackageWorksheet.Package.IsDeleted)
            .ToListAsync();

        var distribution = new MaterialTypeDistribution();

        foreach (var item in processingItems)
        {
            var materialId = item.MaterialId?.ToUpper() ?? "";
            var weight = item.TotalWeight / 1000m; // Convert to tonnes

            if (IsBeam(materialId))
            {
                distribution.BeamCount += item.Quantity;
                distribution.BeamTonnage += weight;
            }
            else if (IsPlate(materialId))
            {
                distribution.PlateCount += item.Quantity;
                distribution.PlateTonnage += weight;
            }
            else if (IsPurlin(materialId))
            {
                distribution.PurlinCount += item.Quantity;
                distribution.PurlinTonnage += weight;
            }
            else
            {
                distribution.MiscCount += item.Quantity;
                distribution.MiscTonnage += weight;
            }
        }

        return distribution;
    }

    public async Task<UserProductivityMetrics> GetUserProductivityMetricsAsync()
    {
        using var context = await _dbContextFactory.CreateDbContextAsync();

        var metrics = new UserProductivityMetrics();

        // Get time by user from time tracking
        var timeLogs = await context.EstimationTimeLogs
            .Include(log => log.User)
            .Where(log => log.StartTime >= DateTime.Now.AddDays(-30))
            .GroupBy(log => log.UserId)
            .Select(g => new { 
                UserId = g.Key, 
                TotalMinutes = g.Sum(log => log.Duration),
                UserName = g.First().User.Username ?? "Unknown"
            })
            .ToListAsync();

        foreach (var timeLog in timeLogs)
        {
            metrics.TimeByUser[timeLog.UserName] = timeLog.TotalMinutes / 60m; // Convert to hours
        }

        // Get estimations by user (based on last modified)
        var estimationsByUser = await context.Projects
            .Include(p => p.LastModifiedByUser)
            .Where(p => !p.IsDeleted && p.LastModified >= DateTime.Now.AddDays(-30))
            .GroupBy(p => p.LastModifiedBy)
            .Select(g => new { 
                UserId = g.Key, 
                Count = g.Count(),
                UserName = g.First().LastModifiedByUser != null ? g.First().LastModifiedByUser.Username : "Unknown"
            })
            .ToListAsync();

        foreach (var userEst in estimationsByUser)
        {
            if (userEst.UserId.HasValue)
            {
                metrics.EstimationsByUser[userEst.UserName] = userEst.Count;
            }
        }

        metrics.TotalActiveUsers = metrics.TimeByUser.Count;

        return metrics;
    }

    public async Task<List<EstimationSummary>> GetRecentEstimationsAsync(int count = 10)
    {
        using var context = await _dbContextFactory.CreateDbContextAsync();

        var estimations = await context.Projects
            .Include(p => p.Packages)
            .ThenInclude(pkg => pkg.Worksheets)
            .ThenInclude(ws => ws.ProcessingItems)
            .Include(p => p.Packages)
            .ThenInclude(pkg => pkg.Worksheets)
            .ThenInclude(ws => ws.WeldingItems)
            .Include(p => p.Customer)
            .Where(p => !p.IsDeleted)
            .OrderByDescending(p => p.LastModified)
            .Take(count)
            .ToListAsync();

        return estimations.Select(e => new EstimationSummary
        {
            Id = e.Id,
            ProjectName = e.ProjectName ?? "",
            JobNumber = e.JobNumber ?? "",
            CustomerName = e.Customer?.CompanyName ?? "",
            Status = e.EstimationStage ?? "",
            LastModified = e.LastModified,
            PackageCount = e.Packages.Count(p => !p.IsDeleted),
            TotalHours = e.Packages.Where(p => !p.IsDeleted).Sum(p => 
                (p.Worksheets.SelectMany(ws => ws.ProcessingItems).Sum(pi => pi.TotalProcessingMinutes) + 
                 p.Worksheets.SelectMany(ws => ws.WeldingItems).Sum(wi => wi.TotalWeldingMinutes)) / 60m),
            TotalTonnage = e.Packages.Where(p => !p.IsDeleted).Sum(p => 
                (p.Worksheets.SelectMany(ws => ws.ProcessingItems).Sum(pi => pi.TotalWeight) + 
                 0m) / 1000m), // p.Worksheets.SelectMany(ws => ws.WeldingItems).Sum(wi => wi.Weight)) / 1000m),
            TonneRate = CalculateTonneRate(e)
        }).ToList();
    }

    private decimal CalculateTonneRate(Project estimation)
    {
        decimal totalCost = 0;
        decimal totalTonnage = 0;

        foreach (var package in estimation.Packages.Where(p => !p.IsDeleted))
        {
            var processingHours = package.Worksheets.SelectMany(ws => ws.ProcessingItems).Sum(p => p.TotalProcessingMinutes) / 60m;
            var weldingHours = package.Worksheets.SelectMany(ws => ws.WeldingItems).Sum(w => w.TotalWeldingMinutes) / 60m;
            totalCost += (processingHours + weldingHours) * package.LaborRatePerHour;
            
            totalTonnage += (package.Worksheets.SelectMany(ws => ws.ProcessingItems).Sum(p => p.TotalWeight) + 
                           0m) / 1000m; // package.Worksheets.SelectMany(ws => ws.WeldingItems).Sum(w => w.Weight)) / 1000m;
        }

        return totalTonnage > 0 ? totalCost / totalTonnage : 0;
    }

    private bool IsBeam(string materialId)
    {
        return materialId.Contains("BEAM") || materialId.Contains("UB") || 
               materialId.Contains("UC") || materialId.Contains("PFC") || 
               materialId.Contains("RSJ");
    }

    private bool IsPlate(string materialId)
    {
        return materialId.Contains("PLATE") || materialId.Contains("FL") || 
               materialId.Contains("PL");
    }

    private bool IsPurlin(string materialId)
    {
        return materialId.Contains("PURLIN") || materialId.Contains("C15") || 
               materialId.Contains("C20") || materialId.Contains("C25") || 
               materialId.Contains("Z15") || materialId.Contains("Z20");
    }

    // Time Analytics Methods - Phase 2 Implementation

    public async Task<TimeCalculationVelocity> GetTimeCalculationVelocityAsync()
    {
        using var context = await _dbContextFactory.CreateDbContextAsync();

        var estimations = await context.Projects
            .Include(p => p.Packages)
            .ThenInclude(pkg => pkg.Worksheets)
            .ThenInclude(ws => ws.ProcessingItems)
            .Include(p => p.Packages)
            .ThenInclude(pkg => pkg.Worksheets)
            .ThenInclude(ws => ws.WeldingItems)
            .Include(p => p.LastModifiedByUser)
            .Where(p => !p.IsDeleted)
            .ToListAsync();

        var velocity = new TimeCalculationVelocity();

        if (!estimations.Any())
        {
            return velocity;
        }

        // Calculate average time to complete estimation (creation to last modified)
        var completionTimes = estimations
            .Where(e => e.CreatedDate != default && e.LastModified != default)
            .Select(e => (e.LastModified - e.CreatedDate).TotalDays)
            .ToList();

        velocity.AverageTimeToCompleteEstimation = completionTimes.Any() ? 
            (decimal)completionTimes.Average() : 0;

        // Calculate package and item metrics
        var allPackages = estimations.SelectMany(e => e.Packages.Where(p => !p.IsDeleted)).ToList();
        var allProcessingItems = allPackages.SelectMany(p => p.Worksheets.SelectMany(ws => ws.ProcessingItems)).ToList();
        var allWeldingItems = allPackages.SelectMany(p => p.Worksheets.SelectMany(ws => ws.WeldingItems)).ToList();

        velocity.TotalEstimationsCompleted = estimations.Count;
        velocity.TotalPackagesCompleted = allPackages.Count;

        if (allPackages.Any())
        {
            var totalPackageHours = allPackages.Sum(p => 
                (p.Worksheets.SelectMany(ws => ws.ProcessingItems).Sum(pi => pi.TotalProcessingMinutes) + 
                 p.Worksheets.SelectMany(ws => ws.WeldingItems).Sum(wi => wi.TotalWeldingMinutes)) / 60m);
            
            velocity.AverageTimePerPackage = totalPackageHours / allPackages.Count;
        }

        var totalItems = allProcessingItems.Count + allWeldingItems.Count;
        if (totalItems > 0)
        {
            var totalItemMinutes = allProcessingItems.Sum(p => p.TotalProcessingMinutes) + 
                                 allWeldingItems.Sum(w => w.TotalWeldingMinutes);
            
            velocity.AverageTimePerPackage = velocity.AverageTimePerPackage > 0 ? velocity.AverageTimePerPackage : 
                totalItemMinutes / 60m / allPackages.Count;
            
            velocity.AverageItemsPerHour = velocity.AverageTimePerPackage > 0 ? 
                (totalItems / (decimal)allPackages.Count) / velocity.AverageTimePerPackage : 0;
        }

        // Calculate average processing and welding time per item
        if (allProcessingItems.Any())
        {
            velocity.AverageProcessingTimePerItem = allProcessingItems.Average(p => p.TotalProcessingMinutes);
        }

        if (allWeldingItems.Any())
        {
            velocity.AverageWeldingTimePerItem = allWeldingItems.Average(w => w.TotalWeldingMinutes);
        }

        // Calculate velocity by user
        var userMetrics = estimations
            .Where(e => e.LastModifiedByUser != null)
            .GroupBy(e => e.LastModifiedByUser.Username)
            .ToDictionary(
                g => g.Key ?? "Unknown",
                g => g.Sum(e => e.Packages.Where(p => !p.IsDeleted).Sum(p => 
                    (p.Worksheets.SelectMany(ws => ws.ProcessingItems).Sum(pi => pi.TotalProcessingMinutes) + 
                     p.Worksheets.SelectMany(ws => ws.WeldingItems).Sum(wi => wi.TotalWeldingMinutes)) / 60m)) / g.Count()
            );

        velocity.VelocityByUser = userMetrics;

        // Calculate velocity by material type
        var materialMetrics = allProcessingItems
            .GroupBy(p => GetMaterialType(p.MaterialId))
            .ToDictionary(
                g => g.Key,
                g => g.Average(p => p.TotalProcessingMinutes)
            );

        velocity.VelocityByMaterialType = materialMetrics;

        return velocity;
    }

    public async Task<TimeAccuracyAnalysis> GetTimeAccuracyAnalysisAsync()
    {
        using var context = await _dbContextFactory.CreateDbContextAsync();

        var estimations = await context.Projects
            .Include(p => p.Packages)
            .ThenInclude(pkg => pkg.Worksheets)
            .ThenInclude(ws => ws.ProcessingItems)
            .Include(p => p.Packages)
            .ThenInclude(pkg => pkg.Worksheets)
            .ThenInclude(ws => ws.WeldingItems)
            .Include(p => p.LastModifiedByUser)
            .Where(p => !p.IsDeleted)
            .ToListAsync();

        var analysis = new TimeAccuracyAnalysis();

        if (!estimations.Any())
        {
            return analysis;
        }

        // Calculate average revision count (using creation vs last modified as proxy)
        var revisionCounts = estimations
            .Where(e => e.CreatedDate != default && e.LastModified != default)
            .Select(e => (e.LastModified - e.CreatedDate).TotalDays > 1 ? 1 : 0)
            .ToList();

        analysis.AverageRevisionCount = revisionCounts.Any() ? 
            (decimal)revisionCounts.Average() : 0;

        // Calculate variance in processing and welding times
        var processingTimes = estimations
            .SelectMany(e => e.Packages.Where(p => !p.IsDeleted))
            .Select(p => p.Worksheets.SelectMany(ws => ws.ProcessingItems).Sum(pi => pi.TotalProcessingMinutes) / 60m)
            .Where(t => t > 0)
            .ToList();

        var weldingTimes = estimations
            .SelectMany(e => e.Packages.Where(p => !p.IsDeleted))
            .Select(p => p.Worksheets.SelectMany(ws => ws.WeldingItems).Sum(wi => wi.TotalWeldingMinutes) / 60m)
            .Where(t => t > 0)
            .ToList();

        if (processingTimes.Any())
        {
            var avgProcessing = processingTimes.Average();
            var variance = processingTimes.Sum(t => Math.Pow((double)(t - (decimal)avgProcessing), 2)) / (double)processingTimes.Count;
            analysis.ProcessingTimeVariance = avgProcessing > 0 ? (decimal)(Math.Sqrt(variance) / (double)avgProcessing * 100) : 0;
        }

        if (weldingTimes.Any())
        {
            var avgWelding = weldingTimes.Average();
            var variance = weldingTimes.Sum(t => Math.Pow((double)(t - (decimal)avgWelding), 2)) / (double)weldingTimes.Count;
            analysis.WeldingTimeVariance = avgWelding > 0 ? (decimal)(Math.Sqrt(variance) / (double)avgWelding * 100) : 0;
        }

        // Calculate accuracy by user (inverse of variance)
        var userAccuracy = estimations
            .Where(e => e.LastModifiedByUser != null)
            .GroupBy(e => e.LastModifiedByUser.Username)
            .ToDictionary(
                g => g.Key ?? "Unknown",
                g => {
                    var userTimes = g.SelectMany(e => e.Packages.Where(p => !p.IsDeleted))
                                   .Select(p => (p.Worksheets.SelectMany(ws => ws.ProcessingItems).Sum(pi => pi.TotalProcessingMinutes) + 
                                               p.Worksheets.SelectMany(ws => ws.WeldingItems).Sum(wi => wi.TotalWeldingMinutes)) / 60m)
                                   .Where(t => t > 0).ToList();
                    
                    if (userTimes.Count < 2) return 100m;
                    
                    var avg = userTimes.Average();
                    var variance = userTimes.Sum(t => Math.Pow((double)(t - (decimal)avg), 2)) / (double)userTimes.Count;
                    return avg > 0 ? Math.Max(0m, 100m - (decimal)(Math.Sqrt(variance) / (double)avg * 100)) : 0m;
                }
            );

        analysis.AccuracyByUser = userAccuracy;

        // Calculate accuracy by material type
        var materialAccuracy = estimations
            .SelectMany(e => e.Packages.Where(p => !p.IsDeleted))
            .SelectMany(p => p.Worksheets.SelectMany(ws => ws.ProcessingItems))
            .GroupBy(p => GetMaterialType(p.MaterialId))
            .ToDictionary(
                g => g.Key,
                g => {
                    var materialTimes = g.Select(p => p.TotalProcessingMinutes).Where(t => t > 0).ToList();
                    if (materialTimes.Count < 2) return 100m;
                    
                    var avg = materialTimes.Average();
                    var variance = materialTimes.Sum(t => Math.Pow((double)(t - (decimal)avg), 2)) / (double)materialTimes.Count;
                    return avg > 0 ? Math.Max(0m, 100m - (decimal)(Math.Sqrt(variance) / (double)avg * 100)) : 0m;
                }
            );

        analysis.AccuracyByMaterialType = materialAccuracy;

        // Calculate overall accuracy score
        var allAccuracyScores = userAccuracy.Values.Concat(materialAccuracy.Values).ToList();
        analysis.OverallAccuracyScore = allAccuracyScores.Any() ? allAccuracyScores.Average() : 0;

        // Calculate improvement trend (simplified - based on recent vs older estimations)
        var recentEstimations = estimations.Where(e => e.LastModified >= DateTime.Now.AddDays(-30)).ToList();
        var olderEstimations = estimations.Where(e => e.LastModified < DateTime.Now.AddDays(-30)).ToList();

        if (recentEstimations.Any() && olderEstimations.Any())
        {
            var recentVariance = CalculateTimeVariance(recentEstimations);
            var olderVariance = CalculateTimeVariance(olderEstimations);
            
            if (olderVariance > 0)
            {
                analysis.ImprovementTrend = ((olderVariance - recentVariance) / olderVariance) * 100;
            }
        }

        return analysis;
    }

    public async Task<List<TimeEfficiencyTrend>> GetTimeEfficiencyTrendsAsync(int days = 30)
    {
        using var context = await _dbContextFactory.CreateDbContextAsync();

        var startDate = DateTime.Now.AddDays(-days);
        var estimations = await context.Projects
            .Include(p => p.Packages)
            .ThenInclude(pkg => pkg.Worksheets)
            .ThenInclude(ws => ws.ProcessingItems)
            .Include(p => p.Packages)
            .ThenInclude(pkg => pkg.Worksheets)
            .ThenInclude(ws => ws.WeldingItems)
            .Where(p => !p.IsDeleted && p.LastModified >= startDate)
            .ToListAsync();

        var trends = new List<TimeEfficiencyTrend>();

        // Group by day and calculate metrics
        var dailyMetrics = estimations
            .GroupBy(e => e.LastModified.Date)
            .OrderBy(g => g.Key)
            .Select(g => new TimeEfficiencyTrend
            {
                Date = g.Key,
                EstimationsCompleted = g.Count(),
                ProcessingHours = g.SelectMany(e => e.Packages.Where(p => !p.IsDeleted))
                                   .Sum(p => p.Worksheets.SelectMany(ws => ws.ProcessingItems).Sum(pi => pi.TotalProcessingMinutes)) / 60m,
                WeldingHours = g.SelectMany(e => e.Packages.Where(p => !p.IsDeleted))
                              .Sum(p => p.Worksheets.SelectMany(ws => ws.WeldingItems).Sum(wi => wi.TotalWeldingMinutes)) / 60m,
                Tonnage = g.SelectMany(e => e.Packages.Where(p => !p.IsDeleted))
                          .Sum(p => (p.Worksheets.SelectMany(ws => ws.ProcessingItems).Sum(pi => pi.TotalWeight) + 
                                   0m) / 1000m), // p.Worksheets.SelectMany(ws => ws.WeldingItems).Sum(wi => wi.Weight)) / 1000m),
                ItemsProcessed = g.SelectMany(e => e.Packages.Where(p => !p.IsDeleted))
                                .Sum(p => p.Worksheets.SelectMany(ws => ws.ProcessingItems).Count() + p.Worksheets.SelectMany(ws => ws.WeldingItems).Count())
            })
            .ToList();

        // Calculate derived metrics
        foreach (var trend in dailyMetrics)
        {
            trend.TotalHours = trend.ProcessingHours + trend.WeldingHours;
            trend.HoursPerTonne = trend.Tonnage > 0 ? trend.TotalHours / trend.Tonnage : 0;
            
            // Calculate tonne rate (assuming $50/hour average)
            var averageHourlyRate = 50m;
            trend.TonneRate = trend.Tonnage > 0 ? (trend.TotalHours * averageHourlyRate) / trend.Tonnage : 0;
        }

        return dailyMetrics;
    }

    public async Task<BundleEfficiencyAnalysis> GetBundleEfficiencyAnalysisAsync()
    {
        using var context = await _dbContextFactory.CreateDbContextAsync();

        var processingItems = await context.ProcessingItems
            .Include(p => p.PackageWorksheet)
            .ThenInclude(pw => pw.Package)
            .Where(p => !p.IsDeleted && p.PackageWorksheet != null && p.PackageWorksheet.Package != null && !p.PackageWorksheet.Package.IsDeleted)
            .ToListAsync();

        var analysis = new BundleEfficiencyAnalysis();

        if (!processingItems.Any())
        {
            return analysis;
        }

        // Calculate delivery bundle metrics
        var deliveryBundledItems = processingItems.Where(p => p.DeliveryBundleId != null).ToList();
        var nonDeliveryBundledItems = processingItems.Where(p => p.DeliveryBundleId == null).ToList();

        if (deliveryBundledItems.Any())
        {
            analysis.AverageDeliveryBundleSize = (decimal)deliveryBundledItems.GroupBy(p => p.DeliveryBundleId)
                                                                    .Average(g => g.Count());
            
            // Calculate time savings from delivery bundling
            var bundledTime = deliveryBundledItems.Sum(p => p.IsParentInBundle ? p.UnloadTimePerBundle * p.DeliveryBundles : 0);
            var unbundledTime = deliveryBundledItems.Sum(p => p.UnloadTimePerBundle * p.Quantity);
            analysis.DeliveryBundleTimeSavings = unbundledTime - bundledTime;
        }

        // Calculate pack bundle metrics
        var packBundledItems = processingItems.Where(p => p.PackBundleId != null).ToList();

        if (packBundledItems.Any())
        {
            analysis.AveragePackBundleSize = (decimal)packBundledItems.GroupBy(p => p.PackBundleId)
                                                            .Average(g => g.Count());
            
            // Calculate time savings from pack bundling
            var bundledTime = packBundledItems.Sum(p => p.IsParentInPackBundle ? 
                (p.MoveToAssembly + p.MoveAfterWeld) * p.PackBundles : 0);
            var unbundledTime = packBundledItems.Sum(p => 
                (p.MoveToAssembly + p.MoveAfterWeld) * p.Quantity);
            analysis.PackBundleTimeSavings = unbundledTime - bundledTime;
        }

        // Calculate bundle utilization rate
        var totalBundledItems = deliveryBundledItems.Count + packBundledItems.Count;
        var totalItems = processingItems.Count;
        analysis.BundleUtilizationRate = totalItems > 0 ? (decimal)totalBundledItems / totalItems * 100 : 0;

        // Calculate efficiency by material type
        var materialEfficiency = processingItems
            .GroupBy(p => GetMaterialType(p.MaterialId))
            .ToDictionary(
                g => g.Key,
                g => {
                    var materialItems = g.ToList();
                    var bundledCount = materialItems.Count(p => p.DeliveryBundleId != null || p.PackBundleId != null);
                    return materialItems.Count > 0 ? (decimal)bundledCount / materialItems.Count * 100 : 0;
                }
            );

        analysis.BundleEfficiencyByMaterial = materialEfficiency;

        // Calculate total time savings percentage
        var totalTimeSavings = analysis.DeliveryBundleTimeSavings + analysis.PackBundleTimeSavings;
        var totalPossibleTime = processingItems.Sum(p => 
            p.UnloadTimePerBundle * p.Quantity + 
            (p.MoveToAssembly + p.MoveAfterWeld) * p.Quantity);
        
        analysis.TimeSavingsPercentage = totalPossibleTime > 0 ? 
            (totalTimeSavings / totalPossibleTime) * 100 : 0;

        // Calculate optimal bundle size (based on efficiency curve)
        var bundleSizes = processingItems
            .Where(p => p.DeliveryBundleId != null || p.PackBundleId != null)
            .GroupBy(p => p.DeliveryBundleId ?? p.PackBundleId)
            .Select(g => g.Count())
            .ToList();

        if (bundleSizes.Any())
        {
            analysis.OptimalBundleSize = bundleSizes.OrderBy(size => Math.Abs(size - bundleSizes.Average()))
                                                   .First();
        }

        return analysis;
    }

    public async Task<UserTimePerformance> GetUserTimePerformanceAsync(int userId)
    {
        using var context = await _dbContextFactory.CreateDbContextAsync();

        var user = await context.Users.FindAsync(userId);
        if (user == null)
        {
            return new UserTimePerformance { UserId = userId, UserName = "Unknown" };
        }

        var performance = new UserTimePerformance
        {
            UserId = userId,
            UserName = user.Username ?? "Unknown"
        };

        // Get user's estimations
        var userEstimations = await context.Projects
            .Include(p => p.Packages)
            .ThenInclude(pkg => pkg.Worksheets)
            .ThenInclude(ws => ws.ProcessingItems)
            .Include(p => p.Packages)
            .ThenInclude(pkg => pkg.Worksheets)
            .ThenInclude(ws => ws.WeldingItems)
            .Where(p => !p.IsDeleted && p.LastModifiedBy == userId)
            .ToListAsync();

        // Get user's time logs
        var timeLogs = await context.EstimationTimeLogs
            .Where(log => log.UserId == userId && log.StartTime >= DateTime.Now.AddDays(-90))
            .ToListAsync();

        if (timeLogs.Any())
        {
            performance.TotalHoursWorked = timeLogs.Sum(log => log.Duration) / 60m;
        }

        if (userEstimations.Any())
        {
            performance.EstimationsCompleted = userEstimations.Count;
            
            var totalHours = userEstimations.SelectMany(e => e.Packages.Where(p => !p.IsDeleted))
                                           .Sum(p => (p.Worksheets.SelectMany(ws => ws.ProcessingItems).Sum(pi => pi.TotalProcessingMinutes) + 
                                                    p.Worksheets.SelectMany(ws => ws.WeldingItems).Sum(wi => wi.TotalWeldingMinutes)) / 60m);
            
            performance.AverageTimePerEstimation = totalHours / userEstimations.Count;
            
            var totalItems = userEstimations.SelectMany(e => e.Packages.Where(p => !p.IsDeleted))
                                           .Sum(p => p.Worksheets.SelectMany(ws => ws.ProcessingItems).Count() + p.Worksheets.SelectMany(ws => ws.WeldingItems).Count());
            
            performance.ItemsProcessed = totalItems;
            performance.AverageTimePerItem = totalItems > 0 ? totalHours / totalItems * 60 : 0; // In minutes

            // Calculate processing vs welding ratio
            var processingHours = userEstimations.SelectMany(e => e.Packages.Where(p => !p.IsDeleted))
                                                .Sum(p => p.Worksheets.SelectMany(ws => ws.ProcessingItems).Sum(pi => pi.TotalProcessingMinutes)) / 60m;
            var weldingHours = userEstimations.SelectMany(e => e.Packages.Where(p => !p.IsDeleted))
                                             .Sum(p => p.Worksheets.SelectMany(ws => ws.WeldingItems).Sum(wi => wi.TotalWeldingMinutes)) / 60m;

            performance.ProcessingTimeRatio = totalHours > 0 ? processingHours / totalHours : 0;
            performance.WeldingTimeRatio = totalHours > 0 ? weldingHours / totalHours : 0;
        }

        // Calculate skill areas
        var skillAreas = new List<SkillArea>();
        
        if (userEstimations.Any())
        {
            var materialGroups = userEstimations
                .SelectMany(e => e.Packages.Where(p => !p.IsDeleted))
                .SelectMany(p => p.Worksheets.SelectMany(ws => ws.ProcessingItems))
                .GroupBy(p => GetMaterialType(p.MaterialId))
                .ToList();

            foreach (var group in materialGroups)
            {
                var items = group.ToList();
                var avgTime = items.Average(p => p.TotalProcessingMinutes);
                var score = (decimal)Math.Min(100, Math.Max(0, 100 - (avgTime / 60))); // Simplified scoring
                
                skillAreas.Add(new SkillArea
                {
                    Area = group.Key,
                    Score = score,
                    ItemCount = items.Count,
                    Trend = 0 // Would need historical data to calculate trend
                });
            }
        }

        performance.SkillAreas = skillAreas;

        // Calculate composite scores (simplified)
        performance.AccuracyScore = CalculateUserAccuracy(userEstimations);
        performance.VelocityScore = CalculateUserVelocity(userEstimations, timeLogs);
        performance.EfficiencyRating = (performance.AccuracyScore + performance.VelocityScore) / 2;

        return performance;
    }

    public async Task<List<UserTimePerformance>> GetAllUserTimePerformanceAsync()
    {
        using var context = await _dbContextFactory.CreateDbContextAsync();

        var users = await context.Users
            .Where(u => true)
            .ToListAsync();

        var performances = new List<UserTimePerformance>();

        foreach (var user in users)
        {
            var performance = await GetUserTimePerformanceAsync(user.Id);
            performances.Add(performance);
        }

        return performances.OrderByDescending(p => p.EfficiencyRating).ToList();
    }

    // Helper methods for Time Analytics

    private string GetMaterialType(string? materialId)
    {
        if (string.IsNullOrEmpty(materialId)) return "Unknown";
        
        var material = materialId.ToUpper();
        if (IsBeam(material)) return "Beam";
        if (IsPlate(material)) return "Plate";
        if (IsPurlin(material)) return "Purlin";
        return "Misc";
    }

    private decimal CalculateTimeVariance(List<Project> estimations)
    {
        var times = estimations
            .SelectMany(e => e.Packages.Where(p => !p.IsDeleted))
            .Select(p => (p.Worksheets.SelectMany(ws => ws.ProcessingItems).Sum(pi => pi.TotalProcessingMinutes) + 
                         p.Worksheets.SelectMany(ws => ws.WeldingItems).Sum(wi => wi.TotalWeldingMinutes)) / 60m)
            .Where(t => t > 0)
            .ToList();

        if (times.Count < 2) return 0;

        var avg = times.Average();
        var variance = times.Sum(t => Math.Pow((double)(t - (decimal)avg), 2)) / times.Count;
        return (decimal)Math.Sqrt(variance);
    }

    private decimal CalculateUserAccuracy(List<Project> userEstimations)
    {
        if (!userEstimations.Any()) return 0;

        var times = userEstimations
            .SelectMany(e => e.Packages.Where(p => !p.IsDeleted))
            .Select(p => (p.Worksheets.SelectMany(ws => ws.ProcessingItems).Sum(pi => pi.TotalProcessingMinutes) + 
                         p.Worksheets.SelectMany(ws => ws.WeldingItems).Sum(wi => wi.TotalWeldingMinutes)) / 60m)
            .Where(t => t > 0)
            .ToList();

        if (times.Count < 2) return 100;

        var avg = times.Average();
        var variance = times.Sum(t => Math.Pow((double)(t - (decimal)avg), 2)) / times.Count;
        var coefficient = avg > 0 ? Math.Sqrt(variance) / (double)avg : 0;
        
        return Math.Max(0m, 100m - (decimal)(coefficient * 100));
    }

    private decimal CalculateUserVelocity(List<Project> userEstimations, List<EstimationTimeLog> timeLogs)
    {
        if (!userEstimations.Any() || !timeLogs.Any()) return 0;

        var totalItems = userEstimations
            .SelectMany(e => e.Packages.Where(p => !p.IsDeleted))
            .Sum(p => p.Worksheets.SelectMany(ws => ws.ProcessingItems).Count() + p.Worksheets.SelectMany(ws => ws.WeldingItems).Count());

        var totalHours = timeLogs.Sum(log => log.Duration) / 60m;
        
        if (totalHours == 0) return 0;

        var itemsPerHour = totalItems / totalHours;
        
        // Scale to 0-100 (assuming 1 item per hour = 50 points)
        return Math.Min(100, itemsPerHour * 50);
    }
}