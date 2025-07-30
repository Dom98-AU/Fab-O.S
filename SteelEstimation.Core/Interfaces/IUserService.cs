using System.Collections.Generic;
using System.Threading.Tasks;
using SteelEstimation.Core.DTOs;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Interfaces
{
    public interface IUserService
    {
        // User CRUD operations
        Task<User?> GetUserByIdAsync(int userId);
        Task<User?> GetUserByUsernameAsync(string username);
        Task<User?> GetUserByEmailAsync(string email);
        Task<IEnumerable<User>> GetAllUsersAsync();
        Task<IEnumerable<User>> GetActiveUsersAsync();
        Task<User> CreateUserAsync(CreateUserRequest request);
        Task<User?> UpdateUserAsync(int userId, UpdateUserRequest request);
        Task<bool> DeleteUserAsync(int userId);
        Task<bool> DeactivateUserAsync(int userId);
        Task<bool> ActivateUserAsync(int userId);

        // Role management
        Task<bool> AssignRoleAsync(int userId, string roleName, int assignedByUserId);
        Task<bool> RemoveRoleAsync(int userId, string roleName);
        Task<IEnumerable<Role>> GetUserRolesAsync(int userId);
        Task<IEnumerable<Role>> GetAllRolesAsync();
        
        // User queries
        Task<IEnumerable<User>> SearchUsersAsync(string searchTerm);
        Task<int> GetActiveUserCountAsync();
        Task<IEnumerable<User>> GetUsersInRoleAsync(string roleName);
        Task<bool> IsEmailUniqueAsync(string email, int? excludeUserId = null);
        Task<bool> IsUsernameUniqueAsync(string username, int? excludeUserId = null);
        
        // Account management
        Task<bool> UnlockUserAsync(int userId);
        Task<bool> ResetFailedLoginAttemptsAsync(int userId);
        Task<bool> UpdateLastLoginAsync(int userId);
    }
}