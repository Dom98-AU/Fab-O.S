using System;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities
{
    public class CommentReaction
    {
        public int Id { get; set; }
        
        [Required]
        public int CommentId { get; set; }
        
        [Required]
        public int UserId { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string ReactionType { get; set; } = string.Empty; // e.g., "like", "thumbsup", "heart", "celebrate"
        
        // Tracking
        public DateTime CreatedAt { get; set; }
        
        // Navigation properties
        public Comment Comment { get; set; } = null!;
        public User User { get; set; } = null!;
    }
}