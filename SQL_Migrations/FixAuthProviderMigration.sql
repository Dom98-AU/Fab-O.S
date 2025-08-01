-- =============================================
-- Fix for Partial Authentication Provider Migration
-- Description: Fixes issues from the initial migration
-- Date: 2025-08-01
-- =============================================

BEGIN TRANSACTION;

-- 1. Check if AuthProvider and ExternalUserId columns were added successfully
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'AuthProvider')
BEGIN
    PRINT 'AuthProvider column already exists in Users table';
END

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'ExternalUserId')
BEGIN
    PRINT 'ExternalUserId column already exists in Users table';
END

-- 2. Fix the stored procedure with correct column references
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
        
        -- Insert user with proper columns
        INSERT INTO Users (
            Email, 
            Username, 
            FirstName,
            LastName,
            AuthProvider, 
            ExternalUserId, 
            CompanyId, 
            IsActive, 
            IsEmailConfirmed, 
            CreatedAt,
            PasswordHash  -- Set to NULL for social logins
        )
        VALUES (
            @Email, 
            @DisplayName,
            SUBSTRING(@DisplayName, 1, CHARINDEX(' ', @DisplayName + ' ') - 1), -- First name
            SUBSTRING(@DisplayName, CHARINDEX(' ', @DisplayName + ' ') + 1, LEN(@DisplayName)), -- Last name
            @AuthProvider, 
            @ExternalUserId, 
            @CompanyId, 
            1, 
            1, 
            GETUTCDATE(),
            NULL  -- No password for social logins
        );
        
        SET @UserId = SCOPE_IDENTITY();
        
        -- Create auth method record
        INSERT INTO UserAuthMethods (UserId, AuthProvider, ExternalUserId, Email, DisplayName)
        VALUES (@UserId, @AuthProvider, @ExternalUserId, @Email, @DisplayName);
        
        -- Grant default role (Viewer)
        DECLARE @ViewerRoleId int;
        SELECT @ViewerRoleId = Id FROM Roles WHERE Name = 'Viewer';
        
        IF @ViewerRoleId IS NOT NULL
        BEGIN
            INSERT INTO UserRoles (UserId, RoleId)
            VALUES (@UserId, @ViewerRoleId);
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

-- 3. Verify OAuthProviderSettings table exists and has Microsoft enabled
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'OAuthProviderSettings')
BEGIN
    PRINT 'OAuthProviderSettings table exists';
    
    -- Check if Microsoft is enabled
    IF EXISTS (SELECT * FROM OAuthProviderSettings WHERE ProviderName = 'Microsoft' AND IsEnabled = 1)
    BEGIN
        PRINT 'Microsoft authentication is enabled in OAuthProviderSettings';
    END
    ELSE
    BEGIN
        -- Enable Microsoft if it exists but is disabled
        UPDATE OAuthProviderSettings SET IsEnabled = 1 WHERE ProviderName = 'Microsoft';
        PRINT 'Enabled Microsoft authentication in OAuthProviderSettings';
    END
END
ELSE
BEGIN
    PRINT 'ERROR: OAuthProviderSettings table does not exist - please check the migration';
END

COMMIT TRANSACTION;

PRINT '=============================================';
PRINT 'Authentication provider fix completed';
PRINT '=============================================';