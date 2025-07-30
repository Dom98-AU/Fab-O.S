using SteelEstimation.Core.DTOs;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Interfaces;

public interface IExcelService
{
    Task<ExcelImportResult> ImportMaterialListAsync(Stream fileStream, string fileName);
    Task<byte[]> ExportProcessingItemsAsync(List<ProcessingItem> items);
    Task<byte[]> ExportWeldingItemsAsync(List<WeldingItem> items);
    Task<ExcelImportResult> ValidateExcelFile(Stream fileStream, string fileName);
}