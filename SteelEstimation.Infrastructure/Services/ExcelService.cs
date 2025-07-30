using Microsoft.Extensions.Logging;
using NPOI.HSSF.UserModel;
using NPOI.SS.UserModel;
using NPOI.XSSF.UserModel;
using SteelEstimation.Core.DTOs;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Interfaces;
using System.Globalization;

namespace SteelEstimation.Infrastructure.Services;

public class ExcelService : IExcelService
{
    private readonly ILogger<ExcelService> _logger;
    
    // Column mapping dictionary
    private readonly Dictionary<string, string> _columnMappings = new()
    {
        { "quantity", "Quantity" },
        { "qty", "Quantity" },
        { "description", "Description" },
        { "desc", "Description" },
        { "length", "Length" },
        { "len", "Length" },
        { "part weight", "PartWeight" },
        { "partweight", "PartWeight" },
        { "weight", "PartWeight" },
        { "remark", "Remark" },
        { "remarks", "Remark" },
        { "comment", "Remark" },
        { "drawing", "Remark" },
        { "drawing number", "Remark" },
        { "material id", "MaterialId" },
        { "materialid", "MaterialId" },
        { "material", "MaterialId" },
        { "mbe id", "MaterialId" },
        { "mbeid", "MaterialId" },
        { "mbe", "MaterialId" },
        { "part mark", "MaterialId" },
        { "partmark", "MaterialId" },
        { "mark", "MaterialId" },
        { "size", "Size" },
        { "grade", "Grade" },
        { "finish", "Finish" }
    };

    public ExcelService(ILogger<ExcelService> logger)
    {
        _logger = logger;
    }

    public async Task<ExcelImportResult> ImportMaterialListAsync(Stream fileStream, string fileName)
    {
        var result = new ExcelImportResult();
        
        try
        {
            // Check file extension
            var extension = Path.GetExtension(fileName)?.ToLower();
            
            if (extension != ".xls" && extension != ".xlsx")
            {
                result.Message = "Invalid file format. Only .xls and .xlsx files are supported.";
                result.Errors.Add($"File extension '{extension}' is not supported.");
                return result;
            }
            
            // Create workbook based on file type
            IWorkbook workbook;
            fileStream.Position = 0;
            
            if (extension == ".xls")
            {
                try
                {
                    workbook = new HSSFWorkbook(fileStream);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to read .xls file");
                    result.Message = "Failed to read Excel 97-2003 file. The file may be corrupted or password protected.";
                    result.Errors.Add("If the file is password protected, please remove the password and try again.");
                    return result;
                }
            }
            else // .xlsx
            {
                try
                {
                    workbook = new XSSFWorkbook(fileStream);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to read .xlsx file");
                    result.Message = "Failed to read Excel file. The file may be corrupted or password protected.";
                    result.Errors.Add("If the file is password protected, please remove the password and try again.");
                    return result;
                }
            }
            
            // Get the first worksheet
            var worksheet = workbook.GetSheetAt(0);
            if (worksheet == null)
            {
                result.Message = "No worksheet found in the Excel file";
                return result;
            }
            
            // Find header row and column mappings
            var headerRow = FindHeaderRow(worksheet);
            if (headerRow == -1)
            {
                result.Message = "Could not find header row in the Excel file";
                result.Errors.Add("Make sure your Excel file has column headers like: Quantity, Description, Length, Part Weight, Remark");
                return result;
            }
            
            var columnMap = MapColumns(worksheet, headerRow);
            result.ColumnMappings = columnMap.ToDictionary(k => k.Key, v => v.Value.ToString());
            
            // Read data rows
            var lastRowNum = worksheet.LastRowNum;
            for (int row = headerRow + 1; row <= lastRowNum; row++)
            {
                var dataRow = worksheet.GetRow(row);
                if (dataRow == null) continue;
                
                var item = ReadRow(dataRow, columnMap);
                if (item != null)
                {
                    ValidateItem(item);
                    result.ImportedItems.Add(item);
                    result.TotalRows++;
                    
                    if (item.IsValid)
                        result.ValidRows++;
                    else
                        result.InvalidRows++;
                }
            }
            
            result.Success = result.ValidRows > 0;
            result.Message = $"Imported {result.ValidRows} valid items out of {result.TotalRows} total rows";
            
            _logger.LogInformation("Excel import completed: {Message}", result.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error importing Excel file: {FileName}", fileName);
            result.Message = $"Error importing file: {ex.Message}";
            result.Errors.Add(ex.Message);
        }
        
        return await Task.FromResult(result);
    }

    private int FindHeaderRow(ISheet worksheet)
    {
        var maxRows = Math.Min(10, worksheet.LastRowNum);
        
        for (int rowIndex = 0; rowIndex <= maxRows; rowIndex++)
        {
            var row = worksheet.GetRow(rowIndex);
            if (row == null) continue;
            
            var cellValues = new List<string>();
            var lastCellNum = Math.Min(20, (int)row.LastCellNum);
            
            for (int cellIndex = 0; cellIndex < lastCellNum; cellIndex++)
            {
                var cell = row.GetCell(cellIndex);
                if (cell == null) continue;
                
                var value = GetCellValueAsString(cell)?.Trim()?.ToLower() ?? "";
                if (!string.IsNullOrEmpty(value))
                    cellValues.Add(value);
            }
            
            // Check if this row contains expected headers
            if (cellValues.Any(v => _columnMappings.ContainsKey(v)))
            {
                return rowIndex;
            }
        }
        
        return -1;
    }

    private Dictionary<string, int> MapColumns(ISheet worksheet, int headerRowIndex)
    {
        var columnMap = new Dictionary<string, int>();
        var headerRow = worksheet.GetRow(headerRowIndex);
        if (headerRow == null) return columnMap;
        
        var lastCellNum = headerRow.LastCellNum;
        _logger.LogInformation($"Mapping columns from header row {headerRowIndex}");
        
        for (int cellIndex = 0; cellIndex < lastCellNum; cellIndex++)
        {
            var cell = headerRow.GetCell(cellIndex);
            if (cell == null) continue;
            
            var headerValue = GetCellValueAsString(cell)?.Trim()?.ToLower() ?? "";
            _logger.LogInformation($"Column {cellIndex}: '{headerValue}'");
            
            if (_columnMappings.TryGetValue(headerValue, out var mappedColumn))
            {
                columnMap[mappedColumn] = cellIndex;
                _logger.LogInformation($"  -> Mapped to {mappedColumn}");
            }
        }
        
        _logger.LogInformation($"Column mapping complete. Found {columnMap.Count} mapped columns.");
        return columnMap;
    }

    private ExcelImportDto? ReadRow(IRow row, Dictionary<string, int> columnMap)
    {
        // Skip empty rows
        var hasData = false;
        foreach (var cellIndex in columnMap.Values)
        {
            var cell = row.GetCell(cellIndex);
            if (cell != null && !string.IsNullOrWhiteSpace(GetCellValueAsString(cell)))
            {
                hasData = true;
                break;
            }
        }
        
        if (!hasData) return null;
        
        var item = new ExcelImportDto();
        
        // Read mapped columns
        if (columnMap.TryGetValue("Quantity", out var qtyCol))
            item.Quantity = GetCellValueAsString(row.GetCell(qtyCol))?.Trim();
            
        if (columnMap.TryGetValue("Description", out var descCol))
            item.Description = GetCellValueAsString(row.GetCell(descCol))?.Trim();
            
        if (columnMap.TryGetValue("Length", out var lenCol))
            item.Length = GetCellValueAsString(row.GetCell(lenCol))?.Trim();
            
        if (columnMap.TryGetValue("PartWeight", out var weightCol))
            item.PartWeight = GetCellValueAsString(row.GetCell(weightCol))?.Trim();
            
        if (columnMap.TryGetValue("Remark", out var remarkCol))
            item.Remark = GetCellValueAsString(row.GetCell(remarkCol))?.Trim();
            
        if (columnMap.TryGetValue("MaterialId", out var matCol))
        {
            item.MaterialId = GetCellValueAsString(row.GetCell(matCol))?.Trim();
            _logger.LogInformation($"MaterialId mapped from column {matCol}: '{item.MaterialId}'");
        }
        else
        {
            _logger.LogWarning("No MaterialId/MBE ID/Part Mark column found in mapping");
        }
            
        if (columnMap.TryGetValue("Size", out var sizeCol))
            item.Size = GetCellValueAsString(row.GetCell(sizeCol))?.Trim();
            
        if (columnMap.TryGetValue("Grade", out var gradeCol))
            item.Grade = GetCellValueAsString(row.GetCell(gradeCol))?.Trim();
            
        if (columnMap.TryGetValue("Finish", out var finishCol))
            item.Finish = GetCellValueAsString(row.GetCell(finishCol))?.Trim();
        
        return item;
    }

    private string? GetCellValueAsString(ICell? cell)
    {
        if (cell == null) return null;
        
        switch (cell.CellType)
        {
            case CellType.String:
                return cell.StringCellValue;
            case CellType.Numeric:
                // Check if it's a date
                if (DateUtil.IsCellDateFormatted(cell))
                {
                    return cell.DateCellValue.ToString();
                }
                return cell.NumericCellValue.ToString(CultureInfo.InvariantCulture);
            case CellType.Boolean:
                return cell.BooleanCellValue.ToString();
            case CellType.Formula:
                // Try to get the cached formula result
                switch (cell.CachedFormulaResultType)
                {
                    case CellType.String:
                        return cell.StringCellValue;
                    case CellType.Numeric:
                        return cell.NumericCellValue.ToString(CultureInfo.InvariantCulture);
                    case CellType.Boolean:
                        return cell.BooleanCellValue.ToString();
                    default:
                        return cell.ToString();
                }
            case CellType.Blank:
                return "";
            case CellType.Error:
                return null;
            default:
                return cell.ToString();
        }
    }

    private void ValidateItem(ExcelImportDto item)
    {
        item.IsValid = true;
        item.ValidationErrors.Clear();
        
        // Check if this is a TOTAL row - mark as invalid
        if (!string.IsNullOrEmpty(item.Description) && 
            item.Description.ToUpper().Contains("TOTAL"))
        {
            item.ValidationErrors.Add("TOTAL rows are automatically skipped");
            item.IsValid = false;
            return; // Skip other validations for TOTAL rows
        }
        
        // Validate quantity
        if (string.IsNullOrEmpty(item.Quantity))
        {
            item.ValidationErrors.Add("Quantity is required");
            item.IsValid = false;
        }
        else if (!int.TryParse(item.Quantity, out var qty) || qty < 0)
        {
            item.ValidationErrors.Add("Quantity must be a valid positive number");
            item.IsValid = false;
        }
        
        // Validate description
        if (string.IsNullOrEmpty(item.Description))
        {
            item.ValidationErrors.Add("Description is required");
            item.IsValid = false;
        }
        
        // Validate length if provided
        if (!string.IsNullOrEmpty(item.Length) && !decimal.TryParse(item.Length, NumberStyles.Any, CultureInfo.InvariantCulture, out var len))
        {
            item.ValidationErrors.Add("Length must be a valid number");
            item.IsValid = false;
        }
        
        // Validate weight if provided
        if (!string.IsNullOrEmpty(item.PartWeight) && !decimal.TryParse(item.PartWeight, NumberStyles.Any, CultureInfo.InvariantCulture, out var weight))
        {
            item.ValidationErrors.Add("Weight must be a valid number");
            item.IsValid = false;
        }
    }

    public async Task<ExcelImportResult> ValidateExcelFile(Stream fileStream, string fileName)
    {
        // This performs the same import but doesn't save anything
        return await ImportMaterialListAsync(fileStream, fileName);
    }

    public async Task<byte[]> ExportProcessingItemsAsync(List<ProcessingItem> items)
    {
        IWorkbook workbook = new XSSFWorkbook();
        var worksheet = workbook.CreateSheet("Processing Items");
        
        // Create header style
        var headerStyle = workbook.CreateCellStyle();
        var font = workbook.CreateFont();
        font.IsBold = true;
        headerStyle.SetFont(font);
        
        // Add headers
        var headers = new[] 
        { 
            "ID", "Drawing Number", "Description", "Material ID", "Quantity", 
            "Length (mm)", "Weight (kg)", "Total Weight", "Delivery Bundle Qty",
            "Pack Bundle Qty", "Bundle Group", "Pack Group", "Unload Time/Bundle",
            "Mark/Measure/Cut", "Quality Check/Clean", "Move to Assembly",
            "Move After Weld", "Loading Time/Bundle"
        };
        
        var headerRow = worksheet.CreateRow(0);
        for (int i = 0; i < headers.Length; i++)
        {
            var cell = headerRow.CreateCell(i);
            cell.SetCellValue(headers[i]);
            cell.CellStyle = headerStyle;
        }
        
        // Add data
        int rowIndex = 1;
        foreach (var item in items)
        {
            var row = worksheet.CreateRow(rowIndex);
            row.CreateCell(0).SetCellValue(rowIndex);
            row.CreateCell(1).SetCellValue(item.DrawingNumber ?? "");
            row.CreateCell(2).SetCellValue(item.Description ?? "");
            row.CreateCell(3).SetCellValue(item.MaterialId ?? "");
            row.CreateCell(4).SetCellValue(item.Quantity);
            row.CreateCell(5).SetCellValue(Convert.ToDouble(item.Length));
            row.CreateCell(6).SetCellValue(Convert.ToDouble(item.Weight));
            row.CreateCell(7).SetCellValue(Convert.ToDouble(item.TotalWeight));
            row.CreateCell(8).SetCellValue(item.DeliveryBundleQty);
            row.CreateCell(9).SetCellValue(item.PackBundleQty);
            row.CreateCell(10).SetCellValue(item.BundleGroup ?? "");
            row.CreateCell(11).SetCellValue(item.PackGroup ?? "");
            row.CreateCell(12).SetCellValue(item.UnloadTimePerBundle);
            row.CreateCell(13).SetCellValue(item.MarkMeasureCut);
            row.CreateCell(14).SetCellValue(item.QualityCheckClean);
            row.CreateCell(15).SetCellValue(item.MoveToAssembly);
            row.CreateCell(16).SetCellValue(item.MoveAfterWeld);
            row.CreateCell(17).SetCellValue(item.LoadingTimePerBundle);
            rowIndex++;
        }
        
        // Auto-size columns
        for (int i = 0; i < headers.Length; i++)
        {
            worksheet.AutoSizeColumn(i);
        }
        
        // Write to memory stream
        using var memoryStream = new MemoryStream();
        workbook.Write(memoryStream);
        return await Task.FromResult(memoryStream.ToArray());
    }

    public async Task<byte[]> ExportWeldingItemsAsync(List<WeldingItem> items)
    {
        IWorkbook workbook = new XSSFWorkbook();
        var worksheet = workbook.CreateSheet("Welding Items");
        
        // Create header style
        var headerStyle = workbook.CreateCellStyle();
        var font = workbook.CreateFont();
        font.IsBold = true;
        headerStyle.SetFont(font);
        
        // Add headers
        var headers = new[] 
        { 
            "ID", "Drawing Number", "Description", "Weld Type", "Weld Length (m)", 
            "Connection Qty", "Assemble/Fit/Tack", "Weld", "Weld Check", "Total Minutes"
        };
        
        var headerRow = worksheet.CreateRow(0);
        for (int i = 0; i < headers.Length; i++)
        {
            var cell = headerRow.CreateCell(i);
            cell.SetCellValue(headers[i]);
            cell.CellStyle = headerStyle;
        }
        
        // Add data
        int rowIndex = 1;
        foreach (var item in items)
        {
            var row = worksheet.CreateRow(rowIndex);
            row.CreateCell(0).SetCellValue(rowIndex);
            row.CreateCell(1).SetCellValue(item.DrawingNumber ?? "");
            row.CreateCell(2).SetCellValue(item.ItemDescription ?? "");
            row.CreateCell(3).SetCellValue(item.WeldType ?? "");
            row.CreateCell(4).SetCellValue(Convert.ToDouble(item.WeldLength));
            row.CreateCell(5).SetCellValue(item.ConnectionQty);
            row.CreateCell(6).SetCellValue(Convert.ToDouble(item.AssembleFitTack));
            row.CreateCell(7).SetCellValue(Convert.ToDouble(item.Weld));
            row.CreateCell(8).SetCellValue(Convert.ToDouble(item.WeldCheck));
            row.CreateCell(9).SetCellValue(Convert.ToDouble(item.TotalWeldingMinutes));
            rowIndex++;
        }
        
        // Auto-size columns
        for (int i = 0; i < headers.Length; i++)
        {
            worksheet.AutoSizeColumn(i);
        }
        
        // Write to memory stream
        using var memoryStream = new MemoryStream();
        workbook.Write(memoryStream);
        return await Task.FromResult(memoryStream.ToArray());
    }
}