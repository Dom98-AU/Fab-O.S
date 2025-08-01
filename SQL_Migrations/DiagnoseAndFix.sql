-- Diagnostic script to check and add missing columns

PRINT 'Checking Users table structure...';
PRINT '';

-- Check if Users table exists
IF OBJECT_ID('Users', 'U') IS NOT NULL
BEGIN
    PRINT 'Users table exists.';
    
    -- Check each column
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'PasswordSalt')
        PRINT '✓ PasswordSalt column EXISTS';
    ELSE
        PRINT '✗ PasswordSalt column MISSING';
        
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'AuthProvider')
        PRINT '✓ AuthProvider column EXISTS';
    ELSE
        PRINT '✗ AuthProvider column MISSING';
        
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'ExternalUserId')
        PRINT '✓ ExternalUserId column EXISTS';
    ELSE
        PRINT '✗ ExternalUserId column MISSING';
END
ELSE
BEGIN
    PRINT 'ERROR: Users table does not exist!';
END

PRINT '';
PRINT 'To add missing columns, run the individual ADD column scripts.';
PRINT 'If columns show as MISSING above, the ALTER TABLE commands did not execute.';