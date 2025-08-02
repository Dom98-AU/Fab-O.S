using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SteelEstimation.Core.DTOs;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Interfaces;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services
{
    public class UserProfileService : IUserProfileService
    {
        private readonly IDbContextFactory<ApplicationDbContext> _contextFactory;
        private readonly ILogger<UserProfileService> _logger;

        public UserProfileService(IDbContextFactory<ApplicationDbContext> contextFactory, ILogger<UserProfileService> logger)
        {
            _contextFactory = contextFactory;
            _logger = logger;
        }

        public async Task<UserProfile?> GetUserProfileAsync(int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            return await context.UserProfiles
                .Include(p => p.User)
                .FirstOrDefaultAsync(p => p.UserId == userId);
        }

        public async Task<UserProfile> CreateUserProfileAsync(int userId, CreateUserProfileRequest request)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var existingProfile = await GetUserProfileAsync(userId);
            if (existingProfile != null)
            {
                throw new InvalidOperationException($"User profile already exists for user {userId}");
            }

            var profile = new UserProfile
            {
                UserId = userId,
                Bio = request.Bio,
                Location = request.Location,
                Timezone = request.Timezone ?? "UTC",
                PhoneNumber = request.PhoneNumber,
                Department = request.Department,
                DateOfBirth = request.DateOfBirth,
                StartDate = request.StartDate,
                JobTitle = request.JobTitle,
                Skills = request.Skills,
                AboutMe = request.AboutMe,
                IsProfilePublic = request.IsProfilePublic,
                ShowEmail = request.ShowEmail,
                ShowPhoneNumber = request.ShowPhoneNumber,
                AllowMentions = request.AllowMentions,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            context.UserProfiles.Add(profile);
            await context.SaveChangesAsync();

            _logger.LogInformation("Created profile for user {UserId}", userId);
            return profile;
        }

        public async Task<UserProfile?> UpdateUserProfileAsync(int userId, UpdateUserProfileRequest request)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var profile = await GetUserProfileAsync(userId);
            if (profile == null)
            {
                return null;
            }

            profile.Bio = request.Bio;
            profile.AvatarUrl = request.AvatarUrl;
            profile.AvatarType = request.AvatarType;
            profile.DiceBearStyle = request.DiceBearStyle;
            profile.DiceBearSeed = request.DiceBearSeed;
            profile.DiceBearOptions = request.DiceBearOptions;
            profile.Location = request.Location;
            profile.Timezone = request.Timezone ?? profile.Timezone;
            profile.PhoneNumber = request.PhoneNumber;
            profile.Department = request.Department;
            profile.DateOfBirth = request.DateOfBirth;
            profile.StartDate = request.StartDate;
            profile.JobTitle = request.JobTitle;
            profile.Skills = request.Skills;
            profile.AboutMe = request.AboutMe;
            profile.IsProfilePublic = request.IsProfilePublic;
            profile.ShowEmail = request.ShowEmail;
            profile.ShowPhoneNumber = request.ShowPhoneNumber;
            profile.AllowMentions = request.AllowMentions;
            profile.Status = request.Status;
            profile.StatusMessage = request.StatusMessage;
            profile.UpdatedAt = DateTime.UtcNow;

            await context.SaveChangesAsync();
            
            _logger.LogInformation("Updated profile for user {UserId}", userId);
            return profile;
        }

        public async Task<bool> DeleteUserProfileAsync(int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var profile = await GetUserProfileAsync(userId);
            if (profile == null)
            {
                return false;
            }

            context.UserProfiles.Remove(profile);
            await context.SaveChangesAsync();
            
            _logger.LogInformation("Deleted profile for user {UserId}", userId);
            return true;
        }

        public async Task<UserProfile?> GetUserProfileByUsernameAsync(string username)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            return await context.UserProfiles
                .Include(p => p.User)
                .FirstOrDefaultAsync(p => p.User.Username == username);
        }

        public async Task<IEnumerable<UserProfile>> SearchProfilesAsync(string searchTerm)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var query = context.UserProfiles
                .Include(p => p.User)
                .Where(p => p.IsProfilePublic);

            if (!string.IsNullOrWhiteSpace(searchTerm))
            {
                searchTerm = searchTerm.ToLower();
                query = query.Where(p => 
                    p.User.Username.ToLower().Contains(searchTerm) ||
                    p.User.FirstName!.ToLower().Contains(searchTerm) ||
                    p.User.LastName!.ToLower().Contains(searchTerm) ||
                    p.Bio!.ToLower().Contains(searchTerm) ||
                    p.Skills!.ToLower().Contains(searchTerm) ||
                    p.Department!.ToLower().Contains(searchTerm));
            }

            return await query.Take(50).ToListAsync();
        }

        public async Task<IEnumerable<UserProfile>> GetProfilesByCompanyAsync(int companyId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            return await context.UserProfiles
                .Include(p => p.User)
                .Where(p => p.User.CompanyId == companyId && p.IsProfilePublic)
                .OrderBy(p => p.User.FirstName)
                .ThenBy(p => p.User.LastName)
                .ToListAsync();
        }

        public async Task<IEnumerable<UserProfile>> GetProfilesByDepartmentAsync(int companyId, string department)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            return await context.UserProfiles
                .Include(p => p.User)
                .Where(p => p.User.CompanyId == companyId && 
                           p.Department == department && 
                           p.IsProfilePublic)
                .OrderBy(p => p.User.FirstName)
                .ThenBy(p => p.User.LastName)
                .ToListAsync();
        }

        public async Task<string?> UpdateAvatarAsync(int userId, byte[] imageData, string contentType)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var profile = await GetUserProfileAsync(userId);
            if (profile == null)
            {
                return null;
            }

            // TODO: Implement actual file storage (Azure Blob Storage, etc.)
            // For now, just return a placeholder URL
            var avatarUrl = $"/api/users/{userId}/avatar?v={DateTime.UtcNow.Ticks}";
            
            profile.AvatarUrl = avatarUrl;
            profile.UpdatedAt = DateTime.UtcNow;
            
            await context.SaveChangesAsync();
            
            _logger.LogInformation("Updated avatar for user {UserId}", userId);
            return avatarUrl;
        }

        public async Task<bool> DeleteAvatarAsync(int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var profile = await GetUserProfileAsync(userId);
            if (profile == null)
            {
                return false;
            }

            profile.AvatarUrl = null;
            profile.UpdatedAt = DateTime.UtcNow;
            
            await context.SaveChangesAsync();
            
            _logger.LogInformation("Deleted avatar for user {UserId}", userId);
            return true;
        }

        public async Task<bool> UpdateUserStatusAsync(int userId, string status, string? statusMessage = null)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var profile = await GetUserProfileAsync(userId);
            if (profile == null)
            {
                return false;
            }

            profile.Status = status;
            profile.StatusMessage = statusMessage;
            profile.UpdatedAt = DateTime.UtcNow;
            
            await context.SaveChangesAsync();
            
            _logger.LogInformation("Updated status for user {UserId} to {Status}", userId, status);
            return true;
        }

        public async Task<bool> UpdateLastActivityAsync(int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var profile = await GetUserProfileAsync(userId);
            if (profile == null)
            {
                return false;
            }

            profile.LastActivityAt = DateTime.UtcNow;
            
            await context.SaveChangesAsync();
            
            return true;
        }

        public async Task<UserPreference?> GetUserPreferencesAsync(int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            return await context.UserPreferences
                .FirstOrDefaultAsync(p => p.UserId == userId);
        }

        public async Task<UserPreference> CreateUserPreferencesAsync(int userId, CreateUserPreferencesRequest request)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var existingPrefs = await GetUserPreferencesAsync(userId);
            if (existingPrefs != null)
            {
                throw new InvalidOperationException($"User preferences already exist for user {userId}");
            }

            var preferences = new UserPreference
            {
                UserId = userId,
                Theme = request.Theme,
                Language = request.Language,
                DateFormat = request.DateFormat,
                TimeFormat = request.TimeFormat,
                DefaultModule = request.DefaultModule,
                AutoSaveEstimates = request.AutoSaveEstimates,
                AutoSaveIntervalMinutes = request.AutoSaveIntervalMinutes,
                EmailNotifications = request.EmailNotifications,
                EmailMentions = request.EmailMentions,
                EmailComments = request.EmailComments,
                ShowOnlineStatus = request.ShowOnlineStatus,
                ShowLastSeen = request.ShowLastSeen,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            context.UserPreferences.Add(preferences);
            await context.SaveChangesAsync();

            _logger.LogInformation("Created preferences for user {UserId}", userId);
            return preferences;
        }

        public async Task<UserPreference?> UpdateUserPreferencesAsync(int userId, UpdateUserPreferencesRequest request)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var preferences = await GetUserPreferencesAsync(userId);
            if (preferences == null)
            {
                return null;
            }

            preferences.Theme = request.Theme;
            preferences.Language = request.Language;
            preferences.DateFormat = request.DateFormat;
            preferences.TimeFormat = request.TimeFormat;
            preferences.DefaultModule = request.DefaultModule;
            preferences.AutoSaveEstimates = request.AutoSaveEstimates;
            preferences.AutoSaveIntervalMinutes = request.AutoSaveIntervalMinutes;
            preferences.DefaultTableView = request.DefaultTableView;
            preferences.DefaultPageSize = request.DefaultPageSize;
            preferences.DefaultCardsPerRow = request.DefaultCardsPerRow;
            preferences.EmailNotifications = request.EmailNotifications;
            preferences.EmailMentions = request.EmailMentions;
            preferences.EmailComments = request.EmailComments;
            preferences.ShowNotificationBadge = request.ShowNotificationBadge;
            preferences.PlayNotificationSound = request.PlayNotificationSound;
            preferences.DesktopNotifications = request.DesktopNotifications;
            preferences.ShowDashboardWidgets = request.ShowDashboardWidgets;
            preferences.DashboardLayout = request.DashboardLayout;
            preferences.ShowOnlineStatus = request.ShowOnlineStatus;
            preferences.ShowLastSeen = request.ShowLastSeen;
            preferences.UpdatedAt = DateTime.UtcNow;

            await context.SaveChangesAsync();
            
            _logger.LogInformation("Updated preferences for user {UserId}", userId);
            return preferences;
        }

        public async Task<bool> ResetUserPreferencesAsync(int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var preferences = await GetUserPreferencesAsync(userId);
            if (preferences == null)
            {
                return false;
            }

            // Reset to defaults
            preferences.Theme = "light";
            preferences.Language = "en";
            preferences.DateFormat = "MM/dd/yyyy";
            preferences.TimeFormat = "12h";
            preferences.DefaultModule = "Estimate";
            preferences.AutoSaveEstimates = true;
            preferences.AutoSaveIntervalMinutes = 5;
            preferences.DefaultTableView = "table";
            preferences.DefaultPageSize = 10;
            preferences.DefaultCardsPerRow = 3;
            preferences.EmailNotifications = true;
            preferences.EmailMentions = true;
            preferences.EmailComments = true;
            preferences.ShowNotificationBadge = true;
            preferences.PlayNotificationSound = false;
            preferences.DesktopNotifications = false;
            preferences.ShowDashboardWidgets = true;
            preferences.DashboardLayout = null;
            preferences.ShowOnlineStatus = true;
            preferences.ShowLastSeen = true;
            preferences.UpdatedAt = DateTime.UtcNow;

            await context.SaveChangesAsync();
            
            _logger.LogInformation("Reset preferences for user {UserId}", userId);
            return true;
        }

        public async Task<bool> UpdateModulePreferencesAsync(int userId, string moduleName, string preferencesJson)
        {
            // TODO: Implement module-specific preferences storage
            // This could be stored in a separate table or as JSON in UserPreferences
            await Task.CompletedTask;
            return true;
        }

        public async Task<string?> GetModulePreferencesAsync(int userId, string moduleName)
        {
            // TODO: Implement module-specific preferences retrieval
            await Task.CompletedTask;
            return null;
        }
    }
}