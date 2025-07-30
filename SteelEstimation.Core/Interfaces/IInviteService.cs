using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using SteelEstimation.Core.DTOs;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Interfaces
{
    public interface IInviteService
    {
        Task<InviteResult> CreateInviteAsync(CreateInviteRequest request, int invitedByUserId);
        Task<InviteResult> ResendInviteAsync(int inviteId, int requestedByUserId);
        Task<InviteResult> AcceptInviteAsync(string token, string password);
        Task<bool> RevokeInviteAsync(int inviteId, int requestedByUserId);
        Task<Invite?> GetInviteByTokenAsync(string token);
        Task<IEnumerable<Invite>> GetInvitesAsync(bool includeUsed = false);
        Task<IEnumerable<Invite>> GetInvitesByUserAsync(int userId);
        Task<bool> IsEmailInvitedAsync(string email);
        Task CleanupExpiredInvitesAsync();
    }
}