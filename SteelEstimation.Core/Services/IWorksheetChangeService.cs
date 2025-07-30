using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Services
{
    public interface IWorksheetChangeService
    {
        Task RecordChangeAsync(WorksheetChange change);
        Task<WorksheetChange?> GetLastChangeAsync(int worksheetId, int userId);
        Task<bool> UndoAsync(int worksheetId, int userId);
        Task<bool> RedoAsync(int worksheetId, int userId);
        Task<List<WorksheetChange>> GetRecentChangesAsync(int worksheetId, int count = 10);
    }
}