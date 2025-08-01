-- =============================================
-- Verify Database Context and Table Details
-- Description: Checks current database and Users table details
-- Date: 2025-08-01
-- =============================================

-- Show current database
PRINT 'Current Database: ' + DB_NAME();
PRINT '';

-- Find all Users tables in current database
PRINT 'All Users tables in this database:';
SELECT 
    s.name AS SchemaName,
    t.name AS TableName,
    t.object_id,
    t.create_date
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.name = 'Users'
ORDER BY s.name, t.name;

PRINT '';
PRINT 'Checking dbo.Users table specifically:';

-- Check columns in dbo.Users specifically
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL
BEGIN
    SELECT 
        c.name AS ColumnName,
        TYPE_NAME(c.system_type_id) AS DataType,
        c.max_length,
        c.is_nullable
    FROM sys.columns c
    WHERE c.object_id = OBJECT_ID('dbo.Users')
    AND c.name IN ('Email', 'PasswordHash', 'PasswordSalt', 'AuthProvider', 'ExternalUserId')
    ORDER BY c.name;
END
ELSE
BEGIN
    PRINT 'dbo.Users table does not exist';
END

-- Also check without schema prefix
PRINT '';
PRINT 'Checking Users table (no schema prefix):';
SELECT 
    SCHEMA_NAME(schema_id) AS SchemaName,
    name AS TableName
FROM sys.tables 
WHERE name = 'Users';

-- Show exactly which table the columns were found in
PRINT '';
PRINT 'Tables containing AuthProvider column:';
SELECT 
    SCHEMA_NAME(t.schema_id) + '.' + t.name AS FullTableName,
    c.name AS ColumnName
FROM sys.columns c
INNER JOIN sys.tables t ON c.object_id = t.object_id
WHERE c.name = 'AuthProvider';