-- User Profile System Migration
-- Add comprehensive user profiles, preferences, comments, and notifications

-- Create UserProfiles table
CREATE TABLE UserProfiles (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    Bio NVARCHAR(500) NULL,
    AvatarUrl NVARCHAR(255) NULL,
    Location NVARCHAR(100) NULL,
    Timezone NVARCHAR(50) NULL,
    PhoneNumber NVARCHAR(20) NULL,
    Department NVARCHAR(100) NULL,
    DateOfBirth DATETIME2 NULL,
    StartDate DATETIME2 NULL,
    JobTitle NVARCHAR(100) NULL,
    Skills NVARCHAR(500) NULL,
    AboutMe NVARCHAR(1000) NULL,
    IsProfilePublic BIT NOT NULL DEFAULT 1,
    ShowEmail BIT NOT NULL DEFAULT 0,
    ShowPhoneNumber BIT NOT NULL DEFAULT 0,
    AllowMentions BIT NOT NULL DEFAULT 1,
    Status NVARCHAR(100) NULL,
    StatusMessage NVARCHAR(255) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    LastActivityAt DATETIME2 NULL,
    CONSTRAINT FK_UserProfiles_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
    CONSTRAINT UQ_UserProfiles_UserId UNIQUE (UserId)
);

-- Create UserPreferences table
CREATE TABLE UserPreferences (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    Theme NVARCHAR(20) NOT NULL DEFAULT 'light',
    Language NVARCHAR(10) NOT NULL DEFAULT 'en',
    DateFormat NVARCHAR(20) NOT NULL DEFAULT 'MM/dd/yyyy',
    TimeFormat NVARCHAR(20) NOT NULL DEFAULT '12h',
    DefaultModule NVARCHAR(50) NOT NULL DEFAULT 'Estimate',
    AutoSaveEstimates BIT NOT NULL DEFAULT 1,
    AutoSaveIntervalMinutes INT NOT NULL DEFAULT 5,
    ShowWeldingTimeByDefault BIT NOT NULL DEFAULT 1,
    ShowProcessingTimeByDefault BIT NOT NULL DEFAULT 1,
    DefaultTableView NVARCHAR(20) NOT NULL DEFAULT 'table',
    DefaultPageSize INT NOT NULL DEFAULT 10,
    DefaultCardsPerRow INT NOT NULL DEFAULT 3,
    EmailNotifications BIT NOT NULL DEFAULT 1,
    EmailMentions BIT NOT NULL DEFAULT 1,
    EmailComments BIT NOT NULL DEFAULT 1,
    EmailInvites BIT NOT NULL DEFAULT 1,
    EmailReports BIT NOT NULL DEFAULT 1,
    ShowNotificationBadge BIT NOT NULL DEFAULT 1,
    PlayNotificationSound BIT NOT NULL DEFAULT 0,
    DesktopNotifications BIT NOT NULL DEFAULT 0,
    ShowDashboardWidgets BIT NOT NULL DEFAULT 1,
    DashboardLayout NVARCHAR(500) NULL,
    ShowOnlineStatus BIT NOT NULL DEFAULT 1,
    ShowLastSeen BIT NOT NULL DEFAULT 1,
    ShowActivityFeed BIT NOT NULL DEFAULT 1,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_UserPreferences_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
    CONSTRAINT UQ_UserPreferences_UserId UNIQUE (UserId)
);

-- Create Comments table
CREATE TABLE Comments (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Content NVARCHAR(2000) NOT NULL,
    UserId INT NOT NULL,
    EntityType NVARCHAR(50) NOT NULL,
    EntityId INT NOT NULL,
    ProductName NVARCHAR(50) NULL,
    ParentCommentId INT NULL,
    IsEdited BIT NOT NULL DEFAULT 0,
    EditedAt DATETIME2 NULL,
    IsDeleted BIT NOT NULL DEFAULT 0,
    DeletedAt DATETIME2 NULL,
    DeletedByUserId INT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_Comments_Users FOREIGN KEY (UserId) REFERENCES Users(Id),
    CONSTRAINT FK_Comments_DeletedByUser FOREIGN KEY (DeletedByUserId) REFERENCES Users(Id),
    CONSTRAINT FK_Comments_ParentComment FOREIGN KEY (ParentCommentId) REFERENCES Comments(Id)
);

-- Create CommentMentions table
CREATE TABLE CommentMentions (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    CommentId INT NOT NULL,
    MentionedUserId INT NOT NULL,
    IsRead BIT NOT NULL DEFAULT 0,
    ReadAt DATETIME2 NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_CommentMentions_Comments FOREIGN KEY (CommentId) REFERENCES Comments(Id) ON DELETE CASCADE,
    CONSTRAINT FK_CommentMentions_Users FOREIGN KEY (MentionedUserId) REFERENCES Users(Id)
);

-- Create CommentReactions table
CREATE TABLE CommentReactions (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    CommentId INT NOT NULL,
    UserId INT NOT NULL,
    ReactionType NVARCHAR(50) NOT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_CommentReactions_Comments FOREIGN KEY (CommentId) REFERENCES Comments(Id) ON DELETE CASCADE,
    CONSTRAINT FK_CommentReactions_Users FOREIGN KEY (UserId) REFERENCES Users(Id),
    CONSTRAINT UQ_CommentReactions_UserComment UNIQUE (CommentId, UserId)
);

-- Create Notifications table
CREATE TABLE Notifications (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    Type NVARCHAR(100) NOT NULL,
    Title NVARCHAR(255) NOT NULL,
    Message NVARCHAR(500) NULL,
    EntityType NVARCHAR(50) NULL,
    EntityId INT NULL,
    ProductName NVARCHAR(50) NULL,
    ActionUrl NVARCHAR(255) NULL,
    IsRead BIT NOT NULL DEFAULT 0,
    ReadAt DATETIME2 NULL,
    IsArchived BIT NOT NULL DEFAULT 0,
    ArchivedAt DATETIME2 NULL,
    Priority NVARCHAR(20) NOT NULL DEFAULT 'normal',
    FromUserId INT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    ExpiresAt DATETIME2 NULL,
    CONSTRAINT FK_Notifications_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
    CONSTRAINT FK_Notifications_FromUser FOREIGN KEY (FromUserId) REFERENCES Users(Id)
);

-- Create UserActivities table
CREATE TABLE UserActivities (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    ActivityType NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500) NULL,
    EntityType NVARCHAR(50) NULL,
    EntityId INT NULL,
    ProductName NVARCHAR(50) NOT NULL,
    Metadata NVARCHAR(MAX) NULL,
    IpAddress NVARCHAR(45) NULL,
    UserAgent NVARCHAR(255) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CONSTRAINT FK_UserActivities_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE
);

-- Create indexes for performance
CREATE INDEX IX_Comments_EntityTypeId ON Comments(EntityType, EntityId);
CREATE INDEX IX_Comments_UserId ON Comments(UserId);
CREATE INDEX IX_Comments_CreatedAt ON Comments(CreatedAt DESC);

CREATE INDEX IX_CommentMentions_MentionedUserId ON CommentMentions(MentionedUserId);
CREATE INDEX IX_CommentMentions_IsRead ON CommentMentions(IsRead);

CREATE INDEX IX_Notifications_UserId ON Notifications(UserId);
CREATE INDEX IX_Notifications_IsRead ON Notifications(IsRead);
CREATE INDEX IX_Notifications_CreatedAt ON Notifications(CreatedAt DESC);

CREATE INDEX IX_UserActivities_UserId ON UserActivities(UserId);
CREATE INDEX IX_UserActivities_ProductName ON UserActivities(ProductName);
CREATE INDEX IX_UserActivities_CreatedAt ON UserActivities(CreatedAt DESC);

-- Create UserProfiles and UserPreferences for existing users
INSERT INTO UserProfiles (UserId, CreatedAt, UpdatedAt)
SELECT Id, GETUTCDATE(), GETUTCDATE()
FROM Users
WHERE NOT EXISTS (SELECT 1 FROM UserProfiles WHERE UserProfiles.UserId = Users.Id);

INSERT INTO UserPreferences (UserId, CreatedAt, UpdatedAt)
SELECT Id, GETUTCDATE(), GETUTCDATE()
FROM Users
WHERE NOT EXISTS (SELECT 1 FROM UserPreferences WHERE UserPreferences.UserId = Users.Id);

-- Add system notification for all users about the new features
INSERT INTO Notifications (UserId, Type, Title, Message, Priority, CreatedAt)
SELECT Id, 'system', 'New User Profile Features Available', 
       'Welcome to the enhanced user experience! You can now customize your profile, set preferences, and collaborate with comments and mentions.',
       'high', GETUTCDATE()
FROM Users
WHERE IsActive = 1;

-- Print summary
DECLARE @UserCount INT;
SELECT @UserCount = COUNT(*) FROM Users;

PRINT 'User Profile System tables created successfully';
PRINT 'Created tables: UserProfiles, UserPreferences, Comments, CommentMentions, CommentReactions, Notifications, UserActivities';
PRINT 'Created profiles and preferences for ' + CAST(@UserCount AS NVARCHAR(10)) + ' existing users';