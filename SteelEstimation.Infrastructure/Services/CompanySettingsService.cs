using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Services;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services;

public class CompanySettingsService : ICompanySettingsService
{
    private readonly IDbContextFactory<ApplicationDbContext> _contextFactory;
    private readonly ILogger<CompanySettingsService> _logger;

    public CompanySettingsService(IDbContextFactory<ApplicationDbContext> contextFactory, ILogger<CompanySettingsService> logger)
    {
        _contextFactory = contextFactory;
        _logger = logger;
    }

    #region Material Types

    public async Task<List<CompanyMaterialType>> GetMaterialTypesAsync(int companyId)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        
        return await context.CompanyMaterialTypes
            .Where(mt => mt.CompanyId == companyId)
            .OrderBy(mt => mt.DisplayOrder)
            .ThenBy(mt => mt.TypeName)
            .ToListAsync();
    }

    public async Task<CompanyMaterialType> GetMaterialTypeAsync(int companyId, int materialTypeId)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        
        var materialType = await context.CompanyMaterialTypes
            .FirstOrDefaultAsync(mt => mt.CompanyId == companyId && mt.Id == materialTypeId);
            
        if (materialType == null)
            throw new InvalidOperationException($"Material type {materialTypeId} not found for company {companyId}");
            
        return materialType;
    }

    public async Task<CompanyMaterialType> CreateMaterialTypeAsync(int companyId, CompanyMaterialType materialType)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        
        materialType.CompanyId = companyId;
        materialType.CreatedDate = DateTime.UtcNow;
        materialType.LastModified = DateTime.UtcNow;
        
        context.CompanyMaterialTypes.Add(materialType);
        await context.SaveChangesAsync();
        
        _logger.LogInformation("Created material type {TypeName} for company {CompanyId}", 
            materialType.TypeName, companyId);
            
        return materialType;
    }

    public async Task<CompanyMaterialType> UpdateMaterialTypeAsync(int companyId, int materialTypeId, CompanyMaterialType materialType)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        var existingType = await GetMaterialTypeAsync(companyId, materialTypeId);
        
        existingType.TypeName = materialType.TypeName;
        existingType.Description = materialType.Description;
        existingType.HourlyRate = materialType.HourlyRate;
        existingType.DefaultWeightPerFoot = materialType.DefaultWeightPerFoot;
        existingType.DefaultColor = materialType.DefaultColor;
        existingType.DisplayOrder = materialType.DisplayOrder;
        existingType.IsActive = materialType.IsActive;
        existingType.LastModified = DateTime.UtcNow;
        
        await context.SaveChangesAsync();
        
        _logger.LogInformation("Updated material type {TypeName} for company {CompanyId}", 
            materialType.TypeName, companyId);
            
        return existingType;
    }

    public async Task<bool> DeleteMaterialTypeAsync(int companyId, int materialTypeId)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        var materialType = await GetMaterialTypeAsync(companyId, materialTypeId);
        
        context.CompanyMaterialTypes.Remove(materialType);
        await context.SaveChangesAsync();
        
        _logger.LogInformation("Deleted material type {TypeName} for company {CompanyId}", 
            materialType.TypeName, companyId);
            
        return true;
    }

    #endregion

    #region MBE ID Mappings

    public async Task<List<CompanyMbeIdMapping>> GetMbeIdMappingsAsync(int companyId)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        
        return await context.CompanyMbeIdMappings
            .Where(m => m.CompanyId == companyId)
            .OrderBy(m => m.MbeId)
            .ToListAsync();
    }

    public async Task<CompanyMbeIdMapping> CreateMbeIdMappingAsync(int companyId, CompanyMbeIdMapping mapping)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        mapping.CompanyId = companyId;
        mapping.CreatedDate = DateTime.UtcNow;
        mapping.LastModified = DateTime.UtcNow;
        
        context.CompanyMbeIdMappings.Add(mapping);
        await context.SaveChangesAsync();
        
        _logger.LogInformation("Created MBE ID mapping {MbeId} -> {MaterialType} for company {CompanyId}", 
            mapping.MbeId, mapping.MaterialType, companyId);
            
        return mapping;
    }

    public async Task<CompanyMbeIdMapping> UpdateMbeIdMappingAsync(int companyId, int mappingId, CompanyMbeIdMapping mapping)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        var existingMapping = await context.CompanyMbeIdMappings
            .FirstOrDefaultAsync(m => m.CompanyId == companyId && m.Id == mappingId);
            
        if (existingMapping == null)
            throw new InvalidOperationException($"MBE ID mapping {mappingId} not found for company {companyId}");
        
        existingMapping.MbeId = mapping.MbeId;
        existingMapping.MaterialType = mapping.MaterialType;
        existingMapping.WeightPerFoot = mapping.WeightPerFoot;
        existingMapping.Notes = mapping.Notes;
        existingMapping.LastModified = DateTime.UtcNow;
        
        await context.SaveChangesAsync();
        
        _logger.LogInformation("Updated MBE ID mapping {MbeId} -> {MaterialType} for company {CompanyId}", 
            mapping.MbeId, mapping.MaterialType, companyId);
            
        return existingMapping;
    }

    public async Task<bool> DeleteMbeIdMappingAsync(int companyId, int mappingId)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        var mapping = await context.CompanyMbeIdMappings
            .FirstOrDefaultAsync(m => m.CompanyId == companyId && m.Id == mappingId);
            
        if (mapping == null)
            return false;
        
        context.CompanyMbeIdMappings.Remove(mapping);
        await context.SaveChangesAsync();
        
        _logger.LogInformation("Deleted MBE ID mapping {MbeId} for company {CompanyId}", 
            mapping.MbeId, companyId);
            
        return true;
    }

    #endregion

    #region Material Patterns

    public async Task<List<CompanyMaterialPattern>> GetMaterialPatternsAsync(int companyId)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        return await context.CompanyMaterialPatterns
            .Where(p => p.CompanyId == companyId)
            .OrderBy(p => p.Priority)
            .ToListAsync();
    }

    public async Task<CompanyMaterialPattern> CreateMaterialPatternAsync(int companyId, CompanyMaterialPattern pattern)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        pattern.CompanyId = companyId;
        pattern.CreatedDate = DateTime.UtcNow;
        pattern.LastModified = DateTime.UtcNow;
        
        context.CompanyMaterialPatterns.Add(pattern);
        await context.SaveChangesAsync();
        
        _logger.LogInformation("Created material pattern {Pattern} -> {MaterialType} for company {CompanyId}", 
            pattern.Pattern, pattern.MaterialType, companyId);
            
        return pattern;
    }

    public async Task<CompanyMaterialPattern> UpdateMaterialPatternAsync(int companyId, int patternId, CompanyMaterialPattern pattern)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        var existingPattern = await context.CompanyMaterialPatterns
            .FirstOrDefaultAsync(p => p.CompanyId == companyId && p.Id == patternId);
            
        if (existingPattern == null)
            throw new InvalidOperationException($"Material pattern {patternId} not found for company {companyId}");
        
        existingPattern.Pattern = pattern.Pattern;
        existingPattern.MaterialType = pattern.MaterialType;
        existingPattern.PatternType = pattern.PatternType;
        existingPattern.Priority = pattern.Priority;
        existingPattern.IsActive = pattern.IsActive;
        existingPattern.LastModified = DateTime.UtcNow;
        
        await context.SaveChangesAsync();
        
        _logger.LogInformation("Updated material pattern {Pattern} -> {MaterialType} for company {CompanyId}", 
            pattern.Pattern, pattern.MaterialType, companyId);
            
        return existingPattern;
    }

    public async Task<bool> DeleteMaterialPatternAsync(int companyId, int patternId)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        var pattern = await context.CompanyMaterialPatterns
            .FirstOrDefaultAsync(p => p.CompanyId == companyId && p.Id == patternId);
            
        if (pattern == null)
            return false;
        
        context.CompanyMaterialPatterns.Remove(pattern);
        await context.SaveChangesAsync();
        
        _logger.LogInformation("Deleted material pattern {Pattern} for company {CompanyId}", 
            pattern.Pattern, companyId);
            
        return true;
    }

    #endregion

    public async Task<bool> CopySettingsFromCompanyAsync(int sourceCompanyId, int targetCompanyId)
    {
        try
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            // Copy material types
            var sourceMaterialTypes = await context.CompanyMaterialTypes
                .Where(mt => mt.CompanyId == sourceCompanyId)
                .ToListAsync();
                
            foreach (var sourceType in sourceMaterialTypes)
            {
                var newType = new CompanyMaterialType
                {
                    CompanyId = targetCompanyId,
                    TypeName = sourceType.TypeName,
                    Description = sourceType.Description,
                    HourlyRate = sourceType.HourlyRate,
                    DefaultWeightPerFoot = sourceType.DefaultWeightPerFoot,
                    DefaultColor = sourceType.DefaultColor,
                    DisplayOrder = sourceType.DisplayOrder,
                    IsActive = sourceType.IsActive,
                    CreatedDate = DateTime.UtcNow,
                    LastModified = DateTime.UtcNow
                };
                context.CompanyMaterialTypes.Add(newType);
            }
            
            // Copy MBE ID mappings
            var sourceMappings = await context.CompanyMbeIdMappings
                .Where(m => m.CompanyId == sourceCompanyId)
                .ToListAsync();
                
            foreach (var sourceMapping in sourceMappings)
            {
                var newMapping = new CompanyMbeIdMapping
                {
                    CompanyId = targetCompanyId,
                    MbeId = sourceMapping.MbeId,
                    MaterialType = sourceMapping.MaterialType,
                    WeightPerFoot = sourceMapping.WeightPerFoot,
                    Notes = sourceMapping.Notes,
                    CreatedDate = DateTime.UtcNow,
                    LastModified = DateTime.UtcNow
                };
                context.CompanyMbeIdMappings.Add(newMapping);
            }
            
            // Copy material patterns
            var sourcePatterns = await context.CompanyMaterialPatterns
                .Where(p => p.CompanyId == sourceCompanyId)
                .ToListAsync();
                
            foreach (var sourcePattern in sourcePatterns)
            {
                var newPattern = new CompanyMaterialPattern
                {
                    CompanyId = targetCompanyId,
                    Pattern = sourcePattern.Pattern,
                    MaterialType = sourcePattern.MaterialType,
                    PatternType = sourcePattern.PatternType,
                    Priority = sourcePattern.Priority,
                    IsActive = sourcePattern.IsActive,
                    CreatedDate = DateTime.UtcNow,
                    LastModified = DateTime.UtcNow
                };
                context.CompanyMaterialPatterns.Add(newPattern);
            }
            
            await context.SaveChangesAsync();
            
            _logger.LogInformation("Copied all settings from company {SourceCompanyId} to company {TargetCompanyId}", 
                sourceCompanyId, targetCompanyId);
                
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error copying settings from company {SourceCompanyId} to company {TargetCompanyId}", 
                sourceCompanyId, targetCompanyId);
            return false;
        }
    }
}