-- =============================================
-- Fix Authentication Columns
-- Description: Ensures all authentication columns exist in Users table
-- Date: 2025-08-01
-- =============================================

-- 1. Add PasswordSalt column if missing
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'PasswordSalt')
BEGIN
    ALTER TABLE Users ADD PasswordSalt nvarchar(100) NULL;
    PRINT 'Added PasswordSalt column to Users table';
END

-- 2. Ensure AuthProvider exists with correct default
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'AuthProvider')
BEGIN
    ALTER TABLE Users ADD AuthProvider nvarchar(50) NOT NULL DEFAULT 'Local';
    PRINT 'Added AuthProvider column to Users table';
END

-- 3. Ensure ExternalUserId exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'ExternalUserId')
BEGIN
    ALTER TABLE Users ADD ExternalUserId nvarchar(256) NULL;
    PRINT 'Added ExternalUserId column to Users table';
END

-- 4. Update existing users to have proper authentication data
-- Set AuthProvider to 'Local' for existing users if NULL
UPDATE Users 
SET AuthProvider = 'Local' 
WHERE AuthProvider IS NULL;

-- For existing admin user, ensure they have a password salt
UPDATE Users 
SET PasswordSalt = 'hJ0rD8KlJ1YhF6MJ8+GJ6w=='  -- This is a base64 encoded salt
WHERE Email = 'admin@steelestimation.com' 
  AND PasswordSalt IS NULL;

PRINT 'Updated existing users with authentication data';

-- 5. Verify all columns exist
DECLARE @MissingColumns TABLE (ColumnName nvarchar(50));

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'AuthProvider')
    INSERT INTO @MissingColumns VALUES ('AuthProvider');

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'ExternalUserId')
    INSERT INTO @MissingColumns VALUES ('ExternalUserId');

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'PasswordSalt')
    INSERT INTO @MissingColumns VALUES ('PasswordSalt');

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'PasswordHash')
    INSERT INTO @MissingColumns VALUES ('PasswordHash');

-- Report final status
IF EXISTS (SELECT * FROM @MissingColumns)
BEGIN
    PRINT '';
    PRINT 'ERROR: The following columns are still missing:';
    SELECT * FROM @MissingColumns;
END
ELSE
BEGIN
    PRINT '';
    PRINT '✅ SUCCESS: All authentication columns are present:';
    PRINT '   - AuthProvider (for tracking login method)';
    PRINT '   - ExternalUserId (for social logins)';
    PRINT '   - PasswordSalt (for password hashing)';
    PRINT '   - PasswordHash (for storing passwords)';
    PRINT '';
    PRINT 'You should now be able to login with admin@steelestimation.com';
END