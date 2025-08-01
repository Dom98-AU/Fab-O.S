-- =============================================
-- Fix Admin User Authentication
-- Description: Ensures admin user can login with proper password hash and salt
-- Date: 2025-08-01
-- =============================================

-- First run the column fix
-- This ensures PasswordSalt column exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'PasswordSalt')
BEGIN
    ALTER TABLE Users ADD PasswordSalt nvarchar(100) NULL;
    PRINT 'Added PasswordSalt column to Users table';
END

-- For the current authentication system using HMACSHA512
-- Password: Admin@123
-- Salt (base64): hJ0rD8KlJ1YhF6MJ8+GJ6w==
-- Hash (base64): 0kHs0FTVHDuKO7iqQqrjErGp5HVt1pqOlGZ2WCzrGxJo1jkoaZGxvkXDdpW3w0oNkHs3tDTmHWYlHlYRjcCFrg==

UPDATE Users 
SET 
    PasswordHash = '0kHs0FTVHDuKO7iqQqrjErGp5HVt1pqOlGZ2WCzrGxJo1jkoaZGxvkXDdpW3w0oNkHs3tDTmHWYlHlYRjcCFrg==',
    PasswordSalt = 'hJ0rD8KlJ1YhF6MJ8+GJ6w==',
    AuthProvider = ISNULL(AuthProvider, 'Local')
WHERE Email = 'admin@steelestimation.com';

IF @@ROWCOUNT > 0
BEGIN
    PRINT 'Updated admin user password successfully';
    PRINT '';
    PRINT '✅ You can now login with:';
    PRINT '   Email: admin@steelestimation.com';
    PRINT '   Password: Admin@123';
END
ELSE
BEGIN
    PRINT 'WARNING: Admin user not found. Creating new admin user...';
    
    -- Ensure NWI Group company exists
    DECLARE @CompanyId int;
    SELECT @CompanyId = Id FROM Companies WHERE Name = 'NWI Group';
    
    IF @CompanyId IS NULL
    BEGIN
        INSERT INTO Companies (Name, Code, IsActive, CreatedDate)
        VALUES ('NWI Group', 'NWI', 1, GETUTCDATE());
        SET @CompanyId = SCOPE_IDENTITY();
    END
    
    -- Create admin user
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
        '0kHs0FTVHDuKO7iqQqrjErGp5HVt1pqOlGZ2WCzrGxJo1jkoaZGxvkXDdpW3w0oNkHs3tDTmHWYlHlYRjcCFrg==',
        'hJ0rD8KlJ1YhF6MJ8+GJ6w==',
        'System',
        'Administrator',
        @CompanyId,
        1,
        1,
        'Local',
        GETUTCDATE()
    );
    
    -- Add admin role
    DECLARE @UserId int = SCOPE_IDENTITY();
    DECLARE @AdminRoleId int;
    SELECT @AdminRoleId = Id FROM Roles WHERE Name = 'Administrator';
    
    IF @AdminRoleId IS NOT NULL AND @UserId IS NOT NULL
    BEGIN
        INSERT INTO UserRoles (UserId, RoleId)
        VALUES (@UserId, @AdminRoleId);
    END
    
    PRINT 'Created new admin user successfully';
    PRINT '';
    PRINT '✅ You can now login with:';
    PRINT '   Email: admin@steelestimation.com';
    PRINT '   Password: Admin@123';
END

-- Verify the user exists with correct columns
SELECT 
    Email,
    CASE 
        WHEN PasswordHash IS NOT NULL THEN 'Has Password Hash' 
        ELSE 'Missing Password Hash' 
    END as PasswordStatus,
    CASE 
        WHEN PasswordSalt IS NOT NULL THEN 'Has Password Salt' 
        ELSE 'Missing Password Salt' 
    END as SaltStatus,
    ISNULL(AuthProvider, 'Not Set') as AuthProvider,
    IsActive
FROM Users
WHERE Email = 'admin@steelestimation.com';