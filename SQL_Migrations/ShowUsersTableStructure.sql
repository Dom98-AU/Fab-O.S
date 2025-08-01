-- =============================================
-- Show Users Table Structure with Data Types
-- Description: Displays all columns with their exact data types and properties
-- Date: 2025-08-01
-- =============================================

PRINT 'Database: ' + DB_NAME();
PRINT 'Table: dbo.Users';
PRINT '';
PRINT 'Complete column list with data types:';
PRINT '=====================================';

SELECT 
    c.column_id AS [#],
    c.name AS ColumnName,
    TYPE_NAME(c.system_type_id) AS DataType,
    CASE 
        WHEN TYPE_NAME(c.system_type_id) IN ('nvarchar', 'varchar', 'char', 'nchar') 
        THEN TYPE_NAME(c.system_type_id) + '(' + 
             CASE WHEN c.max_length = -1 THEN 'MAX' 
                  WHEN TYPE_NAME(c.system_type_id) IN ('nvarchar', 'nchar') THEN CAST(c.max_length/2 AS varchar(10))
                  ELSE CAST(c.max_length AS varchar(10)) 
             END + ')'
        WHEN TYPE_NAME(c.system_type_id) IN ('decimal', 'numeric') 
        THEN TYPE_NAME(c.system_type_id) + '(' + CAST(c.precision AS varchar(10)) + ',' + CAST(c.scale AS varchar(10)) + ')'
        ELSE TYPE_NAME(c.system_type_id)
    END AS FullDataType,
    CASE WHEN c.is_nullable = 1 THEN 'YES' ELSE 'NO' END AS Nullable,
    CASE WHEN c.is_identity = 1 THEN 'YES' ELSE 'NO' END AS IsIdentity
FROM sys.columns c
WHERE c.object_id = OBJECT_ID('dbo.Users')
ORDER BY c.column_id;

PRINT '';
PRINT 'Authentication-related columns specifically:';
PRINT '==========================================';

SELECT 
    c.name AS ColumnName,
    TYPE_NAME(c.system_type_id) AS DataType,
    c.max_length AS MaxLengthBytes,
    CASE 
        WHEN TYPE_NAME(c.system_type_id) = 'nvarchar' THEN c.max_length/2
        ELSE c.max_length
    END AS ActualMaxChars,
    CASE WHEN c.is_nullable = 1 THEN 'NULL' ELSE 'NOT NULL' END AS Nullable
FROM sys.columns c
WHERE c.object_id = OBJECT_ID('dbo.Users')
AND c.name IN ('Email', 'Username', 'PasswordHash', 'PasswordSalt', 'AuthProvider', 'ExternalUserId')
ORDER BY c.name;