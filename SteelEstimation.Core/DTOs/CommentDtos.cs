using System;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.DTOs
{
    public class CreateCommentRequest
    {
        [Required, MaxLength(2000)]
        public string Content { get; set; } = string.Empty;
        
        [Required, MaxLength(50)]
        public string EntityType { get; set; } = string.Empty;
        
        [Required]
        public int EntityId { get; set; }
        
        [MaxLength(50)]
        public string? ProductName { get; set; }
        
        public int? ParentCommentId { get; set; }
    }
    
    public class CommentDto
    {
        public int Id { get; set; }
        public string Content { get; set; } = string.Empty;
        public int UserId { get; set; }
        public string Username { get; set; } = string.Empty;
        public string UserFullName { get; set; } = string.Empty;
        public string? UserAvatarUrl { get; set; }
        public string EntityType { get; set; } = string.Empty;
        public int EntityId { get; set; }
        public string? ProductName { get; set; }
        public int? ParentCommentId { get; set; }
        public bool IsEdited { get; set; }
        public DateTime? EditedAt { get; set; }
        public bool IsDeleted { get; set; }
        public DateTime CreatedAt { get; set; }
        public List<CommentDto> Replies { get; set; } = new();
        public List<CommentMentionDto> Mentions { get; set; } = new();
        public Dictionary<string, int> ReactionSummary { get; set; } = new();
        public string? UserReaction { get; set; }
        public bool CanEdit { get; set; }
        public bool CanDelete { get; set; }
    }
    
    public class CommentMentionDto
    {
        public int Id { get; set; }
        public int MentionedUserId { get; set; }
        public string MentionedUsername { get; set; } = string.Empty;
        public string MentionedUserFullName { get; set; } = string.Empty;
        public bool IsRead { get; set; }
        public DateTime? ReadAt { get; set; }
    }
    
    public class CommentReactionDto
    {
        public int UserId { get; set; }
        public string Username { get; set; } = string.Empty;
        public string UserFullName { get; set; } = string.Empty;
        public string ReactionType { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }
}