using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using SteelEstimation.Core.DTOs;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Interfaces;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services
{
    public class InviteService : IInviteService
    {
        private readonly ApplicationDbContext _context;
        private readonly IAuthenticationService _authService;
        private readonly IConfiguration _configuration;
        private readonly ILogger<InviteService> _logger;

        public InviteService(
            ApplicationDbContext context,
            IAuthenticationService authService,
            IConfiguration configuration,
            ILogger<InviteService> logger)
        {
            _context = context;
            _authService = authService;
            _configuration = configuration;
            _logger = logger;
        }

        public async Task<InviteResult> CreateInviteAsync(CreateInviteRequest request, int invitedByUserId)
        {
            try
            {
                // Check if email already exists in users
                if (await _context.Users.AnyAsync(u => u.Email == request.Email))
                {
                    return new InviteResult
                    {
                        Success = false,
                        Message = "A user with this email already exists"
                    };
                }

                // Check if there's already a pending invite
                var existingInvite = await _context.Invites
                    .FirstOrDefaultAsync(i => i.Email == request.Email && !i.IsUsed && i.ExpiryDate > DateTime.UtcNow);

                if (existingInvite != null)
                {
                    return new InviteResult
                    {
                        Success = false,
                        Message = "An active invite already exists for this email"
                    };
                }

                // Verify role exists
                var role = await _context.Roles.FindAsync(request.RoleId);
                if (role == null)
                {
                    return new InviteResult
                    {
                        Success = false,
                        Message = "Invalid role specified"
                    };
                }

                // Create invite
                var invite = new Invite
                {
                    Email = request.Email,
                    FirstName = request.FirstName,
                    LastName = request.LastName,
                    CompanyName = request.CompanyName,
                    JobTitle = request.JobTitle,
                    Token = GenerateSecureToken(),
                    CreatedDate = DateTime.UtcNow,
                    ExpiryDate = DateTime.UtcNow.AddDays(request.ExpiryDays),
                    InvitedByUserId = invitedByUserId,
                    RoleId = request.RoleId,
                    Message = request.Message,
                    SendWelcomeEmail = request.SendWelcomeEmail
                };

                _context.Invites.Add(invite);
                await _context.SaveChangesAsync();

                // Generate invite URL
                var baseUrl = _configuration["Application:BaseUrl"] ?? "https://app-steel-estimation-prod.azurewebsites.net";
                var inviteUrl = $"{baseUrl}/welcome?token={invite.Token}";

                // TODO: Send email if SendWelcomeEmail is true
                if (request.SendWelcomeEmail)
                {
                    _logger.LogInformation("Would send invite email to {Email} with URL: {Url}", request.Email, inviteUrl);
                }

                return new InviteResult
                {
                    Success = true,
                    Message = "Invite created successfully",
                    InviteUrl = inviteUrl,
                    Invite = invite
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating invite for {Email}", request.Email);
                return new InviteResult
                {
                    Success = false,
                    Message = "An error occurred while creating the invite"
                };
            }
        }

        public async Task<InviteResult> ResendInviteAsync(int inviteId, int requestedByUserId)
        {
            try
            {
                var invite = await _context.Invites
                    .Include(i => i.Role)
                    .FirstOrDefaultAsync(i => i.Id == inviteId);

                if (invite == null)
                {
                    return new InviteResult
                    {
                        Success = false,
                        Message = "Invite not found"
                    };
                }

                if (invite.IsUsed)
                {
                    return new InviteResult
                    {
                        Success = false,
                        Message = "This invite has already been used"
                    };
                }

                // Extend expiry date
                invite.ExpiryDate = DateTime.UtcNow.AddDays(7);
                await _context.SaveChangesAsync();

                // Generate invite URL
                var baseUrl = _configuration["Application:BaseUrl"] ?? "https://app-steel-estimation-prod.azurewebsites.net";
                var inviteUrl = $"{baseUrl}/welcome?token={invite.Token}";

                // TODO: Send email
                _logger.LogInformation("Would resend invite email to {Email} with URL: {Url}", invite.Email, inviteUrl);

                return new InviteResult
                {
                    Success = true,
                    Message = "Invite resent successfully",
                    InviteUrl = inviteUrl,
                    Invite = invite
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error resending invite {InviteId}", inviteId);
                return new InviteResult
                {
                    Success = false,
                    Message = "An error occurred while resending the invite"
                };
            }
        }

        public async Task<InviteResult> AcceptInviteAsync(string token, string password)
        {
            try
            {
                var invite = await _context.Invites
                    .Include(i => i.Role)
                    .FirstOrDefaultAsync(i => i.Token == token);

                if (invite == null)
                {
                    return new InviteResult
                    {
                        Success = false,
                        Message = "Invalid or expired invite token"
                    };
                }

                if (invite.IsUsed)
                {
                    return new InviteResult
                    {
                        Success = false,
                        Message = "This invite has already been used"
                    };
                }

                if (invite.ExpiryDate < DateTime.UtcNow)
                {
                    return new InviteResult
                    {
                        Success = false,
                        Message = "This invite has expired"
                    };
                }

                // Check if email already exists (double check)
                if (await _context.Users.AnyAsync(u => u.Email == invite.Email))
                {
                    return new InviteResult
                    {
                        Success = false,
                        Message = "A user with this email already exists"
                    };
                }

                // Create user account
                var registerRequest = new RegisterRequest
                {
                    Email = invite.Email,
                    Username = invite.Email, // Use email as username initially
                    Password = password,
                    FirstName = invite.FirstName,
                    LastName = invite.LastName,
                    CompanyName = invite.CompanyName,
                    JobTitle = invite.JobTitle
                };

                var authResult = await _authService.RegisterAsync(registerRequest);
                
                if (!authResult.Success || authResult.User == null)
                {
                    return new InviteResult
                    {
                        Success = false,
                        Message = authResult.Message ?? "Failed to create user account"
                    };
                }

                // Override the default role assignment
                var userRole = await _context.UserRoles
                    .FirstOrDefaultAsync(ur => ur.UserId == authResult.User.Id);
                
                if (userRole != null)
                {
                    userRole.RoleId = invite.RoleId;
                }
                else
                {
                    _context.UserRoles.Add(new UserRole
                    {
                        UserId = authResult.User.Id,
                        RoleId = invite.RoleId,
                        AssignedDate = DateTime.UtcNow
                    });
                }

                // Mark invite as used
                invite.IsUsed = true;
                invite.UsedDate = DateTime.UtcNow;
                invite.UserId = authResult.User.Id;

                // Mark email as confirmed since they came from an invite
                authResult.User.IsEmailConfirmed = true;
                authResult.User.IsActive = true;

                await _context.SaveChangesAsync();

                return new InviteResult
                {
                    Success = true,
                    Message = "Account created successfully",
                    Invite = invite
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error accepting invite with token");
                return new InviteResult
                {
                    Success = false,
                    Message = "An error occurred while accepting the invite"
                };
            }
        }

        public async Task<bool> RevokeInviteAsync(int inviteId, int requestedByUserId)
        {
            try
            {
                var invite = await _context.Invites.FindAsync(inviteId);
                if (invite == null || invite.IsUsed)
                    return false;

                _context.Invites.Remove(invite);
                await _context.SaveChangesAsync();
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error revoking invite {InviteId}", inviteId);
                return false;
            }
        }

        public async Task<Invite?> GetInviteByTokenAsync(string token)
        {
            return await _context.Invites
                .Include(i => i.Role)
                .Include(i => i.InvitedByUser)
                .FirstOrDefaultAsync(i => i.Token == token);
        }

        public async Task<IEnumerable<Invite>> GetInvitesAsync(bool includeUsed = false)
        {
            var query = _context.Invites
                .Include(i => i.Role)
                .Include(i => i.InvitedByUser)
                .Include(i => i.User)
                .AsQueryable();

            if (!includeUsed)
            {
                query = query.Where(i => !i.IsUsed);
            }

            return await query
                .OrderByDescending(i => i.CreatedDate)
                .ToListAsync();
        }

        public async Task<IEnumerable<Invite>> GetInvitesByUserAsync(int userId)
        {
            return await _context.Invites
                .Include(i => i.Role)
                .Include(i => i.User)
                .Where(i => i.InvitedByUserId == userId)
                .OrderByDescending(i => i.CreatedDate)
                .ToListAsync();
        }

        public async Task<bool> IsEmailInvitedAsync(string email)
        {
            return await _context.Invites
                .AnyAsync(i => i.Email == email && !i.IsUsed && i.ExpiryDate > DateTime.UtcNow);
        }

        public async Task CleanupExpiredInvitesAsync()
        {
            var expiredInvites = await _context.Invites
                .Where(i => !i.IsUsed && i.ExpiryDate < DateTime.UtcNow.AddDays(-30))
                .ToListAsync();

            _context.Invites.RemoveRange(expiredInvites);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Cleaned up {Count} expired invites", expiredInvites.Count);
        }

        private string GenerateSecureToken()
        {
            var bytes = new byte[32];
            using (var rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(bytes);
            }
            return Convert.ToBase64String(bytes)
                .Replace("+", "-")
                .Replace("/", "_")
                .Replace("=", "");
        }
    }
}