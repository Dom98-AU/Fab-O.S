-- =====================================================
-- Simple Database Diagnostic
-- =====================================================

PRINT '========================================='
PRINT 'Database State Check'
PRINT 'Database: ' + DB_NAME()
PRINT '========================================='
PRINT ''

-- 1. Check Users table
PRINT '1. USERS TABLE CHECK:'
PRINT '--------------------'
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Users')
BEGIN
    PRINT 'Users table: EXISTS'
    
    -- Show columns
    PRINT ''
    PRINT 'Users table columns:'
    SELECT 
        column_id as [#],
        name AS ColumnName,
        TYPE_NAME(user_type_id) AS DataType,
        max_length AS Size,
        CASE WHEN is_nullable = 1 THEN 'YES' ELSE 'NO' END AS Nullable
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'[dbo].[Users]')
    ORDER BY column_id
    
    -- Check for CompanyId specifically
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'CompanyId')
        PRINT 'CompanyId column: EXISTS'
    ELSE
        PRINT 'CompanyId column: NOT FOUND'
END
ELSE
BEGIN
    PRINT 'Users table: NOT FOUND!'
END

PRINT ''
PRINT '2. COMPANY TABLES CHECK:'
PRINT '------------------------'

-- Check each company table
DECLARE @TableName NVARCHAR(100)
DECLARE @Exists BIT

SET @TableName = 'Companies'
SET @Exists = CASE WHEN EXISTS (SELECT * FROM sys.tables WHERE name = @TableName) THEN 1 ELSE 0 END
PRINT @TableName + ': ' + CASE WHEN @Exists = 1 THEN 'EXISTS' ELSE 'NOT FOUND' END

SET @TableName = 'CompanyMaterialTypes'
SET @Exists = CASE WHEN EXISTS (SELECT * FROM sys.tables WHERE name = @TableName) THEN 1 ELSE 0 END
PRINT @TableName + ': ' + CASE WHEN @Exists = 1 THEN 'EXISTS' ELSE 'NOT FOUND' END

SET @TableName = 'CompanyMbeIdMappings'
SET @Exists = CASE WHEN EXISTS (SELECT * FROM sys.tables WHERE name = @TableName) THEN 1 ELSE 0 END
PRINT @TableName + ': ' + CASE WHEN @Exists = 1 THEN 'EXISTS' ELSE 'NOT FOUND' END

SET @TableName = 'CompanyMaterialPatterns'
SET @Exists = CASE WHEN EXISTS (SELECT * FROM sys.tables WHERE name = @TableName) THEN 1 ELSE 0 END
PRINT @TableName + ': ' + CASE WHEN @Exists = 1 THEN 'EXISTS' ELSE 'NOT FOUND' END

PRINT ''
PRINT '3. ALL TABLES IN DATABASE:'
PRINT '--------------------------'
SELECT 
    ROW_NUMBER() OVER (ORDER BY TABLE_NAME) as [#],
    TABLE_NAME as TableName
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE' 
ORDER BY TABLE_NAME

PRINT ''
PRINT '========================================='
PRINT 'End of Diagnostic'
PRINT '========================================='