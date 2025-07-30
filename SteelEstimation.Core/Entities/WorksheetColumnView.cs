using System;
using System.Collections.Generic;

namespace SteelEstimation.Core.Entities;

public class WorksheetColumnView
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int CompanyId { get; set; }
    public string ViewName { get; set; } = string.Empty;
    public string WorksheetType { get; set; } = string.Empty; // "Processing" or "Welding"
    public bool IsDefault { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    
    // Navigation properties
    public User User { get; set; } = null!;
    public Company Company { get; set; } = null!;
    public List<WorksheetColumnOrder> ColumnOrders { get; set; } = new();
}