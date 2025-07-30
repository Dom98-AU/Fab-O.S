using SteelEstimation.Core.DTOs;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Services;

public interface IWorksheetFieldService
{
    /// <summary>
    /// Gets the field dependencies for a specific field
    /// </summary>
    List<string> GetFieldDependencies(string baseType, string fieldName);
    
    /// <summary>
    /// Gets all fields that depend on the specified field
    /// </summary>
    List<string> GetDependentFields(string baseType, string fieldName);
    
    /// <summary>
    /// Checks if a field is required by other selected fields
    /// </summary>
    bool IsFieldRequired(string baseType, string fieldName, List<string> selectedFields);
    
    /// <summary>
    /// Gets the buttons that should be visible based on selected fields
    /// </summary>
    List<string> GetVisibleButtons(string baseType, List<string> selectedFields);
    
    /// <summary>
    /// Validates that all required dependencies are met
    /// </summary>
    (bool isValid, List<string> missingDependencies) ValidateFieldDependencies(string baseType, List<string> selectedFields);
    
    /// <summary>
    /// Gets the default column width for a field
    /// </summary>
    int GetDefaultColumnWidth(string fieldName);
    
    /// <summary>
    /// Gets all available fields for a worksheet type
    /// </summary>
    Dictionary<string, List<FieldDefinition>> GetAvailableFields(string baseType);
}