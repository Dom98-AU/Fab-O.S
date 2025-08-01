using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities
{
    public class Comment
    {
        public int Id { get; set; }
        
        [Required]
        [MaxLength(2000)]
        public string Content { get; set; } = string.Empty;
        
        [Required]
        public int UserId { get; set; }
        
        // Polymorphic association - can be attached to different entities
        [Required]
        [MaxLength(50)]
        public string EntityType { get; set; } = string.Empty; // e.g., "Estimation", "Package", "Project"
        
        [Required]
        public int EntityId { get; set; }
        
        // Product/Module context
        [MaxLength(50)]
        public string? ProductName { get; set; } // e.g., "Estimate", "Trace", "Fabmate", "QDocs"
        
        // Threading
        public int? ParentCommentId { get; set; }
        
        // Status
        public bool IsEdited { get; set; } = false;
        public DateTime? EditedAt { get; set; }
        public bool IsDeleted { get; set; } = false;
        public DateTime? DeletedAt { get; set; }
        public int? DeletedByUserId { get; set; }
        
        // Tracking
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        
        // Navigation properties
        public User User { get; set; } = null!;
        public User? DeletedByUser { get; set; }
        public Comment? ParentComment { get; set; }
        public ICollection<Comment> Replies { get; set; } = new List<Comment>();
        public ICollection<CommentMention> Mentions { get; set; } = new List<CommentMention>();
        public ICollection<CommentReaction> Reactions { get; set; } = new List<CommentReaction>();
    }
}