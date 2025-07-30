using System;
using System.Collections.Generic;

namespace SteelEstimation.Core.Entities;

public class TableView
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int CompanyId { get; set; }
    public string ViewName { get; set; } = string.Empty;
    public string TableType { get; set; } = string.Empty; // "Customers", "Projects", "Worksheets", etc.
    public bool IsDefault { get; set; }
    public bool IsShared { get; set; } // Can other users in the company see this view
    public string? ColumnOrder { get; set; } // JSON array of column names in order
    public string? ColumnWidths { get; set; } // JSON object of column widths
    public string? ColumnVisibility { get; set; } // JSON object of column visibility
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    
    // Navigation properties
    public User User { get; set; } = null!;
    public Company Company { get; set; } = null!;
}