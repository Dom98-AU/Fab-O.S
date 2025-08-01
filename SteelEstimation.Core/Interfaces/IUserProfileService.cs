using System;
using System.Threading.Tasks;
using SteelEstimation.Core.DTOs;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Interfaces
{
    public interface IUserProfileService
    {
        // Profile CRUD operations
        Task<UserProfile?> GetUserProfileAsync(int userId);
        Task<UserProfile> CreateUserProfileAsync(int userId, CreateUserProfileRequest request);
        Task<UserProfile?> UpdateUserProfileAsync(int userId, UpdateUserProfileRequest request);
        Task<bool> DeleteUserProfileAsync(int userId);
        
        // Profile queries
        Task<UserProfile?> GetUserProfileByUsernameAsync(string username);
        Task<IEnumerable<UserProfile>> SearchProfilesAsync(string searchTerm);
        Task<IEnumerable<UserProfile>> GetProfilesByCompanyAsync(int companyId);
        Task<IEnumerable<UserProfile>> GetProfilesByDepartmentAsync(int companyId, string department);
        
        // Avatar management
        Task<string?> UpdateAvatarAsync(int userId, byte[] imageData, string contentType);
        Task<bool> DeleteAvatarAsync(int userId);
        
        // Status management
        Task<bool> UpdateUserStatusAsync(int userId, string status, string? statusMessage = null);
        Task<bool> UpdateLastActivityAsync(int userId);
        
        // Preference management
        Task<UserPreference?> GetUserPreferencesAsync(int userId);
        Task<UserPreference> CreateUserPreferencesAsync(int userId, CreateUserPreferencesRequest request);
        Task<UserPreference?> UpdateUserPreferencesAsync(int userId, UpdateUserPreferencesRequest request);
        Task<bool> ResetUserPreferencesAsync(int userId);
        
        // Module-specific preferences
        Task<bool> UpdateModulePreferencesAsync(int userId, string moduleName, string preferencesJson);
        Task<string?> GetModulePreferencesAsync(int userId, string moduleName);
    }
}