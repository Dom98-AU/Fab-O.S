using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Cryptography.KeyDerivation;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SteelEstimation.Core.DTOs;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Interfaces;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services
{
    public class UserService : IUserService
    {
        private readonly ApplicationDbContext _context;
        private readonly ILogger<UserService> _logger;

        public UserService(ApplicationDbContext context, ILogger<UserService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<User?> GetUserByIdAsync(int userId)
        {
            return await _context.Users
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.Id == userId);
        }

        public async Task<User?> GetUserByUsernameAsync(string username)
        {
            return await _context.Users
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.Username == username);
        }

        public async Task<User?> GetUserByEmailAsync(string email)
        {
            return await _context.Users
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.Email == email);
        }

        public async Task<IEnumerable<User>> GetAllUsersAsync()
        {
            return await _context.Users
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .OrderBy(u => u.Username)
                .ToListAsync();
        }

        public async Task<IEnumerable<User>> GetActiveUsersAsync()
        {
            return await _context.Users
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .Where(u => u.IsActive)
                .OrderBy(u => u.Username)
                .ToListAsync();
        }

        public async Task<User> CreateUserAsync(CreateUserRequest request)
        {
            try
            {
                // Validate uniqueness
                if (await _context.Users.AnyAsync(u => u.Username == request.Username))
                    throw new InvalidOperationException("Username already exists");

                if (await _context.Users.AnyAsync(u => u.Email == request.Email))
                    throw new InvalidOperationException("Email already registered");

                // Create user
                var user = new User
                {
                    Username = request.Username,
                    Email = request.Email,
                    PasswordHash = HashPassword(request.Password),
                    FirstName = request.FirstName,
                    LastName = request.LastName,
                    CompanyName = request.CompanyName,
                    JobTitle = request.JobTitle,
                    PhoneNumber = request.PhoneNumber,
                    IsActive = request.IsActive,
                    IsEmailConfirmed = !request.RequireEmailConfirmation,
                    EmailConfirmationToken = request.RequireEmailConfirmation ? GenerateToken() : null,
                    CreatedDate = DateTime.UtcNow,
                    LastModified = DateTime.UtcNow
                };

                _context.Users.Add(user);
                await _context.SaveChangesAsync();

                // Assign role
                var role = await _context.Roles.FirstOrDefaultAsync(r => r.RoleName == request.RoleName);
                if (role != null)
                {
                    _context.UserRoles.Add(new UserRole
                    {
                        UserId = user.Id,
                        RoleId = role.Id,
                        AssignedDate = DateTime.UtcNow
                    });
                    await _context.SaveChangesAsync();
                }

                // TODO: Send welcome email if requested
                if (request.SendWelcomeEmail)
                {
                    _logger.LogInformation("Welcome email should be sent to {Email}", user.Email);
                }

                _logger.LogInformation("User created: {Username}", user.Username);
                return user;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating user");
                throw;
            }
        }

        public async Task<User?> UpdateUserAsync(int userId, UpdateUserRequest request)
        {
            try
            {
                var user = await _context.Users.FindAsync(userId);
                if (user == null) return null;

                // Update email if changed
                if (!string.IsNullOrEmpty(request.Email) && request.Email != user.Email)
                {
                    if (await _context.Users.AnyAsync(u => u.Email == request.Email && u.Id != userId))
                        throw new InvalidOperationException("Email already in use");
                    
                    user.Email = request.Email;
                    user.IsEmailConfirmed = false;
                    user.EmailConfirmationToken = GenerateToken();
                }

                // Update other properties
                if (request.FirstName != null) user.FirstName = request.FirstName;
                if (request.LastName != null) user.LastName = request.LastName;
                if (request.CompanyName != null) user.CompanyName = request.CompanyName;
                if (request.JobTitle != null) user.JobTitle = request.JobTitle;
                if (request.PhoneNumber != null) user.PhoneNumber = request.PhoneNumber;
                if (request.IsActive.HasValue) user.IsActive = request.IsActive.Value;

                user.LastModified = DateTime.UtcNow;

                await _context.SaveChangesAsync();
                _logger.LogInformation("User updated: {UserId}", userId);
                
                return user;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating user {UserId}", userId);
                throw;
            }
        }

        public async Task<bool> DeleteUserAsync(int userId)
        {
            try
            {
                var user = await _context.Users.FindAsync(userId);
                if (user == null) return false;

                // Soft delete - just deactivate
                user.IsActive = false;
                user.LastModified = DateTime.UtcNow;
                
                await _context.SaveChangesAsync();
                _logger.LogInformation("User deactivated (soft delete): {UserId}", userId);
                
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting user {UserId}", userId);
                return false;
            }
        }

        public async Task<bool> DeactivateUserAsync(int userId)
        {
            return await SetUserActiveStatus(userId, false);
        }

        public async Task<bool> ActivateUserAsync(int userId)
        {
            return await SetUserActiveStatus(userId, true);
        }

        public async Task<bool> AssignRoleAsync(int userId, string roleName, int assignedByUserId)
        {
            try
            {
                var user = await _context.Users.FindAsync(userId);
                var role = await _context.Roles.FirstOrDefaultAsync(r => r.RoleName == roleName);
                
                if (user == null || role == null) return false;

                // Check if already assigned
                if (await _context.UserRoles.AnyAsync(ur => ur.UserId == userId && ur.RoleId == role.Id))
                    return true;

                _context.UserRoles.Add(new UserRole
                {
                    UserId = userId,
                    RoleId = role.Id,
                    AssignedBy = assignedByUserId,
                    AssignedDate = DateTime.UtcNow
                });

                await _context.SaveChangesAsync();
                _logger.LogInformation("Role {Role} assigned to user {UserId}", roleName, userId);
                
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error assigning role to user {UserId}", userId);
                return false;
            }
        }

        public async Task<bool> RemoveRoleAsync(int userId, string roleName)
        {
            try
            {
                var userRole = await _context.UserRoles
                    .Include(ur => ur.Role)
                    .FirstOrDefaultAsync(ur => ur.UserId == userId && ur.Role.RoleName == roleName);
                
                if (userRole == null) return false;

                _context.UserRoles.Remove(userRole);
                await _context.SaveChangesAsync();
                
                _logger.LogInformation("Role {Role} removed from user {UserId}", roleName, userId);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error removing role from user {UserId}", userId);
                return false;
            }
        }

        public async Task<IEnumerable<Role>> GetUserRolesAsync(int userId)
        {
            return await _context.UserRoles
                .Where(ur => ur.UserId == userId)
                .Select(ur => ur.Role)
                .ToListAsync();
        }

        public async Task<IEnumerable<Role>> GetAllRolesAsync()
        {
            return await _context.Roles.OrderBy(r => r.RoleName).ToListAsync();
        }

        public async Task<IEnumerable<User>> SearchUsersAsync(string searchTerm)
        {
            if (string.IsNullOrWhiteSpace(searchTerm))
                return await GetAllUsersAsync();

            searchTerm = searchTerm.ToLower();

            return await _context.Users
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .Where(u => 
                    u.Username.ToLower().Contains(searchTerm) ||
                    u.Email.ToLower().Contains(searchTerm) ||
                    (u.FirstName != null && u.FirstName.ToLower().Contains(searchTerm)) ||
                    (u.LastName != null && u.LastName.ToLower().Contains(searchTerm)) ||
                    (u.CompanyName != null && u.CompanyName.ToLower().Contains(searchTerm)))
                .OrderBy(u => u.Username)
                .ToListAsync();
        }

        public async Task<int> GetActiveUserCountAsync()
        {
            return await _context.Users.CountAsync(u => u.IsActive);
        }

        public async Task<IEnumerable<User>> GetUsersInRoleAsync(string roleName)
        {
            return await _context.UserRoles
                .Include(ur => ur.User)
                .ThenInclude(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .Where(ur => ur.Role.RoleName == roleName)
                .Select(ur => ur.User)
                .ToListAsync();
        }

        public async Task<bool> IsEmailUniqueAsync(string email, int? excludeUserId = null)
        {
            var query = _context.Users.Where(u => u.Email == email);
            if (excludeUserId.HasValue)
                query = query.Where(u => u.Id != excludeUserId.Value);
            
            return !await query.AnyAsync();
        }

        public async Task<bool> IsUsernameUniqueAsync(string username, int? excludeUserId = null)
        {
            var query = _context.Users.Where(u => u.Username == username);
            if (excludeUserId.HasValue)
                query = query.Where(u => u.Id != excludeUserId.Value);
            
            return !await query.AnyAsync();
        }

        public async Task<bool> UnlockUserAsync(int userId)
        {
            try
            {
                var user = await _context.Users.FindAsync(userId);
                if (user == null) return false;

                user.LockedOutUntil = null;
                user.FailedLoginAttempts = 0;
                user.LastModified = DateTime.UtcNow;

                await _context.SaveChangesAsync();
                _logger.LogInformation("User unlocked: {UserId}", userId);
                
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error unlocking user {UserId}", userId);
                return false;
            }
        }

        public async Task<bool> ResetFailedLoginAttemptsAsync(int userId)
        {
            try
            {
                var user = await _context.Users.FindAsync(userId);
                if (user == null) return false;

                user.FailedLoginAttempts = 0;
                user.LastModified = DateTime.UtcNow;

                await _context.SaveChangesAsync();
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error resetting failed login attempts for user {UserId}", userId);
                return false;
            }
        }

        public async Task<bool> UpdateLastLoginAsync(int userId)
        {
            try
            {
                var user = await _context.Users.FindAsync(userId);
                if (user == null) return false;

                user.LastLoginDate = DateTime.UtcNow;
                await _context.SaveChangesAsync();
                
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating last login for user {UserId}", userId);
                return false;
            }
        }

        #region Private Methods

        private async Task<bool> SetUserActiveStatus(int userId, bool isActive)
        {
            try
            {
                var user = await _context.Users.FindAsync(userId);
                if (user == null) return false;

                user.IsActive = isActive;
                user.LastModified = DateTime.UtcNow;

                await _context.SaveChangesAsync();
                _logger.LogInformation("User {UserId} active status set to {Status}", userId, isActive);
                
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error setting user {UserId} active status", userId);
                return false;
            }
        }

        private string HashPassword(string password)
        {
            // Generate a 128-bit salt
            byte[] salt = new byte[128 / 8];
            using (var rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(salt);
            }

            // Derive a 256-bit subkey
            string hashed = Convert.ToBase64String(KeyDerivation.Pbkdf2(
                password: password,
                salt: salt,
                prf: KeyDerivationPrf.HMACSHA256,
                iterationCount: 100000,
                numBytesRequested: 256 / 8));

            // Combine salt and hash
            return $"{Convert.ToBase64String(salt)}.{hashed}";
        }

        private string GenerateToken()
        {
            var bytes = new byte[32];
            using (var rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(bytes);
            }
            return Convert.ToBase64String(bytes).Replace("+", "-").Replace("/", "_");
        }

        #endregion
    }
}