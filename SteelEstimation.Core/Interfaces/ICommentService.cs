using System;
using System.Threading.Tasks;
using SteelEstimation.Core.DTOs;
using SteelEstimation.Core.Entities;

namespace SteelEstimation.Core.Interfaces
{
    public interface ICommentService
    {
        // Comment CRUD operations
        Task<Comment> CreateCommentAsync(CreateCommentRequest request, int userId);
        Task<Comment?> UpdateCommentAsync(int commentId, string newContent, int userId);
        Task<bool> DeleteCommentAsync(int commentId, int userId);
        Task<Comment?> GetCommentAsync(int commentId);
        
        // Comment queries
        Task<IEnumerable<Comment>> GetCommentsForEntityAsync(string entityType, int entityId, bool includeDeleted = false);
        Task<IEnumerable<Comment>> GetCommentThreadAsync(int parentCommentId);
        Task<IEnumerable<Comment>> GetUserCommentsAsync(int userId, int pageNumber = 1, int pageSize = 50);
        Task<int> GetCommentCountAsync(string entityType, int entityId);
        
        // Mention functionality
        Task<IEnumerable<CommentMention>> GetUserMentionsAsync(int userId, bool unreadOnly = false);
        Task<bool> MarkMentionAsReadAsync(int mentionId, int userId);
        Task<bool> MarkAllMentionsAsReadAsync(int userId);
        Task<IEnumerable<User>> ParseAndCreateMentionsAsync(int commentId, string content);
        
        // Reaction functionality
        Task<CommentReaction?> AddReactionAsync(int commentId, int userId, string reactionType);
        Task<bool> RemoveReactionAsync(int commentId, int userId);
        Task<IEnumerable<CommentReaction>> GetCommentReactionsAsync(int commentId);
        Task<Dictionary<string, int>> GetReactionSummaryAsync(int commentId);
        
        // Product/Module filtering
        Task<IEnumerable<Comment>> GetProductCommentsAsync(string productName, int pageNumber = 1, int pageSize = 50);
        Task<IEnumerable<Comment>> GetRecentActivityAsync(int companyId, string? productName = null, int days = 7);
    }
}