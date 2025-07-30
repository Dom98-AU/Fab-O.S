using SteelEstimation.Core.DTOs;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Interfaces;

public interface IProjectService
{
    Task<IEnumerable<ProjectDto>> GetUserProjectsAsync(int userId);
    Task<ProjectDto?> GetProjectAsync(int projectId, int userId);
    Task<ProjectDto> CreateProjectAsync(CreateProjectRequest request, int userId);
    Task<ProjectDto> UpdateProjectAsync(int projectId, UpdateProjectRequest request, int userId);
    Task<bool> DeleteProjectAsync(int projectId, int userId);
    Task<bool> GrantProjectAccessAsync(int projectId, int targetUserId, string accessLevel, int grantedByUserId);
    Task<bool> RevokeProjectAccessAsync(int projectId, int targetUserId, int revokedByUserId);
    Task<IEnumerable<ProjectUserDto>> GetProjectUsersAsync(int projectId, int requestingUserId);
}