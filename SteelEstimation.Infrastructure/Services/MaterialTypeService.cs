using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SteelEstimation.Core.Configuration;
using SteelEstimation.Core.Interfaces;
using SteelEstimation.Core.Services;
using SteelEstimation.Infrastructure.Data;
using System.Text.RegularExpressions;

namespace SteelEstimation.Infrastructure.Services;

public class MaterialTypeService : IMaterialTypeService
{
    private readonly IDbContextFactory<ApplicationDbContext> _contextFactory;
    private readonly MaterialMappingSettings _settings;
    private readonly IFabOSAuthenticationService _authService;
    
    public MaterialTypeService(
        IDbContextFactory<ApplicationDbContext> contextFactory,
        IOptions<MaterialMappingSettings> settings,
        IFabOSAuthenticationService authService)
    {
        _contextFactory = contextFactory;
        _settings = settings.Value;
        _authService = authService;
    }
    
    public async Task<string> GetMaterialTypeAsync(int companyId, string? materialId)
    {
        if (string.IsNullOrWhiteSpace(materialId))
            return "Misc";
        
        // First check MBE ID mappings
        using var context = await _contextFactory.CreateDbContextAsync();
        
        var mbeMapping = await context.CompanyMbeIdMappings
            .FirstOrDefaultAsync(m => m.CompanyId == companyId && m.MbeId == materialId);
            
        if (mbeMapping != null)
            return mbeMapping.MaterialType;
        
        // Then check material patterns
        var patterns = await context.CompanyMaterialPatterns
            .Where(p => p.CompanyId == companyId && p.IsActive)
            .OrderBy(p => p.Priority)
            .ToListAsync();
            
        foreach (var pattern in patterns)
        {
            if (pattern.PatternType == "StartsWith" && materialId.StartsWith(pattern.Pattern, StringComparison.OrdinalIgnoreCase))
                return pattern.MaterialType;
            else if (pattern.PatternType == "Contains" && materialId.Contains(pattern.Pattern, StringComparison.OrdinalIgnoreCase))
                return pattern.MaterialType;
            else if (pattern.PatternType == "Regex")
            {
                try
                {
                    if (Regex.IsMatch(materialId, pattern.Pattern, RegexOptions.IgnoreCase))
                        return pattern.MaterialType;
                }
                catch { /* Invalid regex, skip */ }
            }
        }
        
        // Default to Misc if no match
        return "Misc";
    }
    
    public async Task<bool> IsBeamMaterialAsync(int companyId, string? materialId)
    {
        var type = await GetMaterialTypeAsync(companyId, materialId);
        return type.Equals("Beam", StringComparison.OrdinalIgnoreCase);
    }
    
    public async Task<bool> IsPlateMaterialAsync(int companyId, string? materialId)
    {
        var type = await GetMaterialTypeAsync(companyId, materialId);
        return type.Equals("Plate", StringComparison.OrdinalIgnoreCase);
    }
    
    public async Task<bool> IsPurlinMaterialAsync(int companyId, string? materialId)
    {
        var type = await GetMaterialTypeAsync(companyId, materialId);
        return type.Equals("Purlin", StringComparison.OrdinalIgnoreCase);
    }
    
    public async Task<bool> IsMiscMaterialAsync(int companyId, string? materialId)
    {
        var type = await GetMaterialTypeAsync(companyId, materialId);
        return type.Equals("Misc", StringComparison.OrdinalIgnoreCase);
    }
    
    // Synchronous versions for compatibility - uses current user's company
    public string GetMaterialType(string? materialId)
    {
        var user = _authService.GetCurrentUserAsync().GetAwaiter().GetResult();
        if (user == null)
        {
            // Fall back to settings if no user context
            return _settings.GetMaterialTypeFromMbeId(materialId);
        }
        
        return GetMaterialTypeAsync(user.CompanyId, materialId).GetAwaiter().GetResult();
    }
    
    public bool IsBeamMaterial(string? materialId)
    {
        return GetMaterialType(materialId).Equals("Beam", StringComparison.OrdinalIgnoreCase);
    }
    
    public bool IsPlateMaterial(string? materialId)
    {
        return GetMaterialType(materialId).Equals("Plate", StringComparison.OrdinalIgnoreCase);
    }
    
    public bool IsPurlinMaterial(string? materialId)
    {
        return GetMaterialType(materialId).Equals("Purlin", StringComparison.OrdinalIgnoreCase);
    }
    
    public bool IsMiscMaterial(string? materialId)
    {
        return GetMaterialType(materialId).Equals("Misc", StringComparison.OrdinalIgnoreCase);
    }
}