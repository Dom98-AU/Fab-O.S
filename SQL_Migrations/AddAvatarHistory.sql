-- Add Avatar History tracking
-- Migration: AddAvatarHistory
-- Date: January 2025

-- Create AvatarHistory table
CREATE TABLE AvatarHistory (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    AvatarUrl NVARCHAR(255) NULL,
    AvatarType NVARCHAR(50) NULL, -- "font-awesome", "dicebear", "custom"
    DiceBearStyle NVARCHAR(100) NULL,
    DiceBearSeed NVARCHAR(100) NULL,
    DiceBearOptions NVARCHAR(500) NULL,
    ChangeReason NVARCHAR(100) NULL, -- "user_change", "admin_change", "system_update"
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    IsActive BIT NOT NULL DEFAULT 0, -- Current active avatar
    CONSTRAINT FK_AvatarHistory_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE
);

-- Create indexes for performance
CREATE INDEX IX_AvatarHistory_UserId ON AvatarHistory(UserId);
CREATE INDEX IX_AvatarHistory_CreatedAt ON AvatarHistory(CreatedAt DESC);
CREATE INDEX IX_AvatarHistory_IsActive ON AvatarHistory(IsActive);

-- Insert current avatars into history for existing users
INSERT INTO AvatarHistory (UserId, AvatarUrl, AvatarType, DiceBearStyle, DiceBearSeed, DiceBearOptions, ChangeReason, IsActive, CreatedAt)
SELECT 
    UP.UserId,
    UP.AvatarUrl,
    UP.AvatarType,
    UP.DiceBearStyle,
    UP.DiceBearSeed,
    UP.DiceBearOptions,
    'system_migration',
    1, -- Mark as active
    ISNULL(UP.UpdatedAt, UP.CreatedAt)
FROM UserProfiles UP
WHERE UP.AvatarUrl IS NOT NULL OR UP.DiceBearStyle IS NOT NULL;

PRINT 'Successfully created AvatarHistory table and migrated existing avatars';

-- Print summary
DECLARE @HistoryCount INT;
SELECT @HistoryCount = COUNT(*) FROM AvatarHistory;
PRINT 'Migrated ' + CAST(@HistoryCount AS NVARCHAR(10)) + ' existing avatars to history';