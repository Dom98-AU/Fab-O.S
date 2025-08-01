using System;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.Entities
{
    public class UserPreference
    {
        public int Id { get; set; }
        
        [Required]
        public int UserId { get; set; }
        
        // UI Preferences
        [MaxLength(20)]
        public string Theme { get; set; } = "light"; // light, dark, auto
        
        [MaxLength(10)]
        public string Language { get; set; } = "en";
        
        [MaxLength(20)]
        public string DateFormat { get; set; } = "MM/dd/yyyy";
        
        [MaxLength(20)]
        public string TimeFormat { get; set; } = "12h"; // 12h or 24h
        
        // Module Preferences
        [MaxLength(50)]
        public string DefaultModule { get; set; } = "Estimate";
        
        // Estimate Module Preferences
        public bool AutoSaveEstimates { get; set; } = true;
        public int AutoSaveIntervalMinutes { get; set; } = 5;
        public bool ShowWeldingTimeByDefault { get; set; } = true;
        public bool ShowProcessingTimeByDefault { get; set; } = true;
        
        // Table View Preferences
        [MaxLength(20)]
        public string DefaultTableView { get; set; } = "table"; // table, card
        public int DefaultPageSize { get; set; } = 10;
        public int DefaultCardsPerRow { get; set; } = 3;
        
        // Notification Preferences
        public bool EmailNotifications { get; set; } = true;
        public bool EmailMentions { get; set; } = true;
        public bool EmailComments { get; set; } = true;
        public bool EmailInvites { get; set; } = true;
        public bool EmailReports { get; set; } = true;
        
        // In-App Notification Preferences
        public bool ShowNotificationBadge { get; set; } = true;
        public bool PlayNotificationSound { get; set; } = false;
        public bool DesktopNotifications { get; set; } = false;
        
        // Dashboard Preferences
        public bool ShowDashboardWidgets { get; set; } = true;
        [MaxLength(500)]
        public string? DashboardLayout { get; set; } // JSON string for widget positions
        
        // Privacy Preferences
        public bool ShowOnlineStatus { get; set; } = true;
        public bool ShowLastSeen { get; set; } = true;
        public bool ShowActivityFeed { get; set; } = true;
        
        // Tracking
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        
        // Navigation properties
        public User User { get; set; } = null!;
    }
}