using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Services;

public interface ITimeTrackingService
{
    Task<EstimationTimeLog> StartSessionAsync(int estimationId, int userId, string? pageName = null);
    Task<EstimationTimeLog?> GetActiveSessionAsync(int estimationId, int userId);
    Task EndSessionAsync(int sessionId);
    Task PauseSessionAsync(int estimationId, int userId);
    Task ResumeSessionAsync(int estimationId, int userId);
    Task<TimeSpan> GetTotalTimeAsync(int estimationId, int? userId = null);
    Task<TimeSpan> GetSessionTimeAsync(Guid sessionId);
    Task<Dictionary<int, TimeSpan>> GetTimeByUserAsync(int estimationId);
    Task<List<EstimationTimeLog>> GetTimeLogsAsync(int estimationId, DateTime? startDate = null, DateTime? endDate = null);
}