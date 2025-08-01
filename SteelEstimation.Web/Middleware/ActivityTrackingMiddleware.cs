using Microsoft.AspNetCore.Http;
using SteelEstimation.Core.Interfaces;
using System.Security.Claims;

namespace SteelEstimation.Web.Middleware
{
    public class ActivityTrackingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly ILogger<ActivityTrackingMiddleware> _logger;

        public ActivityTrackingMiddleware(RequestDelegate next, ILogger<ActivityTrackingMiddleware> logger)
        {
            _next = next;
            _logger = logger;
        }

        public async Task InvokeAsync(HttpContext context, IServiceProvider serviceProvider)
        {
            await _next(context);

            // Only track activities for authenticated users and successful responses
            if (context.User.Identity?.IsAuthenticated == true && 
                context.Response.StatusCode >= 200 && 
                context.Response.StatusCode < 300)
            {
                try
                {
                    using (var scope = serviceProvider.CreateScope())
                    {
                        var activityService = scope.ServiceProvider.GetRequiredService<IUserActivityService>();
                        await TrackActivityAsync(context, activityService);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error tracking user activity");
                }
            }
        }

        private async Task TrackActivityAsync(HttpContext context, IUserActivityService activityService)
        {
            var path = context.Request.Path.Value?.ToLower() ?? "";
            var method = context.Request.Method;
            var userIdClaim = context.User.FindFirst("UserId")?.Value 
                            ?? context.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (!int.TryParse(userIdClaim, out var userId))
                return;

            // Determine activity type based on path and method
            string? activityType = null;
            string? entityType = null;
            int? entityId = null;
            string? details = null;

            // Parse path to determine activity
            if (path.StartsWith("/estimation") && method == "POST")
            {
                activityType = "created";
                entityType = "Estimation";
                details = "Created new estimation";
            }
            else if (path.StartsWith("/estimation") && path.Contains("/edit") && method == "POST")
            {
                activityType = "updated";
                entityType = "Estimation";
                details = "Updated estimation";
                
                // Try to extract ID from path
                var segments = path.Split('/');
                for (int i = 0; i < segments.Length - 1; i++)
                {
                    if (segments[i] == "estimation" && int.TryParse(segments[i + 1], out var id))
                    {
                        entityId = id;
                        break;
                    }
                }
            }
            else if (path.Contains("/worksheet") && method == "POST")
            {
                activityType = path.Contains("/create") ? "created" : "updated";
                entityType = "Worksheet";
                details = $"{activityType} worksheet";
            }
            else if (path.Contains("/customers") && method == "POST")
            {
                activityType = path.Contains("/create") ? "created" : "updated";
                entityType = "Customer";
                details = $"{activityType} customer";
            }
            else if (path == "/profile" || path.StartsWith("/profile/"))
            {
                activityType = "viewed";
                entityType = "Profile";
                details = "Viewed profile";
            }
            else if (path.Contains("/notifications"))
            {
                activityType = "viewed";
                entityType = "Notification";
                details = "Viewed notifications";
            }

            // Log the activity if we determined a type
            if (!string.IsNullOrEmpty(activityType))
            {
                var request = new SteelEstimation.Core.DTOs.LogActivityRequest
                {
                    UserId = userId,
                    ActivityType = activityType,
                    EntityType = entityType,
                    EntityId = entityId,
                    Description = details,
                    ProductName = "SteelEstimation",
                    IpAddress = context.Connection.RemoteIpAddress?.ToString(),
                    UserAgent = context.Request.Headers["User-Agent"].ToString()
                };
                await activityService.LogActivityAsync(request);
            }
        }
    }

    public static class ActivityTrackingMiddlewareExtensions
    {
        public static IApplicationBuilder UseActivityTracking(this IApplicationBuilder builder)
        {
            return builder.UseMiddleware<ActivityTrackingMiddleware>();
        }
    }
}