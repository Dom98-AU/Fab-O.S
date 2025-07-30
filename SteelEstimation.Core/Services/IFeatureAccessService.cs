using System.Collections.Generic;
using System.Threading.Tasks;
using SteelEstimation.Core.DTOs.Admin;

namespace SteelEstimation.Core.Services
{
    public interface IFeatureAccessService
    {
        /// <summary>
        /// Check if the current company has access to a specific feature
        /// </summary>
        Task<bool> HasAccessAsync(string featureCode);
        
        /// <summary>
        /// Check if a specific company has access to a feature
        /// </summary>
        Task<bool> HasAccessAsync(int companyId, string featureCode);
        
        /// <summary>
        /// Get all enabled features for the current company
        /// </summary>
        Task<List<FeatureDto>> GetEnabledFeaturesAsync();
        
        /// <summary>
        /// Get all enabled features for a specific company
        /// </summary>
        Task<List<FeatureDto>> GetEnabledFeaturesAsync(int companyId);
        
        /// <summary>
        /// Get all feature groups with their features for the current company
        /// </summary>
        Task<List<FeatureGroupDto>> GetFeatureGroupsAsync();
        
        /// <summary>
        /// Sync features from the admin portal
        /// </summary>
        Task<bool> SyncFeaturesAsync();
        
        /// <summary>
        /// Force sync features for a specific company
        /// </summary>
        Task<bool> SyncFeaturesAsync(int companyId);
        
        /// <summary>
        /// Clear feature cache for a company
        /// </summary>
        Task ClearCacheAsync(int companyId);
        
        /// <summary>
        /// Track feature usage
        /// </summary>
        Task TrackFeatureUsageAsync(string featureCode, string? context = null);
    }
}