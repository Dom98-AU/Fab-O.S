using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SteelEstimation.Core.DTOs;
using SteelEstimation.Core.Entities;
using SteelEstimation.Core.Interfaces;
using SteelEstimation.Infrastructure.Data;

namespace SteelEstimation.Infrastructure.Services
{
    public class CommentService : ICommentService
    {
        private readonly IDbContextFactory<ApplicationDbContext> _contextFactory;
        private readonly ILogger<CommentService> _logger;
        private readonly INotificationService _notificationService;

        public CommentService(IDbContextFactory<ApplicationDbContext> contextFactory, ILogger<CommentService> logger, INotificationService notificationService)
        {
            _contextFactory = contextFactory;
            _logger = logger;
            _notificationService = notificationService;
        }

        public async Task<Comment> CreateCommentAsync(CreateCommentRequest request, int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var comment = new Comment
            {
                Content = request.Content,
                UserId = userId,
                EntityType = request.EntityType,
                EntityId = request.EntityId,
                ProductName = request.ProductName,
                ParentCommentId = request.ParentCommentId,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            context.Comments.Add(comment);
            await context.SaveChangesAsync();

            // Parse mentions and create notifications
            await ParseAndCreateMentionsAsync(comment.Id, comment.Content);

            _logger.LogInformation("Created comment {CommentId} for {EntityType} {EntityId}", comment.Id, request.EntityType, request.EntityId);
            return comment;
        }

        public async Task<Comment?> UpdateCommentAsync(int commentId, string newContent, int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var comment = await context.Comments.FindAsync(commentId);
            if (comment == null || comment.UserId != userId || comment.IsDeleted)
            {
                return null;
            }

            comment.Content = newContent;
            comment.IsEdited = true;
            comment.EditedAt = DateTime.UtcNow;
            comment.UpdatedAt = DateTime.UtcNow;

            await context.SaveChangesAsync();
            
            _logger.LogInformation("Updated comment {CommentId}", commentId);
            return comment;
        }

        public async Task<bool> DeleteCommentAsync(int commentId, int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var comment = await context.Comments.FindAsync(commentId);
            if (comment == null || comment.IsDeleted)
            {
                return false;
            }

            // Check if user owns the comment or is an admin
            var user = await context.Users
                .Include(u => u.UserRoles)
                .ThenInclude(ur => ur.Role)
                .FirstOrDefaultAsync(u => u.Id == userId);
            
            var isAdmin = user?.UserRoles.Any(ur => ur.Role.RoleName == "Administrator") ?? false;
            
            if (comment.UserId != userId && !isAdmin)
            {
                return false;
            }

            comment.IsDeleted = true;
            comment.DeletedAt = DateTime.UtcNow;
            comment.DeletedByUserId = userId;

            await context.SaveChangesAsync();
            
            _logger.LogInformation("Deleted comment {CommentId} by user {UserId}", commentId, userId);
            return true;
        }

        public async Task<Comment?> GetCommentAsync(int commentId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            return await context.Comments
                .Include(c => c.User)
                .Include(c => c.Mentions)
                .Include(c => c.Reactions)
                .FirstOrDefaultAsync(c => c.Id == commentId);
        }

        public async Task<IEnumerable<Comment>> GetCommentsForEntityAsync(string entityType, int entityId, bool includeDeleted = false)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var query = context.Comments
                .Include(c => c.User)
                .Include(c => c.Replies)
                .Include(c => c.Mentions)
                .Include(c => c.Reactions)
                .Where(c => c.EntityType == entityType && c.EntityId == entityId && c.ParentCommentId == null);

            if (!includeDeleted)
            {
                query = query.Where(c => !c.IsDeleted);
            }

            return await query.OrderByDescending(c => c.CreatedAt).ToListAsync();
        }

        public async Task<IEnumerable<Comment>> GetCommentThreadAsync(int parentCommentId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            return await context.Comments
                .Include(c => c.User)
                .Include(c => c.Mentions)
                .Include(c => c.Reactions)
                .Where(c => c.ParentCommentId == parentCommentId && !c.IsDeleted)
                .OrderBy(c => c.CreatedAt)
                .ToListAsync();
        }

        public async Task<IEnumerable<Comment>> GetUserCommentsAsync(int userId, int pageNumber = 1, int pageSize = 50)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var skip = (pageNumber - 1) * pageSize;
            
            return await context.Comments
                .Include(c => c.User)
                .Where(c => c.UserId == userId && !c.IsDeleted)
                .OrderByDescending(c => c.CreatedAt)
                .Skip(skip)
                .Take(pageSize)
                .ToListAsync();
        }

        public async Task<int> GetCommentCountAsync(string entityType, int entityId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            return await context.Comments
                .CountAsync(c => c.EntityType == entityType && c.EntityId == entityId && !c.IsDeleted);
        }

        public async Task<IEnumerable<CommentMention>> GetUserMentionsAsync(int userId, bool unreadOnly = false)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var query = context.CommentMentions
                .Include(m => m.Comment)
                .ThenInclude(c => c.User)
                .Where(m => m.MentionedUserId == userId);

            if (unreadOnly)
            {
                query = query.Where(m => !m.IsRead);
            }

            return await query.OrderByDescending(m => m.CreatedAt).ToListAsync();
        }

        public async Task<bool> MarkMentionAsReadAsync(int mentionId, int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var mention = await context.CommentMentions
                .FirstOrDefaultAsync(m => m.Id == mentionId && m.MentionedUserId == userId);
            
            if (mention == null || mention.IsRead)
            {
                return false;
            }

            mention.IsRead = true;
            mention.ReadAt = DateTime.UtcNow;
            
            await context.SaveChangesAsync();
            return true;
        }

        public async Task<bool> MarkAllMentionsAsReadAsync(int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var mentions = await context.CommentMentions
                .Where(m => m.MentionedUserId == userId && !m.IsRead)
                .ToListAsync();

            foreach (var mention in mentions)
            {
                mention.IsRead = true;
                mention.ReadAt = DateTime.UtcNow;
            }

            await context.SaveChangesAsync();
            return mentions.Any();
        }

        public async Task<IEnumerable<User>> ParseAndCreateMentionsAsync(int commentId, string content)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var mentionedUsers = new List<User>();
            
            // Simple mention parsing - look for @username patterns
            var mentionPattern = @"@(\w+)";
            var matches = System.Text.RegularExpressions.Regex.Matches(content, mentionPattern);
            
            foreach (System.Text.RegularExpressions.Match match in matches)
            {
                var username = match.Groups[1].Value;
                var user = await context.Users
                    .Include(u => u.Profile)
                    .FirstOrDefaultAsync(u => u.Username == username);
                
                if (user != null && (user.Profile?.AllowMentions ?? true))
                {
                    // Check if mention already exists
                    var existingMention = await context.CommentMentions
                        .AnyAsync(m => m.CommentId == commentId && m.MentionedUserId == user.Id);
                    
                    if (!existingMention)
                    {
                        var mention = new CommentMention
                        {
                            CommentId = commentId,
                            MentionedUserId = user.Id,
                            CreatedAt = DateTime.UtcNow
                        };
                        
                        context.CommentMentions.Add(mention);
                        mentionedUsers.Add(user);
                    }
                }
            }
            
            if (mentionedUsers.Any())
            {
                await context.SaveChangesAsync();
                
                // Create notifications for mentioned users
                var comment = await GetCommentAsync(commentId);
                if (comment != null)
                {
                    foreach (var user in mentionedUsers)
                    {
                        await _notificationService.CreateMentionNotificationAsync(user.Id, comment.UserId, comment);
                    }
                }
            }
            
            return mentionedUsers;
        }

        public async Task<CommentReaction?> AddReactionAsync(int commentId, int userId, string reactionType)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var existingReaction = await context.CommentReactions
                .FirstOrDefaultAsync(r => r.CommentId == commentId && r.UserId == userId);
            
            if (existingReaction != null)
            {
                existingReaction.ReactionType = reactionType;
                existingReaction.CreatedAt = DateTime.UtcNow;
            }
            else
            {
                var reaction = new CommentReaction
                {
                    CommentId = commentId,
                    UserId = userId,
                    ReactionType = reactionType,
                    CreatedAt = DateTime.UtcNow
                };
                
                context.CommentReactions.Add(reaction);
                existingReaction = reaction;
            }
            
            await context.SaveChangesAsync();
            return existingReaction;
        }

        public async Task<bool> RemoveReactionAsync(int commentId, int userId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var reaction = await context.CommentReactions
                .FirstOrDefaultAsync(r => r.CommentId == commentId && r.UserId == userId);
            
            if (reaction == null)
            {
                return false;
            }
            
            context.CommentReactions.Remove(reaction);
            await context.SaveChangesAsync();
            return true;
        }

        public async Task<IEnumerable<CommentReaction>> GetCommentReactionsAsync(int commentId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            return await context.CommentReactions
                .Include(r => r.User)
                .Where(r => r.CommentId == commentId)
                .OrderBy(r => r.CreatedAt)
                .ToListAsync();
        }

        public async Task<Dictionary<string, int>> GetReactionSummaryAsync(int commentId)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var reactions = await context.CommentReactions
                .Where(r => r.CommentId == commentId)
                .GroupBy(r => r.ReactionType)
                .Select(g => new { Type = g.Key, Count = g.Count() })
                .ToListAsync();
            
            return reactions.ToDictionary(r => r.Type, r => r.Count);
        }

        public async Task<IEnumerable<Comment>> GetProductCommentsAsync(string productName, int pageNumber = 1, int pageSize = 50)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var skip = (pageNumber - 1) * pageSize;
            
            return await context.Comments
                .Include(c => c.User)
                .Where(c => c.ProductName == productName && !c.IsDeleted)
                .OrderByDescending(c => c.CreatedAt)
                .Skip(skip)
                .Take(pageSize)
                .ToListAsync();
        }

        public async Task<IEnumerable<Comment>> GetRecentActivityAsync(int companyId, string? productName = null, int days = 7)
        {
            using var context = await _contextFactory.CreateDbContextAsync();
            
            var startDate = DateTime.UtcNow.AddDays(-days);
            
            var query = context.Comments
                .Include(c => c.User)
                .Where(c => c.User.CompanyId == companyId && 
                           c.CreatedAt >= startDate && 
                           !c.IsDeleted);
            
            if (!string.IsNullOrEmpty(productName))
            {
                query = query.Where(c => c.ProductName == productName);
            }
            
            return await query
                .OrderByDescending(c => c.CreatedAt)
                .Take(100)
                .ToListAsync();
        }
    }
}