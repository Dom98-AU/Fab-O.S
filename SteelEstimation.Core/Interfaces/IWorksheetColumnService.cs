using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Interfaces;

public interface IWorksheetColumnService
{
    // Column Views
    Task<List<WorksheetColumnView>> GetUserViewsAsync(int userId, int companyId, string worksheetType);
    Task<WorksheetColumnView?> GetViewAsync(int viewId);
    Task<WorksheetColumnView?> GetDefaultViewAsync(int userId, int companyId, string worksheetType);
    Task<WorksheetColumnView> CreateViewAsync(int userId, int companyId, string viewName, string worksheetType, List<WorksheetColumnOrder> columnOrders);
    Task<WorksheetColumnView> UpdateViewAsync(int viewId, string viewName, List<WorksheetColumnOrder> columnOrders);
    Task<bool> DeleteViewAsync(int viewId);
    Task<bool> SetDefaultViewAsync(int userId, int companyId, int viewId);
    
    // Column Orders
    Task<List<WorksheetColumnOrder>> GetColumnOrdersAsync(int viewId);
    Task UpdateColumnOrdersAsync(int viewId, List<WorksheetColumnOrder> columnOrders);
    
    // Utility methods
    Task<Dictionary<string, int>> GetDefaultColumnOrderAsync(string worksheetType);
    Task<Dictionary<string, string>> GetColumnDependenciesAsync(string worksheetType);
}