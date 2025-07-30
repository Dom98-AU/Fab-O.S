using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Services;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services;

public class TimeTrackingService : ITimeTrackingService
{
    private readonly IDbContextFactory<ApplicationDbContext> _contextFactory;
    private readonly ILogger<TimeTrackingService> _logger;

    public TimeTrackingService(IDbContextFactory<ApplicationDbContext> contextFactory, ILogger<TimeTrackingService> logger)
    {
        _contextFactory = contextFactory;
        _logger = logger;
    }

    public async Task<EstimationTimeLog> StartSessionAsync(int estimationId, int userId, string? pageName = null)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        
        // Validate that the project exists
        var projectExists = await context.Projects.AnyAsync(p => p.Id == estimationId);
        if (!projectExists)
        {
            _logger.LogWarning("Cannot start time tracking session: Project with ID {EstimationId} does not exist", estimationId);
            throw new InvalidOperationException($"Project with ID {estimationId} does not exist");
        }
        
        // End any existing active sessions for this user/estimation
        var activeSessions = await context.EstimationTimeLogs
            .Where(t => t.EstimationId == estimationId && t.UserId == userId && t.IsActive)
            .ToListAsync();

        foreach (var session in activeSessions)
        {
            session.IsActive = false;
            session.EndTime = DateTime.UtcNow;
            session.Duration = (int)(session.EndTime.Value - session.StartTime).TotalSeconds;
        }

        // Create new session
        var newSession = new EstimationTimeLog
        {
            EstimationId = estimationId,
            UserId = userId,
            StartTime = DateTime.UtcNow,
            IsActive = true,
            SessionId = Guid.NewGuid(),
            PageName = pageName,
            Duration = 0
        };

        context.EstimationTimeLogs.Add(newSession);
        await context.SaveChangesAsync();

        _logger.LogInformation("Started time tracking session {SessionId} for user {UserId} on estimation {EstimationId}", 
            newSession.SessionId, userId, estimationId);

        return newSession;
    }

    public async Task<EstimationTimeLog?> GetActiveSessionAsync(int estimationId, int userId)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        return await context.EstimationTimeLogs
            .FirstOrDefaultAsync(t => t.EstimationId == estimationId && t.UserId == userId && t.IsActive);
    }

    public async Task EndSessionAsync(int sessionId)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        var session = await context.EstimationTimeLogs.FindAsync(sessionId);
        if (session != null && session.IsActive)
        {
            session.IsActive = false;
            session.EndTime = DateTime.UtcNow;
            session.Duration = (int)(session.EndTime.Value - session.StartTime).TotalSeconds;
            await context.SaveChangesAsync();

            _logger.LogInformation("Ended time tracking session {SessionId} with duration {Duration} seconds", 
                session.SessionId, session.Duration);
        }
    }

    public async Task PauseSessionAsync(int estimationId, int userId)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        var activeSession = await context.EstimationTimeLogs
            .FirstOrDefaultAsync(t => t.EstimationId == estimationId && t.UserId == userId && t.IsActive);
        
        if (activeSession != null)
        {
            // Calculate duration up to now
            var duration = (int)(DateTime.UtcNow - activeSession.StartTime).TotalSeconds;
            
            // End this segment
            activeSession.IsActive = false;
            activeSession.EndTime = DateTime.UtcNow;
            activeSession.Duration = duration;
            
            await context.SaveChangesAsync();

            _logger.LogInformation("Paused time tracking session {SessionId} for user {UserId}", 
                activeSession.SessionId, userId);
        }
    }

    public async Task ResumeSessionAsync(int estimationId, int userId)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        
        // Get the most recent session for this user/estimation
        var lastSession = await context.EstimationTimeLogs
            .Where(t => t.EstimationId == estimationId && t.UserId == userId)
            .OrderByDescending(t => t.StartTime)
            .FirstOrDefaultAsync();

        // Create a new segment with the same session ID
        var newSegment = new EstimationTimeLog
        {
            EstimationId = estimationId,
            UserId = userId,
            StartTime = DateTime.UtcNow,
            IsActive = true,
            SessionId = lastSession?.SessionId ?? Guid.NewGuid(),
            PageName = lastSession?.PageName,
            Duration = 0
        };

        context.EstimationTimeLogs.Add(newSegment);
        await context.SaveChangesAsync();

        _logger.LogInformation("Resumed time tracking session {SessionId} for user {UserId}", 
            newSegment.SessionId, userId);
    }

    public async Task<TimeSpan> GetTotalTimeAsync(int estimationId, int? userId = null)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        
        var query = context.EstimationTimeLogs
            .Where(t => t.EstimationId == estimationId);

        if (userId.HasValue)
        {
            query = query.Where(t => t.UserId == userId.Value);
        }

        // Get completed segments
        var completedTime = await query
            .Where(t => !t.IsActive)
            .SumAsync(t => t.Duration);

        // Add current active segments
        var activeSessions = await query
            .Where(t => t.IsActive)
            .ToListAsync();

        var activeTime = activeSessions.Sum(s => (int)(DateTime.UtcNow - s.StartTime).TotalSeconds);

        return TimeSpan.FromSeconds(completedTime + activeTime);
    }

    public async Task<TimeSpan> GetSessionTimeAsync(Guid sessionId)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        
        var segments = await context.EstimationTimeLogs
            .Where(t => t.SessionId == sessionId)
            .ToListAsync();

        var totalSeconds = segments.Where(s => !s.IsActive).Sum(s => s.Duration);
        
        // Add active segment time
        var activeSegment = segments.FirstOrDefault(s => s.IsActive);
        if (activeSegment != null)
        {
            totalSeconds += (int)(DateTime.UtcNow - activeSegment.StartTime).TotalSeconds;
        }

        return TimeSpan.FromSeconds(totalSeconds);
    }

    public async Task<Dictionary<int, TimeSpan>> GetTimeByUserAsync(int estimationId)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        
        var timeLogs = await context.EstimationTimeLogs
            .Where(t => t.EstimationId == estimationId)
            .GroupBy(t => t.UserId)
            .Select(g => new
            {
                UserId = g.Key,
                TotalSeconds = g.Where(t => !t.IsActive).Sum(t => t.Duration),
                ActiveSessions = g.Where(t => t.IsActive).ToList()
            })
            .ToListAsync();

        var result = new Dictionary<int, TimeSpan>();
        
        foreach (var userTime in timeLogs)
        {
            var totalSeconds = userTime.TotalSeconds;
            
            // Add active time
            foreach (var activeSession in userTime.ActiveSessions)
            {
                totalSeconds += (int)(DateTime.UtcNow - activeSession.StartTime).TotalSeconds;
            }
            
            result[userTime.UserId] = TimeSpan.FromSeconds(totalSeconds);
        }

        return result;
    }

    public async Task<List<EstimationTimeLog>> GetTimeLogsAsync(int estimationId, DateTime? startDate = null, DateTime? endDate = null)
    {
        using var context = await _contextFactory.CreateDbContextAsync();
        
        var query = context.EstimationTimeLogs
            .Include(t => t.User)
            .Where(t => t.EstimationId == estimationId);

        if (startDate.HasValue)
        {
            query = query.Where(t => t.StartTime >= startDate.Value);
        }

        if (endDate.HasValue)
        {
            query = query.Where(t => t.StartTime <= endDate.Value);
        }

        return await query
            .OrderByDescending(t => t.StartTime)
            .ToListAsync();
    }
}