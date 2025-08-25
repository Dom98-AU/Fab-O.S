using System;
using System.Threading.Tasks;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Interfaces;

public interface INumberSeriesService
{
    /// <summary>
    /// Gets the next number in the series and increments the counter
    /// </summary>
    Task<string> GetNextNumberAsync(int companyId, string entityType);
    
    /// <summary>
    /// Previews the next number without incrementing the counter
    /// </summary>
    Task<string> PreviewNextNumberAsync(int companyId, string entityType);
    
    /// <summary>
    /// Gets the number series configuration for an entity type
    /// </summary>
    Task<NumberSeries?> GetNumberSeriesAsync(int companyId, string entityType);
    
    /// <summary>
    /// Gets all number series configurations for a company
    /// </summary>
    Task<List<NumberSeries>> GetAllNumberSeriesAsync(int companyId);
    
    /// <summary>
    /// Creates or updates a number series configuration
    /// </summary>
    Task<NumberSeries> ConfigureNumberSeriesAsync(NumberSeries numberSeries);
    
    /// <summary>
    /// Resets the number series counter to a specific value
    /// </summary>
    Task<bool> ResetNumberSeriesAsync(int companyId, string entityType, int newStartNumber);
    
    /// <summary>
    /// Checks if auto-numbering is enabled for an entity type
    /// </summary>
    Task<bool> IsAutoNumberingEnabledAsync(int companyId, string entityType);
    
    /// <summary>
    /// Validates if a manually entered number is valid and not already used
    /// </summary>
    Task<bool> ValidateManualNumberAsync(int companyId, string entityType, string manualNumber);
    
    /// <summary>
    /// Initializes default number series for a new company
    /// </summary>
    Task InitializeDefaultNumberSeriesAsync(int companyId, int? createdByUserId = null);
    
    /// <summary>
    /// Performs periodic reset of number series (yearly/monthly) if configured
    /// </summary>
    Task PerformPeriodicResetAsync(int companyId);
    
    /// <summary>
    /// Gets usage statistics for number series
    /// </summary>
    Task<NumberSeriesStatistics> GetStatisticsAsync(int companyId, string entityType);
}

public class NumberSeriesStatistics
{
    public string EntityType { get; set; } = string.Empty;
    public int CurrentNumber { get; set; }
    public int TotalUsed { get; set; }
    public DateTime? LastUsedDate { get; set; }
    public string? LastGeneratedNumber { get; set; }
    public string? NextNumberPreview { get; set; }
    public bool IsActive { get; set; }
    public bool RequiresReset { get; set; }
}