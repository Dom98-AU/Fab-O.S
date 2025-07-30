using SteelEstimation.Core.DTOs;
using SteelEstimation.Core.Services;

namespace SteelEstimation.Infrastructure.Services;

public class WorksheetFieldService : IWorksheetFieldService
{
    // Field dependency mappings
    private static readonly Dictionary<string, Dictionary<string, List<string>>> FieldDependencies = new()
    {
        ["Processing"] = new Dictionary<string, List<string>>
        {
            ["TotalWeight"] = new() { "Quantity", "Weight" },
            ["TotalHours"] = new() { "UnloadTime", "MarkMeasureCut", "QualityCheck", 
                                     "MoveToAssembly", "MoveAfterWeld", "LoadingTime" }
        },
        ["Welding"] = new Dictionary<string, List<string>>
        {
            ["ConnectionHours"] = new() { "ConnectionType", "AssembleFitTack", "Weld", "WeldCheck" },
            ["TotalHours"] = new() { "AssembleFitTack", "Weld", "WeldCheck", "WeldTest" }
        }
    };
    
    // Button visibility rules based on fields
    private static readonly Dictionary<string, Dictionary<string, List<string>>> ButtonFieldDependencies = new()
    {
        ["Processing"] = new Dictionary<string, List<string>>
        {
            ["Split Rows"] = new() { "Quantity" },
            ["Create Delivery Bundle"] = new() { "DeliveryBundle" },
            ["Create Pack Bundle"] = new() { "PackBundle" },
            ["Auto Bundle"] = new() { "DeliveryBundle" },
            ["Manage Bundles"] = new() { "DeliveryBundle", "PackBundle" } // needs at least one
        },
        ["Welding"] = new Dictionary<string, List<string>>
        {
            ["Add Connection"] = new() { "ConnectionType" },
            ["Upload Image"] = new() { "Images" }
        }
    };
    
    // Default column widths
    private static readonly Dictionary<string, int> DefaultColumnWidths = new()
    {
        ["ID"] = 50,
        ["DrawingNumber"] = 120,
        ["Description"] = 200,
        ["ItemDescription"] = 200,
        ["MaterialId"] = 100,
        ["Quantity"] = 80,
        ["ConnectionQty"] = 80,
        ["Length"] = 80,
        ["Weight"] = 80,
        ["TotalWeight"] = 100,
        ["TotalHours"] = 100,
        ["DeliveryBundle"] = 150,
        ["PackBundle"] = 150,
        ["Images"] = 150,
        ["ConnectionType"] = 250,
        ["ConnectionHours"] = 250,
        ["UnloadTime"] = 100,
        ["MarkMeasureCut"] = 120,
        ["QualityCheck"] = 100,
        ["MoveToAssembly"] = 120,
        ["MoveAfterWeld"] = 120,
        ["LoadingTime"] = 100,
        ["AssembleFitTack"] = 100,
        ["Weld"] = 80,
        ["WeldCheck"] = 80,
        ["WeldTest"] = 80,
        ["WeldType"] = 100,
        ["WeldLength"] = 100,
        ["PhotoReference"] = 120,
        ["LocationComments"] = 200
    };
    
    public List<string> GetFieldDependencies(string baseType, string fieldName)
    {
        if (FieldDependencies.TryGetValue(baseType, out var typeDeps))
        {
            if (typeDeps.TryGetValue(fieldName, out var deps))
            {
                return deps;
            }
        }
        return new List<string>();
    }
    
    public List<string> GetDependentFields(string baseType, string fieldName)
    {
        var dependents = new List<string>();
        
        if (FieldDependencies.TryGetValue(baseType, out var typeDeps))
        {
            foreach (var (field, deps) in typeDeps)
            {
                if (deps.Contains(fieldName))
                {
                    dependents.Add(field);
                }
            }
        }
        
        return dependents;
    }
    
    public bool IsFieldRequired(string baseType, string fieldName, List<string> selectedFields)
    {
        // ID is always required
        if (fieldName == "ID") return true;
        
        // Check if any selected field depends on this one
        foreach (var selected in selectedFields)
        {
            var deps = GetFieldDependencies(baseType, selected);
            if (deps.Contains(fieldName))
                return true;
        }
        
        return false;
    }
    
    public List<string> GetVisibleButtons(string baseType, List<string> selectedFields)
    {
        var visibleButtons = new List<string>();
        
        // Always visible buttons
        visibleButtons.Add("Bulk Update");
        visibleButtons.Add("Bulk Delete");
        
        if (ButtonFieldDependencies.TryGetValue(baseType, out var buttonRules))
        {
            foreach (var (button, requiredFields) in buttonRules)
            {
                // For "Manage Bundles", it needs at least one of the required fields
                if (button == "Manage Bundles")
                {
                    if (requiredFields.Any(f => selectedFields.Contains(f)))
                    {
                        visibleButtons.Add(button);
                    }
                }
                else
                {
                    // For other buttons, all required fields must be present
                    if (requiredFields.All(f => selectedFields.Contains(f)))
                    {
                        visibleButtons.Add(button);
                    }
                }
            }
        }
        
        return visibleButtons;
    }
    
    public (bool isValid, List<string> missingDependencies) ValidateFieldDependencies(string baseType, List<string> selectedFields)
    {
        var missingDeps = new List<string>();
        
        foreach (var field in selectedFields)
        {
            var deps = GetFieldDependencies(baseType, field);
            var missing = deps.Where(d => !selectedFields.Contains(d)).ToList();
            
            if (missing.Any())
            {
                missingDeps.AddRange(missing.Select(m => $"{field} requires {m}"));
            }
        }
        
        return (missingDeps.Count == 0, missingDeps);
    }
    
    public int GetDefaultColumnWidth(string fieldName)
    {
        return DefaultColumnWidths.TryGetValue(fieldName, out var width) ? width : 100;
    }
    
    public Dictionary<string, List<FieldDefinition>> GetAvailableFields(string baseType)
    {
        if (baseType == "Processing")
        {
            return ProcessingFields;
        }
        else if (baseType == "Welding")
        {
            return WeldingFields;
        }
        
        return new Dictionary<string, List<FieldDefinition>>();
    }
    
    private static readonly Dictionary<string, List<FieldDefinition>> ProcessingFields = new()
    {
        ["Basic Fields"] = new List<FieldDefinition>
        {
            new() { Name = "ID", DisplayName = "ID", Category = "Basic Fields", IsRequired = true },
            new() { Name = "DrawingNumber", DisplayName = "Drawing Number", Category = "Basic Fields" },
            new() { Name = "Description", DisplayName = "Description", Category = "Basic Fields" },
            new() { Name = "MaterialId", DisplayName = "Material ID", Category = "Basic Fields" }
        },
        ["Quantity Fields"] = new List<FieldDefinition>
        {
            new() { Name = "Quantity", DisplayName = "Quantity", Category = "Quantity Fields" },
            new() { Name = "Length", DisplayName = "Length", Category = "Quantity Fields" },
            new() { Name = "Weight", DisplayName = "Weight", Category = "Quantity Fields" },
            new() { 
                Name = "TotalWeight", 
                DisplayName = "Total Weight", 
                Category = "Quantity Fields",
                IsCalculated = true, 
                HasDependencies = true,
                Dependencies = new() { "Quantity", "Weight" },
                CalculationFormula = "Quantity * Weight"
            }
        },
        ["Bundle Fields"] = new List<FieldDefinition>
        {
            new() { Name = "DeliveryBundle", DisplayName = "Delivery Bundle", Category = "Bundle Fields" },
            new() { Name = "PackBundle", DisplayName = "Pack Bundle", Category = "Bundle Fields" }
        },
        ["Time Fields"] = new List<FieldDefinition>
        {
            new() { Name = "UnloadTime", DisplayName = "Unload Time/Bundle", Category = "Time Fields" },
            new() { Name = "MarkMeasureCut", DisplayName = "Mark/Measure/Cut", Category = "Time Fields" },
            new() { Name = "QualityCheck", DisplayName = "Quality Check/Clean", Category = "Time Fields" },
            new() { Name = "MoveToAssembly", DisplayName = "Move to Assembly", Category = "Time Fields" },
            new() { Name = "MoveAfterWeld", DisplayName = "Move After Weld", Category = "Time Fields" },
            new() { Name = "LoadingTime", DisplayName = "Loading Time/Bundle", Category = "Time Fields" },
            new() { 
                Name = "TotalHours", 
                DisplayName = "Total Hours", 
                Category = "Time Fields",
                IsCalculated = true, 
                HasDependencies = true,
                Dependencies = new() { "UnloadTime", "MarkMeasureCut", "QualityCheck", 
                                     "MoveToAssembly", "MoveAfterWeld", "LoadingTime" },
                CalculationFormula = "Sum of all time fields / 60"
            }
        }
    };
    
    private static readonly Dictionary<string, List<FieldDefinition>> WeldingFields = new()
    {
        ["Basic Fields"] = new List<FieldDefinition>
        {
            new() { Name = "ID", DisplayName = "ID", Category = "Basic Fields", IsRequired = true },
            new() { Name = "DrawingNumber", DisplayName = "Drawing Number", Category = "Basic Fields" },
            new() { Name = "ItemDescription", DisplayName = "Description", Category = "Basic Fields" }
        },
        ["Visual Fields"] = new List<FieldDefinition>
        {
            new() { Name = "Images", DisplayName = "Images", Category = "Visual Fields" },
            new() { Name = "PhotoReference", DisplayName = "Photo Reference", Category = "Visual Fields" }
        },
        ["Connection Fields"] = new List<FieldDefinition>
        {
            new() { Name = "ConnectionType", DisplayName = "Connection Type", Category = "Connection Fields" },
            new() { Name = "ConnectionQty", DisplayName = "Connection Quantity", Category = "Connection Fields" },
            new() { 
                Name = "ConnectionHours", 
                DisplayName = "Connection Hours", 
                Category = "Connection Fields",
                IsCalculated = true, 
                HasDependencies = true,
                Dependencies = new() { "ConnectionType", "AssembleFitTack", "Weld", "WeldCheck" }
            }
        },
        ["Welding Details"] = new List<FieldDefinition>
        {
            new() { Name = "WeldType", DisplayName = "Weld Type", Category = "Welding Details" },
            new() { Name = "WeldLength", DisplayName = "Weld Length", Category = "Welding Details" },
            new() { Name = "Weight", DisplayName = "Weight (kg)", Category = "Welding Details" }
        },
        ["Time Fields"] = new List<FieldDefinition>
        {
            new() { Name = "AssembleFitTack", DisplayName = "Assemble/Fit/Tack", Category = "Time Fields" },
            new() { Name = "Weld", DisplayName = "Weld", Category = "Time Fields" },
            new() { Name = "WeldCheck", DisplayName = "Weld Check", Category = "Time Fields" },
            new() { Name = "WeldTest", DisplayName = "Weld Test", Category = "Time Fields" },
            new() { 
                Name = "TotalHours", 
                DisplayName = "Total Hours", 
                Category = "Time Fields",
                IsCalculated = true, 
                HasDependencies = true,
                Dependencies = new() { "AssembleFitTack", "Weld", "WeldCheck", "WeldTest" },
                CalculationFormula = "Sum of all time fields / 60"
            }
        },
        ["Additional"] = new List<FieldDefinition>
        {
            new() { Name = "LocationComments", DisplayName = "Location/Comments", Category = "Additional" }
        }
    };
}