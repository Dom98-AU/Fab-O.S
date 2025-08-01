-- =============================================
-- Add Missing PasswordSalt Column
-- Description: Adds the PasswordSalt column that's referenced in code but missing from database
-- Date: 2025-08-01
-- =============================================

-- Add PasswordSalt column if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'PasswordSalt')
BEGIN
    ALTER TABLE Users ADD PasswordSalt nvarchar(100) NULL;
    PRINT 'Added PasswordSalt column to Users table';
    
    -- Update existing users to have a salt value for their passwords
    UPDATE Users 
    SET PasswordSalt = CONVERT(nvarchar(100), NEWID())
    WHERE PasswordHash IS NOT NULL AND PasswordSalt IS NULL;
    
    PRINT 'Generated salt values for existing users with passwords';
END
ELSE
BEGIN
    PRINT 'PasswordSalt column already exists in Users table';
END

-- Verify all authentication columns exist
DECLARE @MissingColumns TABLE (ColumnName nvarchar(50));

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'AuthProvider')
    INSERT INTO @MissingColumns VALUES ('AuthProvider');

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'ExternalUserId')
    INSERT INTO @MissingColumns VALUES ('ExternalUserId');

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'PasswordSalt')
    INSERT INTO @MissingColumns VALUES ('PasswordSalt');

-- Report status
IF EXISTS (SELECT * FROM @MissingColumns)
BEGIN
    PRINT 'WARNING: The following columns are still missing:';
    SELECT * FROM @MissingColumns;
END
ELSE
BEGIN
    PRINT 'SUCCESS: All authentication columns are present in Users table';
    PRINT '- AuthProvider';
    PRINT '- ExternalUserId';
    PRINT '- PasswordSalt';
END