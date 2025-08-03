using System.Collections.Generic;
using System.Threading.Tasks;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Interfaces
{
    public interface IAvatarHistoryService
    {
        Task<AvatarHistory> SaveAvatarToHistoryAsync(int userId, string? avatarUrl, string? avatarType, 
            string? diceBearStyle, string? diceBearSeed, string? diceBearOptions, string changeReason = "user_change");
        
        Task<IEnumerable<AvatarHistory>> GetAvatarHistoryAsync(int userId, int limit = 10);
        
        Task<AvatarHistory?> GetCurrentAvatarHistoryAsync(int userId);
        
        Task<bool> RollbackToAvatarAsync(int userId, int historyId);
        
        Task<bool> DeleteAvatarHistoryAsync(int userId, int historyId);
        
        Task<int> CleanupOldHistoryAsync(int userId, int keepCount = 10);
    }
}