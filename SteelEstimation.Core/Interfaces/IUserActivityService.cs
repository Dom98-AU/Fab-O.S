using System;
using System.Threading.Tasks;
using SteelEstimation.Core.DTOs;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Interfaces
{
    public interface IUserActivityService
    {
        // Activity logging
        Task LogActivityAsync(LogActivityRequest request);
        Task LogUserLoginAsync(int userId, string productName, string? ipAddress = null, string? userAgent = null);
        Task LogUserLogoutAsync(int userId, string productName);
        Task LogEntityCreatedAsync(int userId, string productName, string entityType, int entityId, string description);
        Task LogEntityUpdatedAsync(int userId, string productName, string entityType, int entityId, string description);
        Task LogEntityDeletedAsync(int userId, string productName, string entityType, int entityId, string description);
        Task LogCommentActivityAsync(int userId, string productName, Comment comment, string action);
        
        // Activity queries
        Task<IEnumerable<UserActivity>> GetUserActivitiesAsync(int userId, int pageNumber = 1, int pageSize = 50);
        Task<IEnumerable<UserActivity>> GetProductActivitiesAsync(string productName, int pageNumber = 1, int pageSize = 50);
        Task<IEnumerable<UserActivity>> GetCompanyActivitiesAsync(int companyId, int pageNumber = 1, int pageSize = 50);
        Task<IEnumerable<UserActivity>> GetEntityActivitiesAsync(string entityType, int entityId);
        Task<IEnumerable<UserActivity>> GetRecentActivitiesAsync(int companyId, int hours = 24);
        
        // Activity analytics
        Task<Dictionary<string, int>> GetActivitySummaryAsync(int userId, DateTime startDate, DateTime endDate);
        Task<Dictionary<string, int>> GetProductUsageStatsAsync(string productName, DateTime startDate, DateTime endDate);
        Task<IEnumerable<UserActivitySummary>> GetTopActiveUsersAsync(int companyId, string? productName = null, int days = 30, int topCount = 10);
        Task<Dictionary<DateTime, int>> GetActivityTimelineAsync(int companyId, string? productName = null, int days = 30);
        
        // Activity cleanup
        Task<int> CleanupOldActivitiesAsync(int daysToKeep = 90);
        Task<bool> DeleteUserActivitiesAsync(int userId);
    }
}