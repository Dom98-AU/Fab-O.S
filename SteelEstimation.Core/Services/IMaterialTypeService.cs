namespace SteelEstimation.Core.Services;

public interface IMaterialTypeService
{
    Task<string> GetMaterialTypeAsync(int companyId, string? materialId);
    Task<bool> IsBeamMaterialAsync(int companyId, string? materialId);
    Task<bool> IsPlateMaterialAsync(int companyId, string? materialId);
    Task<bool> IsPurlinMaterialAsync(int companyId, string? materialId);
    Task<bool> IsMiscMaterialAsync(int companyId, string? materialId);
    
    // Synchronous versions for compatibility (uses default company)
    string GetMaterialType(string? materialId);
    bool IsBeamMaterial(string? materialId);
    bool IsPlateMaterial(string? materialId);
    bool IsPurlinMaterial(string? materialId);
    bool IsMiscMaterial(string? materialId);
}