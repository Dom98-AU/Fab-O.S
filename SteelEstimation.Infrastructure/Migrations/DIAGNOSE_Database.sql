-- =====================================================
-- Database Diagnostic Script
-- =====================================================
-- Run this to check the current state of your database

PRINT '========================================='
PRINT 'Database Diagnostic Report'
PRINT 'Database: ' + DB_NAME()
PRINT '========================================='
PRINT ''

-- Check if Users table exists and show its structure
PRINT 'Checking Users table...'
PRINT '-----------------------'

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Users')
BEGIN
    PRINT '✓ Users table exists'
    PRINT ''
    PRINT 'Users table columns:'
    SELECT 
        c.name AS ColumnName,
        t.name AS DataType,
        c.max_length AS MaxLength,
        c.is_nullable AS IsNullable,
        c.is_identity AS IsIdentity
    FROM sys.columns c
    INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
    WHERE c.object_id = OBJECT_ID(N'[dbo].[Users]')
    ORDER BY c.column_id
END
ELSE
BEGIN
    PRINT '✗ Users table NOT FOUND'
END

PRINT ''

-- Check if Company tables exist
PRINT 'Checking Company tables...'
PRINT '--------------------------'

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Companies')
BEGIN
    PRINT '✓ Companies table exists'
    SELECT COUNT(*) as RecordCount FROM Companies
END
ELSE
    PRINT '✗ Companies table NOT FOUND'

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'CompanyMaterialTypes')
    PRINT '✓ CompanyMaterialTypes table exists'
ELSE
    PRINT '✗ CompanyMaterialTypes table NOT FOUND'

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'CompanyMbeIdMappings')
    PRINT '✓ CompanyMbeIdMappings table exists'
ELSE
    PRINT '✗ CompanyMbeIdMappings table NOT FOUND'

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'CompanyMaterialPatterns')
    PRINT '✓ CompanyMaterialPatterns table exists'
ELSE
    PRINT '✗ CompanyMaterialPatterns table NOT FOUND'

PRINT ''

-- Check for CompanyId column specifically
PRINT 'Checking for CompanyId column...'
PRINT '--------------------------------'

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'CompanyId')
BEGIN
    PRINT '✓ CompanyId column EXISTS in Users table'
    
    -- Get column details
    SELECT 
        c.name AS ColumnName,
        t.name AS DataType,
        c.is_nullable AS IsNullable
    FROM sys.columns c
    INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
    WHERE c.object_id = OBJECT_ID(N'[dbo].[Users]') AND c.name = 'CompanyId'
END
ELSE
BEGIN
    PRINT '✗ CompanyId column NOT FOUND in Users table'
END

PRINT ''

-- Show all tables in database
PRINT 'All tables in database:'
PRINT '-----------------------'
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(TABLE_SCHEMA + '.' + TABLE_NAME)) as ColumnCount
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME

PRINT ''

-- Check for any errors in recent operations
PRINT 'Recent SQL Server errors (if any):'
PRINT '----------------------------------'
SELECT TOP 10
    error_datetime,
    error_number,
    error_severity,
    error_state,
    error_message
FROM sys.dm_db_xtp_nonclustered_index_stats
WHERE error_number > 0
ORDER BY error_datetime DESC

PRINT ''
PRINT '========================================='
PRINT 'End of Diagnostic Report'
PRINT '========================================='