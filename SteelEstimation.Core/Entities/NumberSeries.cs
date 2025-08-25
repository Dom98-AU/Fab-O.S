using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SteelEstimation.Core.Entities;

public class NumberSeries
{
    public int Id { get; set; }
    
    // Company-specific configuration
    public int CompanyId { get; set; }
    public virtual Company Company { get; set; } = null!;
    
    // Entity type this series applies to
    [Required]
    [MaxLength(50)]
    public string EntityType { get; set; } = string.Empty; // Customer, Project, Package, WorkCenter, etc.
    
    // Number series configuration
    [MaxLength(20)]
    public string? Prefix { get; set; } // e.g., "CUST-", "PROJ-", "PKG-"
    
    [MaxLength(20)]
    public string? Suffix { get; set; } // Optional suffix
    
    // Current and starting numbers
    public int CurrentNumber { get; set; } = 0;
    public int StartingNumber { get; set; } = 1;
    public int IncrementBy { get; set; } = 1;
    
    // Formatting options
    public int MinDigits { get; set; } = 5; // For padding zeros (e.g., 00001)
    
    [MaxLength(100)]
    public string? Format { get; set; } // Custom format string, e.g., "{Prefix}{Year}-{Number:D5}{Suffix}"
    
    // Options for format placeholders
    public bool IncludeYear { get; set; } = false; // Include current year in number
    public bool IncludeMonth { get; set; } = false; // Include current month in number
    public bool IncludeCompanyCode { get; set; } = false; // Include company code in number
    
    // Reset options
    public bool ResetYearly { get; set; } = false; // Reset counter at start of year
    public bool ResetMonthly { get; set; } = false; // Reset counter at start of month
    public int? LastResetYear { get; set; }
    public int? LastResetMonth { get; set; }
    
    // Status
    public bool IsActive { get; set; } = true;
    public bool AllowManualEntry { get; set; } = true; // Allow users to override auto-numbering
    
    // Preview and description
    [MaxLength(200)]
    public string? Description { get; set; }
    
    [MaxLength(50)]
    public string? PreviewExample { get; set; } // Shows example of next number
    
    // Audit fields
    public DateTime LastUsed { get; set; } = DateTime.UtcNow;
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    public DateTime LastModified { get; set; } = DateTime.UtcNow;
    public int? CreatedByUserId { get; set; }
    public virtual User? CreatedByUser { get; set; }
    public int? LastModifiedByUserId { get; set; }
    public virtual User? LastModifiedByUser { get; set; }
    
    // Method for generating the next number preview
    public string GetNextNumberPreview()
    {
        var nextNumber = CurrentNumber + IncrementBy;
        return FormatNumber(nextNumber, DateTime.UtcNow);
    }
    
    // Format a number according to the series configuration
    public string FormatNumber(int number, DateTime? date = null)
    {
        date ??= DateTime.UtcNow;
        
        if (!string.IsNullOrEmpty(Format))
        {
            var result = Format;
            result = result.Replace("{Prefix}", Prefix ?? "");
            result = result.Replace("{Suffix}", Suffix ?? "");
            result = result.Replace("{Number}", number.ToString($"D{MinDigits}"));
            result = result.Replace("{Year}", date.Value.Year.ToString());
            result = result.Replace("{YY}", date.Value.ToString("yy"));
            result = result.Replace("{Month}", date.Value.Month.ToString("D2"));
            result = result.Replace("{Day}", date.Value.Day.ToString("D2"));
            return result;
        }
        
        // Default format if no custom format specified
        var formattedNumber = number.ToString($"D{MinDigits}");
        var parts = new List<string>();
        
        if (!string.IsNullOrEmpty(Prefix))
            parts.Add(Prefix);
            
        if (IncludeYear)
            parts.Add(date.Value.Year.ToString());
            
        if (IncludeMonth)
            parts.Add(date.Value.Month.ToString("D2"));
            
        parts.Add(formattedNumber);
        
        if (!string.IsNullOrEmpty(Suffix))
            parts.Add(Suffix);
            
        return string.Join("-", parts.Where(p => !string.IsNullOrEmpty(p)));
    }
}

// Enum for common entity types
public static class NumberSeriesEntityTypes
{
    public const string Customer = "Customer";
    public const string Project = "Project";
    public const string Package = "Package";
    public const string WorkCenter = "WorkCenter";
    public const string MachineCenter = "MachineCenter";
    public const string RoutingTemplate = "RoutingTemplate";
    public const string Estimation = "Estimation";
    public const string User = "User";
    public const string Material = "Material";
    public const string ProcessingItem = "ProcessingItem";
    public const string WeldingItem = "WeldingItem";
    public const string Invoice = "Invoice";
    public const string PurchaseOrder = "PurchaseOrder";
    public const string Quote = "Quote";
}