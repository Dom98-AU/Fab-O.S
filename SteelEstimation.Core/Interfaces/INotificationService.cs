using System;
using System.Threading.Tasks;
using SteelEstimation.Core.DTOs;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Interfaces
{
    public interface INotificationService
    {
        // Notification creation
        Task<Notification> CreateNotificationAsync(CreateNotificationRequest request);
        Task<bool> CreateBulkNotificationsAsync(IEnumerable<CreateNotificationRequest> requests);
        Task<Notification> CreateMentionNotificationAsync(int mentionedUserId, int fromUserId, Comment comment);
        Task<Notification> CreateCommentNotificationAsync(int userId, int fromUserId, Comment comment);
        Task<Notification> CreateSystemNotificationAsync(int userId, string title, string message, string priority = "normal");
        
        // Notification queries
        Task<Notification?> GetNotificationAsync(int notificationId);
        Task<IEnumerable<Notification>> GetUserNotificationsAsync(int userId, bool unreadOnly = false, int pageNumber = 1, int pageSize = 50);
        Task<IEnumerable<Notification>> GetNotificationsByTypeAsync(int userId, string type, int pageNumber = 1, int pageSize = 50);
        Task<IEnumerable<Notification>> GetProductNotificationsAsync(int userId, string productName, bool unreadOnly = false);
        Task<int> GetUnreadCountAsync(int userId);
        Task<Dictionary<string, int>> GetUnreadCountByTypeAsync(int userId);
        
        // Notification management
        Task<bool> MarkAsReadAsync(int notificationId, int userId);
        Task<bool> MarkAllAsReadAsync(int userId);
        Task<bool> MarkTypeAsReadAsync(int userId, string type);
        Task<bool> ArchiveNotificationAsync(int notificationId, int userId);
        Task<bool> ArchiveAllReadAsync(int userId);
        Task<bool> DeleteNotificationAsync(int notificationId, int userId);
        Task<bool> DeleteExpiredNotificationsAsync();
        
        // Real-time notifications (SignalR integration)
        Task SendRealTimeNotificationAsync(int userId, Notification notification);
        Task SendRealTimeNotificationToGroupAsync(string groupName, Notification notification);
        
        // Notification preferences
        Task<bool> ShouldSendNotificationAsync(int userId, string notificationType);
        Task<bool> SendEmailNotificationAsync(int userId, Notification notification);
    }
}