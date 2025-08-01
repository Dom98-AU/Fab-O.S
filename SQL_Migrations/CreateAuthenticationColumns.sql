-- =============================================
-- Create Authentication Columns
-- Description: Creates all required authentication columns before updating data
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

-- Step 2: Add AuthProvider column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'AuthProvider')
BEGIN
    ALTER TABLE Users ADD AuthProvider nvarchar(50) NOT NULL DEFAULT 'Local';
    PRINT '✅ Added AuthProvider column to Users table';
END
ELSE
BEGIN
    PRINT 'AuthProvider column already exists';
END

-- Step 3: Add ExternalUserId column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'ExternalUserId')
BEGIN
    ALTER TABLE Users ADD ExternalUserId nvarchar(256) NULL;
    PRINT '✅ Added ExternalUserId column to Users table';
END
ELSE
BEGIN
    PRINT 'ExternalUserId column already exists';
END

-- Step 4: Wait a moment to ensure schema changes are committed
WAITFOR DELAY '00:00:01';

-- Step 5: Verify all columns now exist
DECLARE @ColumnCheck TABLE (ColumnName nvarchar(50), Exists bit);

INSERT INTO @ColumnCheck (ColumnName, Exists)
SELECT 'PasswordSalt', CASE WHEN EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'PasswordSalt') THEN 1 ELSE 0 END
UNION ALL
SELECT 'AuthProvider', CASE WHEN EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'AuthProvider') THEN 1 ELSE 0 END
UNION ALL
SELECT 'ExternalUserId', CASE WHEN EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'ExternalUserId') THEN 1 ELSE 0 END;

SELECT * FROM @ColumnCheck;

-- Step 6: Only proceed with updates if all columns exist
IF NOT EXISTS (SELECT * FROM @ColumnCheck WHERE Exists = 0)
BEGIN
    PRINT '';
    PRINT '✅ All authentication columns are present. Updating admin user...';
    
    -- Password: Admin@123
    -- Salt and Hash generated using HMACSHA512
    DECLARE @Salt nvarchar(100) = 'nsYnK4MNzdfPHSCR3MbQnQ==';
    DECLARE @Hash nvarchar(500) = 'QLl0gbsufEANZI3gpGe+qfEoQ+GER6+lom/s/IL5XajgxXJC0qNsLa1qZt6fqKT3TrcFARkDi4bh7j02bnSEsA==';
    
    UPDATE Users 
    SET 
        PasswordSalt = @Salt,
        PasswordHash = @Hash,
        AuthProvider = 'Local'
    WHERE Email = 'admin@steelestimation.com';
    
    IF @@ROWCOUNT > 0
    BEGIN
        PRINT '✅ Updated admin user with salted password';
        PRINT '';
        PRINT '📝 Login credentials:';
        PRINT '   Email: admin@steelestimation.com';
        PRINT '   Password: Admin@123';
    END
    ELSE
    BEGIN
        PRINT '⚠️  Admin user not found. You may need to create the user first.';
    END
END
ELSE
BEGIN
    PRINT '';
    PRINT '❌ ERROR: Not all columns were created successfully.';
    PRINT 'Please check the table schema and try again.';
END