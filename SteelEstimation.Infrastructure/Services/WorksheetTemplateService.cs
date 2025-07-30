using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Services;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services;

public class WorksheetTemplateService : IWorksheetTemplateService
{
    private readonly IDbContextFactory<ApplicationDbContext> _dbContextFactory;
    private readonly ILogger<WorksheetTemplateService> _logger;

    public WorksheetTemplateService(
        IDbContextFactory<ApplicationDbContext> dbContextFactory,
        ILogger<WorksheetTemplateService> logger)
    {
        _dbContextFactory = dbContextFactory;
        _logger = logger;
    }

    public async Task<WorksheetTemplate?> GetActiveTemplateAsync(int userId, string baseType)
    {
        using var dbContext = await _dbContextFactory.CreateDbContextAsync();
        
        // First check if user has a preferred template
        var userPreference = await dbContext.Set<UserWorksheetPreference>()
            .FirstOrDefaultAsync(p => p.UserId == userId && p.BaseType == baseType);
            
        if (userPreference != null)
        {
            var preferredTemplate = await dbContext.WorksheetTemplates
                .Include(t => t.Fields.OrderBy(f => f.DisplayOrder))
                .FirstOrDefaultAsync(t => t.Id == userPreference.TemplateId);
                
            if (preferredTemplate != null)
                return preferredTemplate;
        }
        
        // Fall back to default template
        return await GetDefaultTemplateAsync(baseType);
    }

    public async Task<WorksheetTemplate?> GetDefaultTemplateAsync(string baseType)
    {
        using var dbContext = await _dbContextFactory.CreateDbContextAsync();
        
        return await dbContext.WorksheetTemplates
            .Include(t => t.Fields.OrderBy(f => f.DisplayOrder))
            .FirstOrDefaultAsync(t => t.BaseType == baseType && t.IsDefault);
    }

    public async Task<WorksheetTemplate?> GetTemplateWithFieldsAsync(int templateId)
    {
        using var dbContext = await _dbContextFactory.CreateDbContextAsync();
        
        return await dbContext.WorksheetTemplates
            .Include(t => t.Fields.OrderBy(f => f.DisplayOrder))
            .FirstOrDefaultAsync(t => t.Id == templateId);
    }

    public async Task SetUserPreferredTemplateAsync(int userId, int templateId, string baseType)
    {
        using var dbContext = await _dbContextFactory.CreateDbContextAsync();
        
        var preference = await dbContext.Set<UserWorksheetPreference>()
            .FirstOrDefaultAsync(p => p.UserId == userId && p.BaseType == baseType);
            
        if (preference == null)
        {
            preference = new UserWorksheetPreference
            {
                UserId = userId,
                BaseType = baseType,
                TemplateId = templateId
            };
            dbContext.Set<UserWorksheetPreference>().Add(preference);
        }
        else
        {
            preference.TemplateId = templateId;
        }
        
        await dbContext.SaveChangesAsync();
    }

    public async Task<List<WorksheetTemplateField>> GetVisibleFieldsAsync(int templateId)
    {
        using var dbContext = await _dbContextFactory.CreateDbContextAsync();
        
        return await dbContext.WorksheetTemplateFields
            .Where(f => f.WorksheetTemplateId == templateId && f.IsVisible)
            .OrderBy(f => f.DisplayOrder)
            .ToListAsync();
    }
}