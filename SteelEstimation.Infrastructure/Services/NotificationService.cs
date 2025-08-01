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
    public class NotificationService : INotificationService
    {
        private readonly IDbContextFactory<ApplicationDbContext> _contextFactory;
        private readonly ILogger<NotificationService> _logger;

        public NotificationService(IDbContextFactory<ApplicationDbContext> contextFactory, ILogger<NotificationService> logger)
        {
            _contextFactory = contextFactory;
            _logger = logger;
        }

        public async Task<Notification> CreateNotificationAsync(CreateNotificationRequest request)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var notification = new Notification
            {
                UserId = request.UserId,
                Type = request.Type,
                Title = request.Title,
                Message = request.Message,
                EntityType = request.EntityType,
                EntityId = request.EntityId,
                ProductName = request.ProductName,
                ActionUrl = request.ActionUrl,
                Priority = request.Priority,
                FromUserId = request.FromUserId,
                ExpiresAt = request.ExpiresAt,
                CreatedAt = DateTime.UtcNow
            };

            context.Notifications.Add(notification);
            await context.SaveChangesAsync();

            _logger.LogInformation("Created notification {NotificationId} for user {UserId}", notification.Id, request.UserId);
            
            // Send real-time notification if implemented
            await SendRealTimeNotificationAsync(request.UserId, notification);
            
            return notification;
        }

        public async Task<bool> CreateBulkNotificationsAsync(IEnumerable<CreateNotificationRequest> requests)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var notifications = requests.Select(request => new Notification
            {
                UserId = request.UserId,
                Type = request.Type,
                Title = request.Title,
                Message = request.Message,
                EntityType = request.EntityType,
                EntityId = request.EntityId,
                ProductName = request.ProductName,
                ActionUrl = request.ActionUrl,
                Priority = request.Priority,
                FromUserId = request.FromUserId,
                ExpiresAt = request.ExpiresAt,
                CreatedAt = DateTime.UtcNow
            }).ToList();

            context.Notifications.AddRange(notifications);
            await context.SaveChangesAsync();

            _logger.LogInformation("Created {Count} bulk notifications", notifications.Count);
            return true;
        }

        public async Task<Notification> CreateMentionNotificationAsync(int mentionedUserId, int fromUserId, Comment comment)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var fromUser = await context.Users.FindAsync(fromUserId);
            var title = $"{fromUser?.FullName ?? "Someone"} mentioned you in a comment";
            
            var request = new CreateNotificationRequest
            {
                UserId = mentionedUserId,
                Type = "mention",
                Title = title,
                Message = comment.Content.Length > 100 ? comment.Content.Substring(0, 100) + "..." : comment.Content,
                EntityType = comment.EntityType,
                EntityId = comment.EntityId,
                ProductName = comment.ProductName,
                ActionUrl = $"/{comment.EntityType.ToLower()}/{comment.EntityId}#comment-{comment.Id}",
                Priority = "high",
                FromUserId = fromUserId
            };

            return await CreateNotificationAsync(request);
        }

        public async Task<Notification> CreateCommentNotificationAsync(int userId, int fromUserId, Comment comment)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var fromUser = await context.Users.FindAsync(fromUserId);
            var title = $"{fromUser?.FullName ?? "Someone"} commented on your {comment.EntityType.ToLower()}";
            
            var request = new CreateNotificationRequest
            {
                UserId = userId,
                Type = "comment",
                Title = title,
                Message = comment.Content.Length > 100 ? comment.Content.Substring(0, 100) + "..." : comment.Content,
                EntityType = comment.EntityType,
                EntityId = comment.EntityId,
                ProductName = comment.ProductName,
                ActionUrl = $"/{comment.EntityType.ToLower()}/{comment.EntityId}#comment-{comment.Id}",
                Priority = "normal",
                FromUserId = fromUserId
            };

            return await CreateNotificationAsync(request);
        }

        public async Task<Notification> CreateSystemNotificationAsync(int userId, string title, string message, string priority = "normal")
        {
            var request = new CreateNotificationRequest
            {
                UserId = userId,
                Type = "system",
                Title = title,
                Message = message,
                Priority = priority
            };

            return await CreateNotificationAsync(request);
        }

        public async Task<Notification?> GetNotificationAsync(int notificationId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            return await context.Notifications
                .Include(n => n.User)
                .Include(n => n.FromUser)
                .FirstOrDefaultAsync(n => n.Id == notificationId);
        }

        public async Task<IEnumerable<Notification>> GetUserNotificationsAsync(int userId, bool unreadOnly = false, int pageNumber = 1, int pageSize = 50)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var skip = (pageNumber - 1) * pageSize;
            
            var query = context.Notifications
                .Include(n => n.FromUser)
                .Where(n => n.UserId == userId && !n.IsArchived);

            if (unreadOnly)
            {
                query = query.Where(n => !n.IsRead);
            }

            return await query
                .OrderByDescending(n => n.CreatedAt)
                .Skip(skip)
                .Take(pageSize)
                .ToListAsync();
        }

        public async Task<IEnumerable<Notification>> GetNotificationsByTypeAsync(int userId, string type, int pageNumber = 1, int pageSize = 50)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var skip = (pageNumber - 1) * pageSize;
            
            return await context.Notifications
                .Include(n => n.FromUser)
                .Where(n => n.UserId == userId && n.Type == type && !n.IsArchived)
                .OrderByDescending(n => n.CreatedAt)
                .Skip(skip)
                .Take(pageSize)
                .ToListAsync();
        }

        public async Task<IEnumerable<Notification>> GetProductNotificationsAsync(int userId, string productName, bool unreadOnly = false)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var query = context.Notifications
                .Include(n => n.FromUser)
                .Where(n => n.UserId == userId && n.ProductName == productName && !n.IsArchived);

            if (unreadOnly)
            {
                query = query.Where(n => !n.IsRead);
            }

            return await query
                .OrderByDescending(n => n.CreatedAt)
                .Take(100)
                .ToListAsync();
        }

        public async Task<int> GetUnreadCountAsync(int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            return await context.Notifications
                .CountAsync(n => n.UserId == userId && !n.IsRead && !n.IsArchived);
        }

        public async Task<Dictionary<string, int>> GetUnreadCountByTypeAsync(int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var counts = await context.Notifications
                .Where(n => n.UserId == userId && !n.IsRead && !n.IsArchived)
                .GroupBy(n => n.Type)
                .Select(g => new { Type = g.Key, Count = g.Count() })
                .ToListAsync();

            return counts.ToDictionary(c => c.Type, c => c.Count);
        }

        public async Task<bool> MarkAsReadAsync(int notificationId, int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var notification = await context.Notifications
                .FirstOrDefaultAsync(n => n.Id == notificationId && n.UserId == userId);

            if (notification == null || notification.IsRead)
            {
                return false;
            }

            notification.IsRead = true;
            notification.ReadAt = DateTime.UtcNow;

            await context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> MarkAllAsReadAsync(int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var notifications = await context.Notifications
                .Where(n => n.UserId == userId && !n.IsRead && !n.IsArchived)
                .ToListAsync();

            if (!notifications.Any())
            {
                return false;
            }

            foreach (var notification in notifications)
            {
                notification.IsRead = true;
                notification.ReadAt = DateTime.UtcNow;
            }

            await context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> MarkTypeAsReadAsync(int userId, string type)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var notifications = await context.Notifications
                .Where(n => n.UserId == userId && n.Type == type && !n.IsRead && !n.IsArchived)
                .ToListAsync();

            if (!notifications.Any())
            {
                return false;
            }

            foreach (var notification in notifications)
            {
                notification.IsRead = true;
                notification.ReadAt = DateTime.UtcNow;
            }

            await context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> ArchiveNotificationAsync(int notificationId, int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var notification = await context.Notifications
                .FirstOrDefaultAsync(n => n.Id == notificationId && n.UserId == userId);

            if (notification == null || notification.IsArchived)
            {
                return false;
            }

            notification.IsArchived = true;
            notification.ArchivedAt = DateTime.UtcNow;

            await context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> ArchiveAllReadAsync(int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var notifications = await context.Notifications
                .Where(n => n.UserId == userId && n.IsRead && !n.IsArchived)
                .ToListAsync();

            if (!notifications.Any())
            {
                return false;
            }

            foreach (var notification in notifications)
            {
                notification.IsArchived = true;
                notification.ArchivedAt = DateTime.UtcNow;
            }

            await context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> DeleteNotificationAsync(int notificationId, int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var notification = await context.Notifications
                .FirstOrDefaultAsync(n => n.Id == notificationId && n.UserId == userId);

            if (notification == null)
            {
                return false;
            }

            context.Notifications.Remove(notification);
            await context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> DeleteExpiredNotificationsAsync()
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var expiredNotifications = await context.Notifications
                .Where(n => n.ExpiresAt.HasValue && n.ExpiresAt < DateTime.UtcNow)
                .ToListAsync();

            if (!expiredNotifications.Any())
            {
                return false;
            }

            context.Notifications.RemoveRange(expiredNotifications);
            await context.SaveChangesAsync();

            _logger.LogInformation("Deleted {Count} expired notifications", expiredNotifications.Count);
            return true;
        }

        public async Task SendRealTimeNotificationAsync(int userId, Notification notification)
        {
            // TODO: Implement SignalR hub for real-time notifications
            await Task.CompletedTask;
        }

        public async Task SendRealTimeNotificationToGroupAsync(string groupName, Notification notification)
        {
            // TODO: Implement SignalR hub for real-time notifications
            await Task.CompletedTask;
        }

        public async Task<bool> ShouldSendNotificationAsync(int userId, string notificationType)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var preferences = await context.UserPreferences
                .FirstOrDefaultAsync(p => p.UserId == userId);

            if (preferences == null)
            {
                return true; // Default to sending if no preferences set
            }

            return notificationType switch
            {
                "mention" => preferences.EmailMentions,
                "comment" => preferences.EmailComments,
                "invite" => preferences.EmailInvites,
                _ => preferences.EmailNotifications
            };
        }

        public async Task<bool> SendEmailNotificationAsync(int userId, Notification notification)
        {
            // TODO: Implement email service integration
            var shouldSend = await ShouldSendNotificationAsync(userId, notification.Type);
            if (!shouldSend)
            {
                return false;
            }

            // Email sending logic would go here
            await Task.CompletedTask;
            return true;
        }
    }
}