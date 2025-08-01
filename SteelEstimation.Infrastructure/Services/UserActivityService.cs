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
    public class UserActivityService : IUserActivityService
    {
        private readonly IDbContextFactory<ApplicationDbContext> _contextFactory;
        private readonly ILogger<UserActivityService> _logger;

        public UserActivityService(IDbContextFactory<ApplicationDbContext> contextFactory, ILogger<UserActivityService> logger)
        {
            _contextFactory = contextFactory;
            _logger = logger;
        }

        public async Task LogActivityAsync(LogActivityRequest request)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            var activity = new UserActivity
            {
                UserId = request.UserId,
                ActivityType = request.ActivityType,
                Description = request.Description,
                EntityType = request.EntityType,
                EntityId = request.EntityId,
                ProductName = request.ProductName,
                Metadata = request.Metadata,
                IpAddress = request.IpAddress,
                UserAgent = request.UserAgent,
                CreatedAt = DateTime.UtcNow
            };

            context.UserActivities.Add(activity);
            await context.SaveChangesAsync();

            // Update user's last activity
            var userProfile = await context.UserProfiles.FirstOrDefaultAsync(p => p.UserId == request.UserId);
            if (userProfile != null)
            {
                userProfile.LastActivityAt = DateTime.UtcNow;
                await context.SaveChangesAsync();
            }
        }

        public async Task LogUserLoginAsync(int userId, string productName, string? ipAddress = null, string? userAgent = null)
        {
            await LogActivityAsync(new LogActivityRequest
            {
                UserId = userId,
                ActivityType = "user_login",
                Description = $"Logged in to {productName}",
                ProductName = productName,
                IpAddress = ipAddress,
                UserAgent = userAgent
            });
        }

        public async Task LogUserLogoutAsync(int userId, string productName)
        {
            await LogActivityAsync(new LogActivityRequest
            {
                UserId = userId,
                ActivityType = "user_logout",
                Description = $"Logged out from {productName}",
                ProductName = productName
            });
        }

        public async Task LogEntityCreatedAsync(int userId, string productName, string entityType, int entityId, string description)
        {
            await LogActivityAsync(new LogActivityRequest
            {
                UserId = userId,
                ActivityType = $"{entityType.ToLower()}_created",
                Description = description,
                EntityType = entityType,
                EntityId = entityId,
                ProductName = productName
            });
        }

        public async Task LogEntityUpdatedAsync(int userId, string productName, string entityType, int entityId, string description)
        {
            await LogActivityAsync(new LogActivityRequest
            {
                UserId = userId,
                ActivityType = $"{entityType.ToLower()}_updated",
                Description = description,
                EntityType = entityType,
                EntityId = entityId,
                ProductName = productName
            });
        }

        public async Task LogEntityDeletedAsync(int userId, string productName, string entityType, int entityId, string description)
        {
            await LogActivityAsync(new LogActivityRequest
            {
                UserId = userId,
                ActivityType = $"{entityType.ToLower()}_deleted",
                Description = description,
                EntityType = entityType,
                EntityId = entityId,
                ProductName = productName
            });
        }

        public async Task LogCommentActivityAsync(int userId, string productName, Comment comment, string action)
        {
            await LogActivityAsync(new LogActivityRequest
            {
                UserId = userId,
                ActivityType = $"comment_{action}",
                Description = $"{action} comment on {comment.EntityType} #{comment.EntityId}",
                EntityType = "Comment",
                EntityId = comment.Id,
                ProductName = productName
            });
        }

        public async Task<IEnumerable<UserActivity>> GetUserActivitiesAsync(int userId, int pageNumber = 1, int pageSize = 50)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            var skip = (pageNumber - 1) * pageSize;

            return await context.UserActivities
                .Include(a => a.User)
                .Where(a => a.UserId == userId)
                .OrderByDescending(a => a.CreatedAt)
                .Skip(skip)
                .Take(pageSize)
                .ToListAsync();
        }

        public async Task<IEnumerable<UserActivity>> GetProductActivitiesAsync(string productName, int pageNumber = 1, int pageSize = 50)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            var skip = (pageNumber - 1) * pageSize;

            return await context.UserActivities
                .Include(a => a.User)
                .Where(a => a.ProductName == productName)
                .OrderByDescending(a => a.CreatedAt)
                .Skip(skip)
                .Take(pageSize)
                .ToListAsync();
        }

        public async Task<IEnumerable<UserActivity>> GetCompanyActivitiesAsync(int companyId, int pageNumber = 1, int pageSize = 50)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            var skip = (pageNumber - 1) * pageSize;

            return await context.UserActivities
                .Include(a => a.User)
                .Where(a => a.User.CompanyId == companyId)
                .OrderByDescending(a => a.CreatedAt)
                .Skip(skip)
                .Take(pageSize)
                .ToListAsync();
        }

        public async Task<IEnumerable<UserActivity>> GetEntityActivitiesAsync(string entityType, int entityId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            return await context.UserActivities
                .Include(a => a.User)
                .Where(a => a.EntityType == entityType && a.EntityId == entityId)
                .OrderByDescending(a => a.CreatedAt)
                .ToListAsync();
        }

        public async Task<IEnumerable<UserActivity>> GetRecentActivitiesAsync(int companyId, int hours = 24)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            var startDate = DateTime.UtcNow.AddHours(-hours);

            return await context.UserActivities
                .Include(a => a.User)
                .Where(a => a.User.CompanyId == companyId && a.CreatedAt >= startDate)
                .OrderByDescending(a => a.CreatedAt)
                .Take(100)
                .ToListAsync();
        }

        public async Task<Dictionary<string, int>> GetActivitySummaryAsync(int userId, DateTime startDate, DateTime endDate)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            var activities = await context.UserActivities
                .Where(a => a.UserId == userId && a.CreatedAt >= startDate && a.CreatedAt <= endDate)
                .GroupBy(a => a.ActivityType)
                .Select(g => new { Type = g.Key, Count = g.Count() })
                .ToListAsync();

            return activities.ToDictionary(a => a.Type, a => a.Count);
        }

        public async Task<Dictionary<string, int>> GetProductUsageStatsAsync(string productName, DateTime startDate, DateTime endDate)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            var activities = await context.UserActivities
                .Where(a => a.ProductName == productName && a.CreatedAt >= startDate && a.CreatedAt <= endDate)
                .GroupBy(a => a.ActivityType)
                .Select(g => new { Type = g.Key, Count = g.Count() })
                .ToListAsync();

            return activities.ToDictionary(a => a.Type, a => a.Count);
        }

        public async Task<IEnumerable<UserActivitySummary>> GetTopActiveUsersAsync(int companyId, string? productName = null, int days = 30, int topCount = 10)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            var startDate = DateTime.UtcNow.AddDays(-days);

            var query = context.UserActivities
                .Include(a => a.User)
                .ThenInclude(u => u.Profile)
                .Where(a => a.User.CompanyId == companyId && a.CreatedAt >= startDate);

            if (!string.IsNullOrEmpty(productName))
            {
                query = query.Where(a => a.ProductName == productName);
            }

            var userActivities = await query
                .GroupBy(a => new { a.UserId, a.User.Username, a.User.FirstName, a.User.LastName })
                .Select(g => new
                {
                    UserId = g.Key.UserId,
                    Username = g.Key.Username,
                    FirstName = g.Key.FirstName,
                    LastName = g.Key.LastName,
                    TotalActivities = g.Count(),
                    LastActivity = g.Max(a => a.CreatedAt),
                    Activities = g.ToList()
                })
                .OrderByDescending(u => u.TotalActivities)
                .Take(topCount)
                .ToListAsync();

            var summaries = new List<UserActivitySummary>();

            foreach (var userActivity in userActivities)
            {
                var user = await context.Users
                    .Include(u => u.Profile)
                    .FirstOrDefaultAsync(u => u.Id == userActivity.UserId);

                var summary = new UserActivitySummary
                {
                    UserId = userActivity.UserId,
                    Username = userActivity.Username,
                    UserFullName = $"{userActivity.FirstName} {userActivity.LastName}".Trim(),
                    UserAvatarUrl = user?.Profile?.AvatarUrl,
                    TotalActivities = userActivity.TotalActivities,
                    LastActivityAt = userActivity.LastActivity,
                    ActivitiesByType = userActivity.Activities
                        .GroupBy(a => a.ActivityType)
                        .ToDictionary(g => g.Key, g => g.Count()),
                    ActivitiesByProduct = userActivity.Activities
                        .GroupBy(a => a.ProductName)
                        .ToDictionary(g => g.Key, g => g.Count())
                };

                summaries.Add(summary);
            }

            return summaries;
        }

        public async Task<Dictionary<DateTime, int>> GetActivityTimelineAsync(int companyId, string? productName = null, int days = 30)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            var startDate = DateTime.UtcNow.AddDays(-days).Date;

            var query = context.UserActivities
                .Where(a => a.User.CompanyId == companyId && a.CreatedAt >= startDate);

            if (!string.IsNullOrEmpty(productName))
            {
                query = query.Where(a => a.ProductName == productName);
            }

            var activities = await query
                .GroupBy(a => a.CreatedAt.Date)
                .Select(g => new { Date = g.Key, Count = g.Count() })
                .OrderBy(a => a.Date)
                .ToListAsync();

            return activities.ToDictionary(a => a.Date, a => a.Count);
        }

        public async Task<int> CleanupOldActivitiesAsync(int daysToKeep = 90)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            var cutoffDate = DateTime.UtcNow.AddDays(-daysToKeep);

            var oldActivities = await context.UserActivities
                .Where(a => a.CreatedAt < cutoffDate)
                .ToListAsync();

            if (!oldActivities.Any())
            {
                return 0;
            }

            context.UserActivities.RemoveRange(oldActivities);
            await context.SaveChangesAsync();

            _logger.LogInformation("Cleaned up {Count} old activities", oldActivities.Count);
            return oldActivities.Count;
        }

        public async Task<bool> DeleteUserActivitiesAsync(int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            var activities = await context.UserActivities
                .Where(a => a.UserId == userId)
                .ToListAsync();

            if (!activities.Any())
            {
                return false;
            }

            context.UserActivities.RemoveRange(activities);
            await context.SaveChangesAsync();

            _logger.LogInformation("Deleted all activities for user {UserId}", userId);
            return true;
        }
    }
}