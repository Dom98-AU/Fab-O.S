using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Services;

public interface IWorksheetTemplateService
{
    /// <summary>
    /// Gets the active template for a user and worksheet type
    /// </summary>
    Task<WorksheetTemplate?> GetActiveTemplateAsync(int userId, string baseType);
    
    /// <summary>
    /// Gets the default template for a worksheet type
    /// </summary>
    Task<WorksheetTemplate?> GetDefaultTemplateAsync(string baseType);
    
    /// <summary>
    /// Gets a template by ID with its fields
    /// </summary>
    Task<WorksheetTemplate?> GetTemplateWithFieldsAsync(int templateId);
    
    /// <summary>
    /// Sets a user's preferred template for a worksheet type
    /// </summary>
    Task SetUserPreferredTemplateAsync(int userId, int templateId, string baseType);
    
    /// <summary>
    /// Gets all visible fields for a template in display order
    /// </summary>
    Task<List<WorksheetTemplateField>> GetVisibleFieldsAsync(int templateId);
}