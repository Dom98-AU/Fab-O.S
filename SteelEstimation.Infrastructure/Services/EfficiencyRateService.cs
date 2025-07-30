using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Services;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services;

public class EfficiencyRateService : IEfficiencyRateService
{
    private readonly IDbContextFactory<ApplicationDbContext> _contextFactory;
    private readonly ILogger<EfficiencyRateService> _logger;

    public EfficiencyRateService(IDbContextFactory<ApplicationDbContext> contextFactory, ILogger<EfficiencyRateService> logger)
    {
        _contextFactory = contextFactory;
        _logger = logger;
    }

    public async Task<List<EfficiencyRate>> GetAllAsync(int companyId)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        return await context.EfficiencyRates
            .Where(e => e.CompanyId == companyId)
            .OrderBy(e => e.Name)
            .ToListAsync();
    }

    public async Task<List<EfficiencyRate>> GetActiveAsync(int companyId)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        return await context.EfficiencyRates
            .Where(e => e.CompanyId == companyId && e.IsActive)
            .OrderBy(e => e.Name)
            .ToListAsync();
    }

    public async Task<EfficiencyRate?> GetByIdAsync(int id)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        return await context.EfficiencyRates
            .FirstOrDefaultAsync(e => e.Id == id);
    }

    public async Task<EfficiencyRate?> GetDefaultAsync(int companyId)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        return await context.EfficiencyRates
            .FirstOrDefaultAsync(e => e.CompanyId == companyId && e.IsDefault);
    }

    public async Task<EfficiencyRate> CreateAsync(EfficiencyRate efficiencyRate)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        
        // If this is set as default, unset other defaults
        if (efficiencyRate.IsDefault)
        {
            var existingDefaults = await context.EfficiencyRates
                .Where(e => e.CompanyId == efficiencyRate.CompanyId && e.IsDefault)
                .ToListAsync();
            
            foreach (var existing in existingDefaults)
            {
                existing.IsDefault = false;
            }
        }
        
        efficiencyRate.CreatedDate = DateTime.UtcNow;
        efficiencyRate.ModifiedDate = DateTime.UtcNow;
        
        context.EfficiencyRates.Add(efficiencyRate);
        await context.SaveChangesAsync();
        
        _logger.LogInformation("Created efficiency rate {Name} for company {CompanyId}", 
            efficiencyRate.Name, efficiencyRate.CompanyId);
        
        return efficiencyRate;
    }

    public async Task<EfficiencyRate> UpdateAsync(EfficiencyRate efficiencyRate)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        
        var existing = await context.EfficiencyRates
            .FirstOrDefaultAsync(e => e.Id == efficiencyRate.Id);
        
        if (existing == null)
        {
            throw new InvalidOperationException($"Efficiency rate with ID {efficiencyRate.Id} not found");
        }
        
        // If this is set as default, unset other defaults
        if (efficiencyRate.IsDefault && !existing.IsDefault)
        {
            var otherDefaults = await context.EfficiencyRates
                .Where(e => e.CompanyId == existing.CompanyId && e.IsDefault && e.Id != efficiencyRate.Id)
                .ToListAsync();
            
            foreach (var other in otherDefaults)
            {
                other.IsDefault = false;
            }
        }
        
        existing.Name = efficiencyRate.Name;
        existing.EfficiencyPercentage = efficiencyRate.EfficiencyPercentage;
        existing.Description = efficiencyRate.Description;
        existing.IsDefault = efficiencyRate.IsDefault;
        existing.IsActive = efficiencyRate.IsActive;
        existing.ModifiedDate = DateTime.UtcNow;
        
        await context.SaveChangesAsync();
        
        _logger.LogInformation("Updated efficiency rate {Name} (ID: {Id})", 
            existing.Name, existing.Id);
        
        return existing;
    }

    public async Task DeleteAsync(int id)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        
        var efficiencyRate = await context.EfficiencyRates
            .Include(e => e.Packages)
            .FirstOrDefaultAsync(e => e.Id == id);
        
        if (efficiencyRate == null)
        {
            throw new InvalidOperationException($"Efficiency rate with ID {id} not found");
        }
        
        // Check if it's in use
        if (efficiencyRate.Packages.Any())
        {
            throw new InvalidOperationException($"Cannot delete efficiency rate '{efficiencyRate.Name}' as it is in use by {efficiencyRate.Packages.Count} package(s)");
        }
        
        context.EfficiencyRates.Remove(efficiencyRate);
        await context.SaveChangesAsync();
        
        _logger.LogInformation("Deleted efficiency rate {Name} (ID: {Id})", 
            efficiencyRate.Name, id);
    }

    public async Task<bool> SetDefaultAsync(int id)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        
        var efficiencyRate = await context.EfficiencyRates
            .FirstOrDefaultAsync(e => e.Id == id);
        
        if (efficiencyRate == null)
        {
            return false;
        }
        
        // Unset all other defaults for this company
        var otherDefaults = await context.EfficiencyRates
            .Where(e => e.CompanyId == efficiencyRate.CompanyId && e.IsDefault && e.Id != id)
            .ToListAsync();
        
        foreach (var other in otherDefaults)
        {
            other.IsDefault = false;
        }
        
        efficiencyRate.IsDefault = true;
        efficiencyRate.ModifiedDate = DateTime.UtcNow;
        
        await context.SaveChangesAsync();
        
        _logger.LogInformation("Set efficiency rate {Name} as default for company {CompanyId}", 
            efficiencyRate.Name, efficiencyRate.CompanyId);
        
        return true;
    }

    public async Task<decimal> GetEffectiveEfficiencyAsync(int packageId)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        
        var package = await context.Packages
            .Include(p => p.EfficiencyRate)
            .FirstOrDefaultAsync(p => p.Id == packageId);
        
        if (package == null)
        {
            return 100m; // Default efficiency
        }
        
        // If package has an efficiency rate assigned, use it
        if (package.EfficiencyRate != null)
        {
            return package.EfficiencyRate.EfficiencyPercentage;
        }
        
        // Otherwise, use the direct ProcessingEfficiency value if set
        if (package.ProcessingEfficiency.HasValue)
        {
            return package.ProcessingEfficiency.Value;
        }
        
        // Default to 100%
        return 100m;
    }
}