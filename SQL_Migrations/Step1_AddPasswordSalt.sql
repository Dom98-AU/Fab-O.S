-- =============================================
-- Step 1: Add PasswordSalt Column
-- Description: Adds only the PasswordSalt column
-- Date: 2025-08-01
-- =============================================

-- Add PasswordSalt column
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'PasswordSalt')
BEGIN
    ALTER TABLE Users ADD PasswordSalt nvarchar(100) NULL;
    PRINT 'SUCCESS: Added PasswordSalt column to Users table';
END
ELSE
BEGIN
    PRINT 'PasswordSalt column already exists';
END

-- Verify it was added
SELECT 
    c.name AS ColumnName,
    t.name AS DataType,
    c.max_length,
    c.is_nullable
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('Users') 
AND c.name = 'PasswordSalt';

PRINT '';
PRINT 'Run Step2_AddAuthColumns.sql next';