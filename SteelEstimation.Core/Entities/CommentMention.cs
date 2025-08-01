using System;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities
{
    public class CommentMention
    {
        public int Id { get; set; }
        
        [Required]
        public int CommentId { get; set; }
        
        [Required]
        public int MentionedUserId { get; set; }
        
        public bool IsRead { get; set; } = false;
        public DateTime? ReadAt { get; set; }
        
        // Tracking
        public DateTime CreatedAt { get; set; }
        
        // Navigation properties
        public Comment Comment { get; set; } = null!;
        public User MentionedUser { get; set; } = null!;
    }
}