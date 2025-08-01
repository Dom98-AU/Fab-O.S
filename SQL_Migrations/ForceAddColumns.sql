-- Force add columns with explicit error handling
BEGIN TRY
    -- Add AuthProvider
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'AuthProvider')
    BEGIN
        EXEC('ALTER TABLE Users ADD AuthProvider nvarchar(50) NULL');
        PRINT 'Added AuthProvider column';
    END
END TRY
BEGIN CATCH
    PRINT 'ERROR adding AuthProvider: ' + ERROR_MESSAGE();
END CATCH
GO

BEGIN TRY
    -- Add ExternalUserId
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'ExternalUserId')
    BEGIN
        EXEC('ALTER TABLE Users ADD ExternalUserId nvarchar(256) NULL');
        PRINT 'Added ExternalUserId column';
    END
END TRY
BEGIN CATCH
    PRINT 'ERROR adding ExternalUserId: ' + ERROR_MESSAGE();
END CATCH
GO

-- Show final state
SELECT 
    name AS ColumnName,
    TYPE_NAME(system_type_id) AS DataType,
    max_length,
    is_nullable
FROM sys.columns 
WHERE object_id = OBJECT_ID('Users')
AND name IN ('PasswordSalt', 'AuthProvider', 'ExternalUserId', 'PasswordHash', 'Email')
ORDER BY name;