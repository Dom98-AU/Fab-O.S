namespace SteelEstimation.Core.DTOs;

public class ExcelImportDto
{
    public string? Quantity { get; set; }
    public string? Description { get; set; }
    public string? Length { get; set; }
    public string? PartWeight { get; set; }
    public string? Remark { get; set; }
    public string? MaterialId { get; set; }
    
    // Additional fields that might be in Excel
    public string? Size { get; set; }
    public string? Grade { get; set; }
    public string? Finish { get; set; }
    
    // Validation
    public bool IsValid { get; set; }
    public List<string> ValidationErrors { get; set; } = new();
}

public class ExcelImportResult
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public List<ExcelImportDto> ImportedItems { get; set; } = new();
    public List<string> Errors { get; set; } = new();
    public int TotalRows { get; set; }
    public int ValidRows { get; set; }
    public int InvalidRows { get; set; }
    public Dictionary<string, string> ColumnMappings { get; set; } = new();
}