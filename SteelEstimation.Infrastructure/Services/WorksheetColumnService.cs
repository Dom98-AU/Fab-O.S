using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Interfaces;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services;

public class WorksheetColumnService : IWorksheetColumnService
{
    private readonly IDbContextFactory<ApplicationDbContext> _contextFactory;
    
    public WorksheetColumnService(IDbContextFactory<ApplicationDbContext> contextFactory)
    {
        _contextFactory = contextFactory;
    }
    
    public async Task<List<WorksheetColumnView>> GetUserViewsAsync(int userId, int companyId, string worksheetType)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        return await context.WorksheetColumnViews
            .Include(v => v.ColumnOrders.OrderBy(c => c.DisplayOrder))
            .Where(v => v.UserId == userId && v.CompanyId == companyId && v.WorksheetType == worksheetType)
            .OrderBy(v => v.IsDefault ? 0 : 1)
            .ThenBy(v => v.ViewName)
            .ToListAsync();
    }
    
    public async Task<WorksheetColumnView?> GetViewAsync(int viewId)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        return await context.WorksheetColumnViews
            .Include(v => v.ColumnOrders.OrderBy(c => c.DisplayOrder))
            .FirstOrDefaultAsync(v => v.Id == viewId);
    }
    
    public async Task<WorksheetColumnView?> GetDefaultViewAsync(int userId, int companyId, string worksheetType)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        return await context.WorksheetColumnViews
            .Include(v => v.ColumnOrders.OrderBy(c => c.DisplayOrder))
            .FirstOrDefaultAsync(v => v.UserId == userId && v.CompanyId == companyId && 
                                    v.WorksheetType == worksheetType && v.IsDefault);
    }
    
    public async Task<WorksheetColumnView> CreateViewAsync(int userId, int companyId, string viewName, 
        string worksheetType, List<WorksheetColumnOrder> columnOrders)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        
        var view = new WorksheetColumnView
        {
            UserId = userId,
            CompanyId = companyId,
            ViewName = viewName,
            WorksheetType = worksheetType,
            IsDefault = false,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
            ColumnOrders = columnOrders
        };
        
        context.WorksheetColumnViews.Add(view);
        await context.SaveChangesAsync();
        
        return view;
    }
    
    public async Task<WorksheetColumnView> UpdateViewAsync(int viewId, string viewName, 
        List<WorksheetColumnOrder> columnOrders)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        
        var view = await context.WorksheetColumnViews
            .Include(v => v.ColumnOrders)
            .FirstOrDefaultAsync(v => v.Id == viewId);
            
        if (view == null)
            throw new InvalidOperationException($"View with ID {viewId} not found");
        
        view.ViewName = viewName;
        view.UpdatedAt = DateTime.UtcNow;
        
        // Remove existing column orders
        context.WorksheetColumnOrders.RemoveRange(view.ColumnOrders);
        
        // Add new column orders
        foreach (var order in columnOrders)
        {
            order.WorksheetColumnViewId = viewId;
            context.WorksheetColumnOrders.Add(order);
        }
        
        await context.SaveChangesAsync();
        
        return view;
    }
    
    public async Task<bool> DeleteViewAsync(int viewId)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        
        var view = await context.WorksheetColumnViews.FindAsync(viewId);
        if (view == null || view.IsDefault)
            return false;
        
        context.WorksheetColumnViews.Remove(view);
        await context.SaveChangesAsync();
        
        return true;
    }
    
    public async Task<bool> SetDefaultViewAsync(int userId, int companyId, int viewId)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        
        var view = await context.WorksheetColumnViews
            .FirstOrDefaultAsync(v => v.Id == viewId && v.UserId == userId && v.CompanyId == companyId);
            
        if (view == null)
            return false;
        
        // Clear existing defaults for this user/company/worksheet type
        var existingDefaults = await context.WorksheetColumnViews
            .Where(v => v.UserId == userId && v.CompanyId == companyId && 
                       v.WorksheetType == view.WorksheetType && v.IsDefault)
            .ToListAsync();
            
        foreach (var existing in existingDefaults)
        {
            existing.IsDefault = false;
        }
        
        // Set new default
        view.IsDefault = true;
        view.UpdatedAt = DateTime.UtcNow;
        
        await context.SaveChangesAsync();
        
        return true;
    }
    
    public async Task<List<WorksheetColumnOrder>> GetColumnOrdersAsync(int viewId)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        return await context.WorksheetColumnOrders
            .Where(co => co.WorksheetColumnViewId == viewId)
            .OrderBy(co => co.DisplayOrder)
            .ToListAsync();
    }
    
    public async Task UpdateColumnOrdersAsync(int viewId, List<WorksheetColumnOrder> columnOrders)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        
        // Remove existing orders
        var existing = await context.WorksheetColumnOrders
            .Where(co => co.WorksheetColumnViewId == viewId)
            .ToListAsync();
        context.WorksheetColumnOrders.RemoveRange(existing);
        
        // Add new orders
        foreach (var order in columnOrders)
        {
            order.WorksheetColumnViewId = viewId;
            context.WorksheetColumnOrders.Add(order);
        }
        
        // Update view timestamp
        var view = await context.WorksheetColumnViews.FindAsync(viewId);
        if (view != null)
        {
            view.UpdatedAt = DateTime.UtcNow;
        }
        
        await context.SaveChangesAsync();
    }
    
    public Task<Dictionary<string, int>> GetDefaultColumnOrderAsync(string worksheetType)
    {
        var processingDefaults = new Dictionary<string, int>
        {
            ["DrawingNumber"] = 1,
            ["Quantity"] = 2,
            ["Description"] = 3,
            ["Material"] = 4,
            ["MaterialType"] = 5,
            ["Weight"] = 6,
            ["TotalWeight"] = 7,
            ["DeliveryBundle"] = 8,
            ["PackBundle"] = 9,
            ["HandlingTime"] = 10,
            ["UnloadTime"] = 11,
            ["MarkMeasureCut"] = 12,
            ["QualityCheck"] = 13,
            ["MoveToAssembly"] = 14,
            ["MoveAfterWeld"] = 15,
            ["LoadingTime"] = 16
        };
        
        var weldingDefaults = new Dictionary<string, int>
        {
            ["DrawingNumber"] = 1,
            ["ItemDescription"] = 2,
            ["WeldType"] = 3,
            ["ConnectionQty"] = 4,
            ["WeldingConnections"] = 5,
            ["TotalMinutes"] = 6,
            ["Images"] = 7
        };
        
        return Task.FromResult(worksheetType == "Processing" ? processingDefaults : weldingDefaults);
    }
    
    public Task<Dictionary<string, string>> GetColumnDependenciesAsync(string worksheetType)
    {
        var dependencies = new Dictionary<string, string>();
        
        if (worksheetType == "Processing")
        {
            dependencies["Material"] = "MaterialType";
        }
        
        return Task.FromResult(dependencies);
    }
}