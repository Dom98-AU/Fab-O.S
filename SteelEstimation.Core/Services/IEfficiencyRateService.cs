using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Services;

public interface IEfficiencyRateService
{
    Task<List<EfficiencyRate>> GetAllAsync(int companyId);
    Task<List<EfficiencyRate>> GetActiveAsync(int companyId);
    Task<EfficiencyRate?> GetByIdAsync(int id);
    Task<EfficiencyRate?> GetDefaultAsync(int companyId);
    Task<EfficiencyRate> CreateAsync(EfficiencyRate efficiencyRate);
    Task<EfficiencyRate> UpdateAsync(EfficiencyRate efficiencyRate);
    Task DeleteAsync(int id);
    Task<bool> SetDefaultAsync(int id);
    Task<decimal> GetEffectiveEfficiencyAsync(int packageId);
}