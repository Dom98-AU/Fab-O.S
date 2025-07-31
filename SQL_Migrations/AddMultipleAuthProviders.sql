-- =============================================
-- Migration: Add Multiple Authentication Providers Support
-- Description: Enables users to sign up/login with email or social providers (Microsoft, Google)
-- Date: 2025-01-31
-- =============================================

BEGIN TRANSACTION;

-- 1. Add authentication provider columns to Users table
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'AuthProvider')
BEGIN
    ALTER TABLE Users ADD AuthProvider nvarchar(50) NOT NULL DEFAULT 'Local';
    PRINT 'Added AuthProvider column to Users table';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'ExternalUserId')
BEGIN
    ALTER TABLE Users ADD ExternalUserId nvarchar(256) NULL;
    PRINT 'Added ExternalUserId column to Users table';
END

-- 2. Make password fields nullable for social login users
ALTER TABLE Users ALTER COLUMN PasswordHash nvarchar(500) NULL;
ALTER TABLE Users ALTER COLUMN PasswordSalt nvarchar(100) NULL;
PRINT 'Made password fields nullable for social login support';

-- 3. Create UserAuthMethods table for multiple auth methods per user
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserAuthMethods')
BEGIN
    CREATE TABLE UserAuthMethods (
        Id int IDENTITY(1,1) PRIMARY KEY,
        UserId int NOT NULL,
        AuthProvider nvarchar(50) NOT NULL,
        ExternalUserId nvarchar(256) NULL,
        Email nvarchar(256) NULL, -- Provider email might differ from primary
        DisplayName nvarchar(256) NULL,
        ProfilePictureUrl nvarchar(500) NULL,
        LinkedDate datetime2 NOT NULL DEFAULT GETUTCDATE(),
        LastUsedDate datetime2 NULL,
        IsActive bit NOT NULL DEFAULT 1,
        CONSTRAINT FK_UserAuthMethods_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE
    );

    CREATE INDEX IX_UserAuthMethods_UserId ON UserAuthMethods(UserId);
    CREATE INDEX IX_UserAuthMethods_ExternalUserId ON UserAuthMethods(AuthProvider, ExternalUserId);
    CREATE UNIQUE INDEX IX_UserAuthMethods_User_Provider ON UserAuthMethods(UserId, AuthProvider) WHERE IsActive = 1;

    PRINT 'Created UserAuthMethods table';
END

-- 4. Create social login audit table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SocialLoginAudits')
BEGIN
    CREATE TABLE SocialLoginAudits (
        Id int IDENTITY(1,1) PRIMARY KEY,
        UserId int NULL,
        AuthProvider nvarchar(50) NOT NULL,
        EventType nvarchar(50) NOT NULL, -- 'Login', 'SignUp', 'Link', 'Unlink'
        Success bit NOT NULL,
        ErrorMessage nvarchar(500) NULL,
        IpAddress nvarchar(45) NULL,
        UserAgent nvarchar(500) NULL,
        EventDate datetime2 NOT NULL DEFAULT GETUTCDATE()
    );

    CREATE INDEX IX_SocialLoginAudits_UserId ON SocialLoginAudits(UserId);
    CREATE INDEX IX_SocialLoginAudits_EventDate ON SocialLoginAudits(EventDate);

    PRINT 'Created SocialLoginAudits table';
END

-- 5. Update unique constraint on Users table
-- First drop the existing unique constraint on Email if it exists
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Users_Email' AND object_id = OBJECT_ID('Users'))
BEGIN
    DROP INDEX IX_Users_Email ON Users;
END

-- Create a filtered unique index that only applies to active users
CREATE UNIQUE INDEX IX_Users_Email_Active ON Users(Email) WHERE IsActive = 1;
PRINT 'Updated Users email uniqueness constraint';

-- 6. Migrate existing users to have Local auth method records
PRINT 'Migrating existing users to UserAuthMethods...';

INSERT INTO UserAuthMethods (UserId, AuthProvider, Email, DisplayName, LinkedDate, LastUsedDate)
SELECT 
    u.Id,
    'Local' as AuthProvider,
    u.Email,
    u.Username as DisplayName,
    u.CreatedAt as LinkedDate,
    u.LastLoginDate as LastUsedDate
FROM Users u
WHERE NOT EXISTS (
    SELECT 1 FROM UserAuthMethods uam 
    WHERE uam.UserId = u.Id AND uam.AuthProvider = 'Local'
);

PRINT 'Migrated ' + CAST(@@ROWCOUNT AS nvarchar(10)) + ' existing users to UserAuthMethods';

-- 7. Add configuration table for OAuth providers
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'OAuthProviderSettings')
BEGIN
    CREATE TABLE OAuthProviderSettings (
        Id int IDENTITY(1,1) PRIMARY KEY,
        ProviderName nvarchar(50) NOT NULL UNIQUE,
        IsEnabled bit NOT NULL DEFAULT 0,
        DisplayName nvarchar(100) NOT NULL,
        IconClass nvarchar(100) NULL, -- Font Awesome class
        ButtonColor nvarchar(20) NULL, -- CSS color
        SortOrder int NOT NULL DEFAULT 0,
        CreatedDate datetime2 NOT NULL DEFAULT GETUTCDATE(),
        ModifiedDate datetime2 NOT NULL DEFAULT GETUTCDATE()
    );

    -- Insert default providers
    INSERT INTO OAuthProviderSettings (ProviderName, IsEnabled, DisplayName, IconClass, ButtonColor, SortOrder)
    VALUES 
        ('Microsoft', 1, 'Continue with Microsoft', 'fab fa-microsoft', '#0078d4', 1),
        ('Google', 0, 'Continue with Google', 'fab fa-google', '#4285f4', 2),
        ('LinkedIn', 0, 'Continue with LinkedIn', 'fab fa-linkedin', '#0077b5', 3);

    PRINT 'Created OAuthProviderSettings table with defaults';
END

-- 8. Add stored procedure to handle social login
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'sp_HandleSocialLogin')
    DROP PROCEDURE sp_HandleSocialLogin;
GO

CREATE PROCEDURE sp_HandleSocialLogin
    @Email nvarchar(256),
    @AuthProvider nvarchar(50),
    @ExternalUserId nvarchar(256),
    @DisplayName nvarchar(256),
    @CompanyId int = NULL,
    @UserId int OUTPUT,
    @IsNewUser bit OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if user exists with this email
    SELECT @UserId = Id FROM Users WHERE Email = @Email AND IsActive = 1;
    
    IF @UserId IS NULL
    BEGIN
        -- Create new user
        SET @IsNewUser = 1;
        
        -- If no company provided, create a default one
        IF @CompanyId IS NULL
        BEGIN
            DECLARE @CompanyName nvarchar(200) = SUBSTRING(@Email, CHARINDEX('@', @Email) + 1, LEN(@Email));
            INSERT INTO Companies (Name, Code, IsActive, CreatedDate)
            VALUES (@CompanyName, UPPER(LEFT(@CompanyName, 3)), 1, GETUTCDATE());
            SET @CompanyId = SCOPE_IDENTITY();
        END
        
        INSERT INTO Users (Email, Username, AuthProvider, ExternalUserId, CompanyId, IsActive, IsEmailConfirmed, CreatedDate)
        VALUES (@Email, @DisplayName, @AuthProvider, @ExternalUserId, @CompanyId, 1, 1, GETUTCDATE());
        
        SET @UserId = SCOPE_IDENTITY();
        
        -- Create auth method record
        INSERT INTO UserAuthMethods (UserId, AuthProvider, ExternalUserId, Email, DisplayName)
        VALUES (@UserId, @AuthProvider, @ExternalUserId, @Email, @DisplayName);
        
        -- Grant default Estimate access
        DECLARE @EstimateLicenseId int;
        SELECT @EstimateLicenseId = Id FROM ProductLicenses 
        WHERE CompanyId = @CompanyId AND ProductName = 'Estimate' AND IsActive = 1;
        
        IF @EstimateLicenseId IS NOT NULL
        BEGIN
            INSERT INTO UserProductAccess (UserId, ProductLicenseId)
            VALUES (@UserId, @EstimateLicenseId);
        END
    END
    ELSE
    BEGIN
        -- Existing user - check if this auth method is linked
        SET @IsNewUser = 0;
        
        IF NOT EXISTS (SELECT 1 FROM UserAuthMethods WHERE UserId = @UserId AND AuthProvider = @AuthProvider AND IsActive = 1)
        BEGIN
            -- Link this auth method
            INSERT INTO UserAuthMethods (UserId, AuthProvider, ExternalUserId, Email, DisplayName)
            VALUES (@UserId, @AuthProvider, @ExternalUserId, @Email, @DisplayName);
        END
        ELSE
        BEGIN
            -- Update last used date
            UPDATE UserAuthMethods 
            SET LastUsedDate = GETUTCDATE(),
                ExternalUserId = @ExternalUserId -- Update in case it changed
            WHERE UserId = @UserId AND AuthProvider = @AuthProvider;
        END
        
        -- Update user's last login
        UPDATE Users SET LastLoginDate = GETUTCDATE() WHERE Id = @UserId;
    END
END
GO

PRINT 'Created sp_HandleSocialLogin stored procedure';

COMMIT TRANSACTION;

PRINT '=============================================';
PRINT 'Multiple Authentication Providers migration completed successfully';
PRINT '=============================================';