using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SteelEstimation.Core.Entities;
using SteelEstimation.Infrastructure.Data;
using SteelEstimation.Core.Interfaces;
using System.Text.Json;

namespace SteelEstimation.Web.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class TableViewsController : ControllerBase
{
    private readonly IDbContextFactory<ApplicationDbContext> _dbFactory;
    private readonly IAuthenticationService _authService;

    public TableViewsController(
        IDbContextFactory<ApplicationDbContext> dbFactory,
        IAuthenticationService authService)
    {
        _dbFactory = dbFactory;
        _authService = authService;
    }

    [HttpGet("table/{tableType}")]
    public async Task<ActionResult<List<TableViewDto>>> GetTableViews(string tableType)
    {
        var userId = await _authService.GetCurrentUserIdAsync();
        var companyId = await _authService.GetUserCompanyIdAsync();

        if (!userId.HasValue || !companyId.HasValue)
            return Unauthorized();

        using var context = await _dbFactory.CreateDbContextAsync();
        
        var views = await context.TableViews
            .Where(v => v.TableType == tableType && 
                       (v.UserId == userId.Value || (v.CompanyId == companyId.Value && v.IsShared)))
            .OrderBy(v => v.ViewName)
            .Select(v => new TableViewDto
            {
                Id = v.Id,
                ViewName = v.ViewName,
                TableType = v.TableType,
                IsDefault = v.IsDefault,
                IsShared = v.IsShared,
                IsOwner = v.UserId == userId.Value,
                CreatedAt = v.CreatedAt,
                UpdatedAt = v.UpdatedAt
            })
            .ToListAsync();

        return Ok(views);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<TableViewDetailDto>> GetTableView(int id)
    {
        var userId = await _authService.GetCurrentUserIdAsync();
        var companyId = await _authService.GetUserCompanyIdAsync();

        if (!userId.HasValue || !companyId.HasValue)
            return Unauthorized();

        using var context = await _dbFactory.CreateDbContextAsync();
        
        var view = await context.TableViews
            .Where(v => v.Id == id && 
                       (v.UserId == userId.Value || (v.CompanyId == companyId.Value && v.IsShared)))
            .Select(v => new TableViewDetailDto
            {
                Id = v.Id,
                ViewName = v.ViewName,
                TableType = v.TableType,
                IsDefault = v.IsDefault,
                IsShared = v.IsShared,
                IsOwner = v.UserId == userId.Value,
                ColumnOrder = v.ColumnOrder,
                ColumnWidths = v.ColumnWidths,
                ColumnVisibility = v.ColumnVisibility,
                CreatedAt = v.CreatedAt,
                UpdatedAt = v.UpdatedAt
            })
            .FirstOrDefaultAsync();

        if (view == null)
            return NotFound();

        return Ok(view);
    }

    [HttpPost]
    public async Task<ActionResult<TableViewDto>> CreateTableView(CreateTableViewDto dto)
    {
        var userId = await _authService.GetCurrentUserIdAsync();
        var companyId = await _authService.GetUserCompanyIdAsync();

        if (!userId.HasValue || !companyId.HasValue)
            return Unauthorized();

        using var context = await _dbFactory.CreateDbContextAsync();
        
        // Check if view name already exists for this user/table
        var existingView = await context.TableViews
            .AnyAsync(v => v.UserId == userId.Value && 
                          v.TableType == dto.TableType && 
                          v.ViewName == dto.ViewName);
                          
        if (existingView)
            return BadRequest("A view with this name already exists");

        var view = new TableView
        {
            UserId = userId.Value,
            CompanyId = companyId.Value,
            ViewName = dto.ViewName,
            TableType = dto.TableType,
            IsDefault = dto.IsDefault,
            IsShared = dto.IsShared,
            ColumnOrder = dto.ColumnOrder,
            ColumnWidths = dto.ColumnWidths,
            ColumnVisibility = dto.ColumnVisibility,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        // If setting as default, unset other defaults for this user/table
        if (dto.IsDefault)
        {
            var existingDefaults = await context.TableViews
                .Where(v => v.UserId == userId.Value && 
                           v.TableType == dto.TableType && 
                           v.IsDefault)
                .ToListAsync();
                
            foreach (var existing in existingDefaults)
            {
                existing.IsDefault = false;
            }
        }

        context.TableViews.Add(view);
        await context.SaveChangesAsync();

        return Ok(new TableViewDto
        {
            Id = view.Id,
            ViewName = view.ViewName,
            TableType = view.TableType,
            IsDefault = view.IsDefault,
            IsShared = view.IsShared,
            IsOwner = true,
            CreatedAt = view.CreatedAt,
            UpdatedAt = view.UpdatedAt
        });
    }

    [HttpPut("{id}")]
    public async Task<ActionResult> UpdateTableView(int id, UpdateTableViewDto dto)
    {
        var userId = await _authService.GetCurrentUserIdAsync();
        var companyId = await _authService.GetUserCompanyIdAsync();

        if (!userId.HasValue || !companyId.HasValue)
            return Unauthorized();

        using var context = await _dbFactory.CreateDbContextAsync();
        
        var view = await context.TableViews
            .FirstOrDefaultAsync(v => v.Id == id && v.UserId == userId.Value);
            
        if (view == null)
            return NotFound();

        view.ViewName = dto.ViewName;
        view.IsDefault = dto.IsDefault;
        view.IsShared = dto.IsShared;
        view.ColumnOrder = dto.ColumnOrder;
        view.ColumnWidths = dto.ColumnWidths;
        view.ColumnVisibility = dto.ColumnVisibility;
        view.UpdatedAt = DateTime.UtcNow;

        // If setting as default, unset other defaults for this user/table
        if (dto.IsDefault)
        {
            var existingDefaults = await context.TableViews
                .Where(v => v.UserId == userId.Value && 
                           v.TableType == view.TableType && 
                           v.Id != id &&
                           v.IsDefault)
                .ToListAsync();
                
            foreach (var existing in existingDefaults)
            {
                existing.IsDefault = false;
            }
        }

        await context.SaveChangesAsync();
        return Ok();
    }

    [HttpDelete("{id}")]
    public async Task<ActionResult> DeleteTableView(int id)
    {
        var userId = await _authService.GetCurrentUserIdAsync();

        if (!userId.HasValue)
            return Unauthorized();

        using var context = await _dbFactory.CreateDbContextAsync();
        
        var view = await context.TableViews
            .FirstOrDefaultAsync(v => v.Id == id && v.UserId == userId.Value);
            
        if (view == null)
            return NotFound();

        context.TableViews.Remove(view);
        await context.SaveChangesAsync();
        
        return Ok();
    }

    [HttpPost("{id}/set-default")]
    public async Task<ActionResult> SetDefaultView(int id)
    {
        var userId = await _authService.GetCurrentUserIdAsync();

        if (!userId.HasValue)
            return Unauthorized();

        using var context = await _dbFactory.CreateDbContextAsync();
        
        var view = await context.TableViews
            .FirstOrDefaultAsync(v => v.Id == id && v.UserId == userId.Value);
            
        if (view == null)
            return NotFound();

        // Unset other defaults for this user/table
        var existingDefaults = await context.TableViews
            .Where(v => v.UserId == userId.Value && 
                       v.TableType == view.TableType && 
                       v.Id != id &&
                       v.IsDefault)
            .ToListAsync();
            
        foreach (var existing in existingDefaults)
        {
            existing.IsDefault = false;
        }

        view.IsDefault = true;
        view.UpdatedAt = DateTime.UtcNow;
        
        await context.SaveChangesAsync();
        return Ok();
    }
}

// DTOs
public class TableViewDto
{
    public int Id { get; set; }
    public string ViewName { get; set; } = string.Empty;
    public string TableType { get; set; } = string.Empty;
    public bool IsDefault { get; set; }
    public bool IsShared { get; set; }
    public bool IsOwner { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class TableViewDetailDto : TableViewDto
{
    public string? ColumnOrder { get; set; }
    public string? ColumnWidths { get; set; }
    public string? ColumnVisibility { get; set; }
}

public class CreateTableViewDto
{
    public string ViewName { get; set; } = string.Empty;
    public string TableType { get; set; } = string.Empty;
    public bool IsDefault { get; set; }
    public bool IsShared { get; set; }
    public string? ColumnOrder { get; set; }
    public string? ColumnWidths { get; set; }
    public string? ColumnVisibility { get; set; }
}

public class UpdateTableViewDto
{
    public string ViewName { get; set; } = string.Empty;
    public bool IsDefault { get; set; }
    public bool IsShared { get; set; }
    public string? ColumnOrder { get; set; }
    public string? ColumnWidths { get; set; }
    public string? ColumnVisibility { get; set; }
}