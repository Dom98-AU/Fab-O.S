using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Services;

public interface ICompanySettingsService
{
    Task<List<CompanyMaterialType>> GetMaterialTypesAsync(int companyId);
    Task<CompanyMaterialType> GetMaterialTypeAsync(int companyId, int materialTypeId);
    Task<CompanyMaterialType> CreateMaterialTypeAsync(int companyId, CompanyMaterialType materialType);
    Task<CompanyMaterialType> UpdateMaterialTypeAsync(int companyId, int materialTypeId, CompanyMaterialType materialType);
    Task<bool> DeleteMaterialTypeAsync(int companyId, int materialTypeId);
    
    Task<List<CompanyMbeIdMapping>> GetMbeIdMappingsAsync(int companyId);
    Task<CompanyMbeIdMapping> CreateMbeIdMappingAsync(int companyId, CompanyMbeIdMapping mapping);
    Task<CompanyMbeIdMapping> UpdateMbeIdMappingAsync(int companyId, int mappingId, CompanyMbeIdMapping mapping);
    Task<bool> DeleteMbeIdMappingAsync(int companyId, int mappingId);
    
    Task<List<CompanyMaterialPattern>> GetMaterialPatternsAsync(int companyId);
    Task<CompanyMaterialPattern> CreateMaterialPatternAsync(int companyId, CompanyMaterialPattern pattern);
    Task<CompanyMaterialPattern> UpdateMaterialPatternAsync(int companyId, int patternId, CompanyMaterialPattern pattern);
    Task<bool> DeleteMaterialPatternAsync(int companyId, int patternId);
    
    Task<bool> CopySettingsFromCompanyAsync(int sourceCompanyId, int targetCompanyId);
}