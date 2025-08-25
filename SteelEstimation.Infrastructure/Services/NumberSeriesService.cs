using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Interfaces;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services;

public class NumberSeriesService : INumberSeriesService
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<NumberSeriesService> _logger;
    private static readonly SemaphoreSlim _semaphore = new(1, 1);

    public NumberSeriesService(ApplicationDbContext context, ILogger<NumberSeriesService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<string> GetNextNumberAsync(int companyId, string entityType)
    {
        await _semaphore.WaitAsync();
        try
        {
            var series = await GetOrCreateNumberSeriesAsync(companyId, entityType);
            
            if (!series.IsActive)
            {
                throw new InvalidOperationException($"Number series for {entityType} is not active");
            }

            // Check for periodic reset
            await CheckAndPerformResetAsync(series);

            // Increment the counter
            series.CurrentNumber += series.IncrementBy;
            series.LastUsed = DateTime.UtcNow;
            
            // Generate the formatted number
            var generatedNumber = series.FormatNumber(series.CurrentNumber);
            
            // Update preview
            series.PreviewExample = series.GetNextNumberPreview();
            
            // Save changes
            await _context.SaveChangesAsync();
            
            _logger.LogInformation($"Generated number {generatedNumber} for {entityType} in company {companyId}");
            
            return generatedNumber;
        }
        finally
        {
            _semaphore.Release();
        }
    }

    public async Task<string> PreviewNextNumberAsync(int companyId, string entityType)
    {
        var series = await GetOrCreateNumberSeriesAsync(companyId, entityType);
        await CheckAndPerformResetAsync(series, preview: true);
        
        var nextNumber = series.CurrentNumber + series.IncrementBy;
        return series.FormatNumber(nextNumber);
    }

    public async Task<NumberSeries?> GetNumberSeriesAsync(int companyId, string entityType)
    {
        return await _context.Set<NumberSeries>()
            .FirstOrDefaultAsync(ns => ns.CompanyId == companyId && ns.EntityType == entityType);
    }

    public async Task<List<NumberSeries>> GetAllNumberSeriesAsync(int companyId)
    {
        return await _context.Set<NumberSeries>()
            .Where(ns => ns.CompanyId == companyId)
            .OrderBy(ns => ns.EntityType)
            .ToListAsync();
    }

    public async Task<NumberSeries> ConfigureNumberSeriesAsync(NumberSeries numberSeries)
    {
        var existing = await GetNumberSeriesAsync(numberSeries.CompanyId, numberSeries.EntityType);
        
        if (existing != null)
        {
            // Update existing
            existing.Prefix = numberSeries.Prefix;
            existing.Suffix = numberSeries.Suffix;
            existing.MinDigits = numberSeries.MinDigits;
            existing.Format = numberSeries.Format;
            existing.IncludeYear = numberSeries.IncludeYear;
            existing.IncludeMonth = numberSeries.IncludeMonth;
            existing.IncludeCompanyCode = numberSeries.IncludeCompanyCode;
            existing.ResetYearly = numberSeries.ResetYearly;
            existing.ResetMonthly = numberSeries.ResetMonthly;
            existing.IsActive = numberSeries.IsActive;
            existing.AllowManualEntry = numberSeries.AllowManualEntry;
            existing.Description = numberSeries.Description;
            existing.LastModified = DateTime.UtcNow;
            existing.LastModifiedByUserId = numberSeries.LastModifiedByUserId;
            existing.PreviewExample = existing.GetNextNumberPreview();
            
            _context.Update(existing);
        }
        else
        {
            // Create new
            numberSeries.CreatedDate = DateTime.UtcNow;
            numberSeries.LastModified = DateTime.UtcNow;
            numberSeries.PreviewExample = numberSeries.GetNextNumberPreview();
            _context.Add(numberSeries);
        }
        
        await _context.SaveChangesAsync();
        return existing ?? numberSeries;
    }

    public async Task<bool> ResetNumberSeriesAsync(int companyId, string entityType, int newStartNumber)
    {
        var series = await GetNumberSeriesAsync(companyId, entityType);
        if (series == null) return false;
        
        series.CurrentNumber = newStartNumber - series.IncrementBy;
        series.StartingNumber = newStartNumber;
        series.LastModified = DateTime.UtcNow;
        series.PreviewExample = series.GetNextNumberPreview();
        
        if (series.ResetYearly)
        {
            series.LastResetYear = DateTime.UtcNow.Year;
        }
        if (series.ResetMonthly)
        {
            series.LastResetMonth = DateTime.UtcNow.Month;
        }
        
        await _context.SaveChangesAsync();
        
        _logger.LogInformation($"Reset number series for {entityType} in company {companyId} to {newStartNumber}");
        return true;
    }

    public async Task<bool> IsAutoNumberingEnabledAsync(int companyId, string entityType)
    {
        var series = await GetNumberSeriesAsync(companyId, entityType);
        return series?.IsActive ?? false;
    }

    public async Task<bool> ValidateManualNumberAsync(int companyId, string entityType, string manualNumber)
    {
        // Check if manual entry is allowed
        var series = await GetNumberSeriesAsync(companyId, entityType);
        if (series == null || !series.AllowManualEntry)
        {
            return false;
        }
        
        // Check uniqueness based on entity type
        bool exists = entityType switch
        {
            NumberSeriesEntityTypes.Customer => await _context.Set<Customer>()
                .AnyAsync(c => c.CompanyId == companyId && c.Id.ToString() == manualNumber),
            NumberSeriesEntityTypes.Project => await _context.Set<Project>()
                .AnyAsync(p => p.JobNumber == manualNumber),
            NumberSeriesEntityTypes.Package => await _context.Set<Package>()
                .AnyAsync(p => p.PackageNumber == manualNumber),
            NumberSeriesEntityTypes.WorkCenter => await _context.Set<WorkCenter>()
                .AnyAsync(w => w.CompanyId == companyId && w.Code == manualNumber),
            NumberSeriesEntityTypes.MachineCenter => await _context.Set<MachineCenter>()
                .AnyAsync(m => m.CompanyId == companyId && m.MachineCode == manualNumber),
            NumberSeriesEntityTypes.RoutingTemplate => await _context.Set<RoutingTemplate>()
                .AnyAsync(r => r.CompanyId == companyId && r.Code == manualNumber),
            _ => false
        };
        
        return !exists;
    }

    public async Task InitializeDefaultNumberSeriesAsync(int companyId, int? createdByUserId = null)
    {
        var defaultConfigs = GetDefaultNumberSeriesConfigurations(companyId, createdByUserId);
        
        foreach (var config in defaultConfigs)
        {
            var existing = await GetNumberSeriesAsync(companyId, config.EntityType);
            if (existing == null)
            {
                _context.Add(config);
            }
        }
        
        await _context.SaveChangesAsync();
        _logger.LogInformation($"Initialized default number series for company {companyId}");
    }

    public async Task PerformPeriodicResetAsync(int companyId)
    {
        var allSeries = await GetAllNumberSeriesAsync(companyId);
        var now = DateTime.UtcNow;
        
        foreach (var series in allSeries)
        {
            await CheckAndPerformResetAsync(series);
        }
        
        await _context.SaveChangesAsync();
    }

    public async Task<NumberSeriesStatistics> GetStatisticsAsync(int companyId, string entityType)
    {
        var series = await GetNumberSeriesAsync(companyId, entityType);
        if (series == null)
        {
            return new NumberSeriesStatistics
            {
                EntityType = entityType,
                IsActive = false
            };
        }
        
        var stats = new NumberSeriesStatistics
        {
            EntityType = entityType,
            CurrentNumber = series.CurrentNumber,
            TotalUsed = series.CurrentNumber - series.StartingNumber + 1,
            LastUsedDate = series.LastUsed,
            NextNumberPreview = series.GetNextNumberPreview(),
            IsActive = series.IsActive,
            RequiresReset = await CheckIfResetRequiredAsync(series)
        };
        
        // Get last generated number (this would vary by entity type)
        stats.LastGeneratedNumber = series.FormatNumber(series.CurrentNumber);
        
        return stats;
    }

    private async Task<NumberSeries> GetOrCreateNumberSeriesAsync(int companyId, string entityType)
    {
        var series = await GetNumberSeriesAsync(companyId, entityType);
        
        if (series == null)
        {
            // Create default configuration
            series = CreateDefaultNumberSeries(companyId, entityType);
            _context.Add(series);
            await _context.SaveChangesAsync();
        }
        
        return series;
    }

    private async Task CheckAndPerformResetAsync(NumberSeries series, bool preview = false)
    {
        var now = DateTime.UtcNow;
        bool shouldReset = false;
        
        if (series.ResetYearly && series.LastResetYear != now.Year)
        {
            shouldReset = true;
        }
        else if (series.ResetMonthly && (series.LastResetMonth != now.Month || series.LastResetYear != now.Year))
        {
            shouldReset = true;
        }
        
        if (shouldReset && !preview)
        {
            series.CurrentNumber = series.StartingNumber - series.IncrementBy;
            series.LastResetYear = now.Year;
            series.LastResetMonth = now.Month;
            _logger.LogInformation($"Performed periodic reset for {series.EntityType} in company {series.CompanyId}");
        }
    }

    private async Task<bool> CheckIfResetRequiredAsync(NumberSeries series)
    {
        var now = DateTime.UtcNow;
        
        if (series.ResetYearly && series.LastResetYear != now.Year)
            return true;
            
        if (series.ResetMonthly && (series.LastResetMonth != now.Month || series.LastResetYear != now.Year))
            return true;
            
        return false;
    }

    private NumberSeries CreateDefaultNumberSeries(int companyId, string entityType)
    {
        var (prefix, minDigits, description) = entityType switch
        {
            NumberSeriesEntityTypes.Customer => ("CUST-", 5, "Customer numbering"),
            NumberSeriesEntityTypes.Project => ("PROJ-", 5, "Project numbering"),
            NumberSeriesEntityTypes.Package => ("PKG-", 5, "Package numbering"),
            NumberSeriesEntityTypes.WorkCenter => ("WC-", 3, "Work center codes"),
            NumberSeriesEntityTypes.MachineCenter => ("MC-", 3, "Machine center codes"),
            NumberSeriesEntityTypes.RoutingTemplate => ("RT-", 3, "Routing template codes"),
            NumberSeriesEntityTypes.Estimation => ("EST-", 5, "Estimation numbering"),
            NumberSeriesEntityTypes.User => ("USR-", 4, "User codes"),
            NumberSeriesEntityTypes.Material => ("MAT-", 3, "Material codes"),
            NumberSeriesEntityTypes.ProcessingItem => ("PI-", 6, "Processing item numbering"),
            NumberSeriesEntityTypes.WeldingItem => ("WI-", 6, "Welding item numbering"),
            NumberSeriesEntityTypes.Invoice => ("INV-", 5, "Invoice numbering"),
            NumberSeriesEntityTypes.PurchaseOrder => ("PO-", 5, "Purchase order numbering"),
            NumberSeriesEntityTypes.Quote => ("QT-", 5, "Quote numbering"),
            _ => ("", 5, $"{entityType} numbering")
        };
        
        return new NumberSeries
        {
            CompanyId = companyId,
            EntityType = entityType,
            Prefix = prefix,
            Suffix = "",
            CurrentNumber = 0,
            StartingNumber = 1,
            IncrementBy = 1,
            MinDigits = minDigits,
            Format = null,
            IncludeYear = false,
            IncludeMonth = false,
            IncludeCompanyCode = false,
            ResetYearly = false,
            ResetMonthly = false,
            IsActive = true,
            AllowManualEntry = true,
            Description = description,
            CreatedDate = DateTime.UtcNow,
            LastModified = DateTime.UtcNow,
            LastUsed = DateTime.UtcNow
        };
    }

    private List<NumberSeries> GetDefaultNumberSeriesConfigurations(int companyId, int? createdByUserId)
    {
        var entityTypes = new[]
        {
            NumberSeriesEntityTypes.Customer,
            NumberSeriesEntityTypes.Project,
            NumberSeriesEntityTypes.Package,
            NumberSeriesEntityTypes.WorkCenter,
            NumberSeriesEntityTypes.MachineCenter,
            NumberSeriesEntityTypes.RoutingTemplate,
            NumberSeriesEntityTypes.Estimation,
            NumberSeriesEntityTypes.User,
            NumberSeriesEntityTypes.Material,
            NumberSeriesEntityTypes.ProcessingItem,
            NumberSeriesEntityTypes.WeldingItem
        };
        
        return entityTypes.Select(entityType =>
        {
            var series = CreateDefaultNumberSeries(companyId, entityType);
            series.CreatedByUserId = createdByUserId;
            return series;
        }).ToList();
    }
}