-- =============================================
-- Implement PasswordSalt Column with Proper Hash
-- Description: Adds PasswordSalt column and updates admin user with correctly salted password
-- Date: 2025-08-01
-- =============================================

-- Step 1: Add PasswordSalt column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'PasswordSalt')
BEGIN
    ALTER TABLE Users ADD PasswordSalt nvarchar(100) NULL;
    PRINT '✅ Added PasswordSalt column to Users table';
END
ELSE
BEGIN
    PRINT 'PasswordSalt column already exists';
END

-- Step 2: Generate and set password hash with salt for admin user
-- Using pre-computed values for Admin@123
-- These values were generated using HMACSHA512 algorithm matching FabOSAuthenticationService

DECLARE @Salt nvarchar(100) = 'nsYnK4MNzdfPHSCR3MbQnQ=='; -- Base64 encoded 16-byte salt
DECLARE @Hash nvarchar(500) = 'QLl0gbsufEANZI3gpGe+qfEoQ+GER6+lom/s/IL5XajgxXJC0qNsLa1qZt6fqKT3TrcFARkDi4bh7j02bnSEsA=='; -- HMACSHA512 hash

UPDATE Users 
SET 
    PasswordSalt = @Salt,
    PasswordHash = @Hash,
    AuthProvider = ISNULL(AuthProvider, 'Local')
WHERE Email = 'admin@steelestimation.com';

IF @@ROWCOUNT > 0
BEGIN
    PRINT '✅ Updated admin user with salted password';
END
ELSE
BEGIN
    PRINT '⚠️  Admin user not found - creating new admin user';
    
    -- Ensure NWI Group company exists
    DECLARE @CompanyId int;
    SELECT @CompanyId = Id FROM Companies WHERE Name = 'NWI Group';
    
    IF @CompanyId IS NULL
    BEGIN
        INSERT INTO Companies (Name, Code, IsActive, CreatedDate)
        VALUES ('NWI Group', 'NWI', 1, GETUTCDATE());
        SET @CompanyId = SCOPE_IDENTITY();
        PRINT '✅ Created NWI Group company';
    END
    
    -- Create admin user with proper salt and hash
    INSERT INTO Users (
        Username,
        Email,
        PasswordHash,
        PasswordSalt,
        FirstName,
        LastName,
        CompanyId,
        IsActive,
        IsEmailConfirmed,
        AuthProvider,
        CreatedAt
    )
    VALUES (
        'admin',
        'admin@steelestimation.com',
        @Hash,
        @Salt,
        'System',
        'Administrator',
        @CompanyId,
        1,
        1,
        'Local',
        GETUTCDATE()
    );
    
    PRINT '✅ Created admin user with salted password';
    
    -- Add Administrator role
    DECLARE @UserId int = SCOPE_IDENTITY();
    DECLARE @AdminRoleId int;
    SELECT @AdminRoleId = Id FROM Roles WHERE Name = 'Administrator';
    
    IF @AdminRoleId IS NOT NULL
    BEGIN
        INSERT INTO UserRoles (UserId, RoleId)
        SELECT @UserId, @AdminRoleId
        WHERE NOT EXISTS (SELECT 1 FROM UserRoles WHERE UserId = @UserId AND RoleId = @AdminRoleId);
        PRINT '✅ Assigned Administrator role';
    END
END

-- Step 3: Update all existing users with passwords to have salts
-- For users with passwords but no salt, generate a temporary salt
UPDATE Users
SET PasswordSalt = CONVERT(nvarchar(100), NEWID())
WHERE PasswordHash IS NOT NULL 
  AND PasswordSalt IS NULL
  AND Email != 'admin@steelestimation.com';

PRINT 'Updated ' + CAST(@@ROWCOUNT AS nvarchar(10)) + ' other users with generated salts';

-- Step 4: Verify the setup
PRINT '';
PRINT '=== Verification ===';
SELECT 
    Email,
    Username,
    CASE WHEN PasswordHash IS NOT NULL THEN '✅ Has Hash' ELSE '❌ No Hash' END as HashStatus,
    CASE WHEN PasswordSalt IS NOT NULL THEN '✅ Has Salt' ELSE '❌ No Salt' END as SaltStatus,
    ISNULL(AuthProvider, 'Not Set') as AuthProvider,
    CASE WHEN IsActive = 1 THEN '✅ Active' ELSE '❌ Inactive' END as Status
FROM Users
WHERE Email = 'admin@steelestimation.com';

PRINT '';
PRINT '✅ Password salt implementation complete!';
PRINT '';
PRINT '📝 Login credentials:';
PRINT '   Email: admin@steelestimation.com';
PRINT '   Password: Admin@123';
PRINT '';
PRINT '🔐 The password is now properly salted and hashed using HMACSHA512';