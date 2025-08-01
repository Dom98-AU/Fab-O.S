using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using SteelEstimation.Core.Interfaces;
using System.Security.Claims;

namespace SteelEstimation.Web.Hubs
{
    [Authorize]
    public class NotificationHub : Hub
    {
        private readonly INotificationService _notificationService;
        private readonly IFabOSAuthenticationService _authService;
        private static readonly Dictionary<int, HashSet<string>> _userConnections = new();

        public NotificationHub(INotificationService notificationService, IFabOSAuthenticationService authService)
        {
            _notificationService = notificationService;
            _authService = authService;
        }

        public override async Task OnConnectedAsync()
        {
            var userId = GetUserId();
            if (userId.HasValue)
            {
                lock (_userConnections)
                {
                    if (!_userConnections.ContainsKey(userId.Value))
                    {
                        _userConnections[userId.Value] = new HashSet<string>();
                    }
                    _userConnections[userId.Value].Add(Context.ConnectionId);
                }

                // Send unread count on connection
                var unreadCount = await _notificationService.GetUnreadCountAsync(userId.Value);
                await Clients.Caller.SendAsync("UpdateUnreadCount", unreadCount);
            }

            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var userId = GetUserId();
            if (userId.HasValue)
            {
                lock (_userConnections)
                {
                    if (_userConnections.ContainsKey(userId.Value))
                    {
                        _userConnections[userId.Value].Remove(Context.ConnectionId);
                        if (_userConnections[userId.Value].Count == 0)
                        {
                            _userConnections.Remove(userId.Value);
                        }
                    }
                }
            }

            await base.OnDisconnectedAsync(exception);
        }

        public async Task MarkAsRead(int notificationId)
        {
            var userId = GetUserId();
            if (userId.HasValue)
            {
                await _notificationService.MarkAsReadAsync(notificationId, userId.Value);
                var unreadCount = await _notificationService.GetUnreadCountAsync(userId.Value);
                await Clients.Caller.SendAsync("UpdateUnreadCount", unreadCount);
            }
        }

        public async Task MarkAllAsRead()
        {
            var userId = GetUserId();
            if (userId.HasValue)
            {
                await _notificationService.MarkAllAsReadAsync(userId.Value);
                await Clients.Caller.SendAsync("UpdateUnreadCount", 0);
            }
        }

        public static async Task SendNotificationToUser(IHubContext<NotificationHub> hubContext, int userId, object notification)
        {
            if (_userConnections.ContainsKey(userId))
            {
                var connectionIds = _userConnections[userId].ToList();
                await hubContext.Clients.Clients(connectionIds).SendAsync("ReceiveNotification", notification);
            }
        }

        public static async Task UpdateUnreadCountForUser(IHubContext<NotificationHub> hubContext, int userId, int unreadCount)
        {
            if (_userConnections.ContainsKey(userId))
            {
                var connectionIds = _userConnections[userId].ToList();
                await hubContext.Clients.Clients(connectionIds).SendAsync("UpdateUnreadCount", unreadCount);
            }
        }

        private int? GetUserId()
        {
            var userIdClaim = Context.User?.FindFirst("UserId")?.Value 
                            ?? Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            if (int.TryParse(userIdClaim, out var userId))
            {
                return userId;
            }

            return null;
        }
    }
}