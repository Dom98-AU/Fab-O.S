-- =============================================
-- Step 2: Add Auth Columns (Fixed with GO statements)
-- Description: Adds AuthProvider and ExternalUserId columns
-- Date: 2025-08-01
-- =============================================

-- Add AuthProvider column
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'AuthProvider')
BEGIN
    ALTER TABLE Users ADD AuthProvider nvarchar(50) NULL;
    PRINT 'SUCCESS: Added AuthProvider column to Users table';
END
ELSE
BEGIN
    PRINT 'AuthProvider column already exists';
END
GO

-- Update existing records to have 'Local' as AuthProvider
UPDATE Users SET AuthProvider = 'Local' WHERE AuthProvider IS NULL;
PRINT 'Updated existing users with Local auth provider';
GO

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
GO

-- Show the new columns
PRINT '';
PRINT 'Authentication columns in Users table:';
SELECT 
    c.name AS ColumnName,
    t.name AS DataType,
    c.max_length,
    c.is_nullable,
    CASE WHEN c.is_nullable = 1 THEN 'NULL' ELSE 'NOT NULL' END as Nullable
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('Users') 
AND c.name IN ('PasswordSalt', 'AuthProvider', 'ExternalUserId', 'PasswordHash')
ORDER BY c.name;

PRINT '';
PRINT 'Columns added successfully. Run Step3_UpdateAdminPassword.sql next';