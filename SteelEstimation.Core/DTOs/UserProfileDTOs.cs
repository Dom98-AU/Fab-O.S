using System;
using System.ComponentModel.DataAnnotations;

namespace SteelEstimation.Core.DTOs
{
    public class CreateUserProfileRequest
    {
        [MaxLength(500)]
        public string? Bio { get; set; }
        
        [MaxLength(100)]
        public string? Location { get; set; }
        
        [MaxLength(50)]
        public string? Timezone { get; set; }
        
        [Phone, MaxLength(20)]
        public string? PhoneNumber { get; set; }
        
        [MaxLength(100)]
        public string? Department { get; set; }
        
        public DateTime? DateOfBirth { get; set; }
        
        public DateTime? StartDate { get; set; }
        
        [MaxLength(100)]
        public string? JobTitle { get; set; }
        
        [MaxLength(500)]
        public string? Skills { get; set; }
        
        [MaxLength(1000)]
        public string? AboutMe { get; set; }
        
        public bool IsProfilePublic { get; set; } = true;
        public bool ShowEmail { get; set; } = false;
        public bool ShowPhoneNumber { get; set; } = false;
        public bool AllowMentions { get; set; } = true;
    }
    
    public class UpdateUserProfileRequest : CreateUserProfileRequest
    {
        [MaxLength(255)]
        public string? AvatarUrl { get; set; }
        
        [MaxLength(50)]
        public string? AvatarType { get; set; } // "font-awesome", "dicebear", "custom"
        
        [MaxLength(100)]
        public string? DiceBearStyle { get; set; } // DiceBear style ID (e.g., "adventurer", "avataaars")
        
        [MaxLength(100)]
        public string? DiceBearSeed { get; set; } // Seed for consistent DiceBear generation
        
        [MaxLength(2000)]
        public string? DiceBearOptions { get; set; } // JSON string of DiceBear options
        
        [MaxLength(100)]
        public string? Status { get; set; }
        
        [MaxLength(255)]
        public string? StatusMessage { get; set; }
    }
    
    public class CreateUserPreferencesRequest
    {
        [MaxLength(20)]
        public string Theme { get; set; } = "light";
        
        [MaxLength(10)]
        public string Language { get; set; } = "en";
        
        [MaxLength(20)]
        public string DateFormat { get; set; } = "MM/dd/yyyy";
        
        [MaxLength(20)]
        public string TimeFormat { get; set; } = "12h";
        
        [MaxLength(50)]
        public string DefaultModule { get; set; } = "Estimate";
        
        public bool AutoSaveEstimates { get; set; } = true;
        public int AutoSaveIntervalMinutes { get; set; } = 5;
        
        public bool EmailNotifications { get; set; } = true;
        public bool EmailMentions { get; set; } = true;
        public bool EmailComments { get; set; } = true;
        
        public bool ShowOnlineStatus { get; set; } = true;
        public bool ShowLastSeen { get; set; } = true;
    }
    
    public class UpdateUserPreferencesRequest : CreateUserPreferencesRequest
    {
        [MaxLength(20)]
        public string DefaultTableView { get; set; } = "table";
        
        public int DefaultPageSize { get; set; } = 10;
        public int DefaultCardsPerRow { get; set; } = 3;
        
        public bool ShowNotificationBadge { get; set; } = true;
        public bool PlayNotificationSound { get; set; } = false;
        public bool DesktopNotifications { get; set; } = false;
        
        public bool ShowDashboardWidgets { get; set; } = true;
        
        [MaxLength(500)]
        public string? DashboardLayout { get; set; }
        
        // Estimation preferences
        public bool ShowWeldingTimeByDefault { get; set; } = true;
        public bool ShowProcessingTimeByDefault { get; set; } = true;
        
        // Additional email preferences
        public bool EmailInvites { get; set; } = true;
        public bool EmailReports { get; set; } = false;
        
        // Activity feed preference
        public bool ShowActivityFeed { get; set; } = true;
    }
    
    public class UserProfileDto
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Username { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string? Bio { get; set; }
        public string? AvatarUrl { get; set; }
        public string? Location { get; set; }
        public string? Timezone { get; set; }
        public string? PhoneNumber { get; set; }
        public string? Department { get; set; }
        public string? JobTitle { get; set; }
        public string? Skills { get; set; }
        public string? AboutMe { get; set; }
        public string? Status { get; set; }
        public string? StatusMessage { get; set; }
        public DateTime? LastActivityAt { get; set; }
        public bool IsOnline { get; set; }
        public bool CanBeMentioned { get; set; }
    }
}