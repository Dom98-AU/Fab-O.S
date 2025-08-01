-- =============================================
-- Step 2: Add Auth Columns
-- Description: Adds AuthProvider and ExternalUserId columns
-- Date: 2025-08-01
-- =============================================

-- Add AuthProvider column
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'AuthProvider')
BEGIN
    ALTER TABLE Users ADD AuthProvider nvarchar(50) NULL;
    
    -- Set default value for existing records
    UPDATE Users SET AuthProvider = 'Local' WHERE AuthProvider IS NULL;
    
    -- Now make it NOT NULL with default
    ALTER TABLE Users ALTER COLUMN AuthProvider nvarchar(50) NOT NULL;
    ALTER TABLE Users ADD CONSTRAINT DF_Users_AuthProvider DEFAULT 'Local' FOR AuthProvider;
    
    PRINT 'SUCCESS: Added AuthProvider column to Users table';
END
ELSE
BEGIN
    PRINT 'AuthProvider column already exists';
END

-- Add ExternalUserId column
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'ExternalUserId')
BEGIN
    ALTER TABLE Users ADD ExternalUserId nvarchar(256) NULL;
    PRINT 'SUCCESS: Added ExternalUserId column to Users table';
END
ELSE
BEGIN
    PRINT 'ExternalUserId column already exists';
END

-- Show all columns
SELECT 
    c.name AS ColumnName,
    t.name AS DataType,
    c.max_length,
    c.is_nullable
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('Users') 
AND c.name IN ('PasswordSalt', 'AuthProvider', 'ExternalUserId')
ORDER BY c.name;

PRINT '';
PRINT 'Run Step3_UpdateAdminPassword.sql next';