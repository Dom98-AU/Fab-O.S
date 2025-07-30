-- Refresh Entity Framework metadata
-- This helps when column types have changed but EF still has old metadata cached

-- 1. Check for any computed columns that might be causing issues
PRINT 'Checking for computed columns...'
SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    c.is_computed,
    cc.definition AS ComputedDefinition
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
LEFT JOIN sys.computed_columns cc ON c.object_id = cc.object_id AND c.column_id = cc.column_id
WHERE t.name IN ('Packages', 'PackageWorksheets', 'WeldingItems', 'ProcessingItems')
    AND (c.is_computed = 1 OR cc.definition IS NOT NULL)
ORDER BY t.name, c.name;

-- 2. Check for any triggers that might be interfering
PRINT ''
PRINT 'Checking for triggers...'
SELECT 
    t.name AS TableName,
    tr.name AS TriggerName,
    tr.is_disabled
FROM sys.tables t
INNER JOIN sys.triggers tr ON t.object_id = tr.parent_id
WHERE t.name IN ('Packages', 'PackageWorksheets', 'WeldingItems', 'ProcessingItems')
ORDER BY t.name, tr.name;

-- 3. Check for any default constraints with wrong types
PRINT ''
PRINT 'Checking default constraints...'
SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    dc.name AS ConstraintName,
    dc.definition AS DefaultValue,
    ty.name AS DataType
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.default_constraints dc ON c.default_object_id = dc.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name IN ('Packages', 'PackageWorksheets', 'WeldingItems', 'ProcessingItems')
    AND ty.name IN ('decimal', 'int')
ORDER BY t.name, c.name;

-- 4. Update statistics to ensure query optimizer has fresh data
PRINT ''
PRINT 'Updating statistics...'
UPDATE STATISTICS [dbo].[Packages] WITH FULLSCAN;
UPDATE STATISTICS [dbo].[PackageWorksheets] WITH FULLSCAN;
UPDATE STATISTICS [dbo].[WeldingItems] WITH FULLSCAN;
UPDATE STATISTICS [dbo].[ProcessingItems] WITH FULLSCAN;

-- 5. Check if there are any views that might need refreshing
PRINT ''
PRINT 'Checking for views that might need refreshing...'
SELECT 
    v.name AS ViewName,
    m.definition
FROM sys.views v
INNER JOIN sys.sql_modules m ON v.object_id = m.object_id
WHERE m.definition LIKE '%Packages%' 
   OR m.definition LIKE '%WeldingItems%'
   OR m.definition LIKE '%ProcessingItems%';

-- 6. Force recompilation of stored procedures
PRINT ''
PRINT 'Marking stored procedures for recompilation...'
DECLARE @ProcName NVARCHAR(500)
DECLARE proc_cursor CURSOR FOR
    SELECT QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name)
    FROM sys.procedures
    WHERE OBJECT_DEFINITION(object_id) LIKE '%Packages%' 
       OR OBJECT_DEFINITION(object_id) LIKE '%WeldingItems%'
       OR OBJECT_DEFINITION(object_id) LIKE '%ProcessingItems%';

OPEN proc_cursor
FETCH NEXT FROM proc_cursor INTO @ProcName

WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC sp_recompile @ProcName;
    PRINT 'Marked for recompilation: ' + @ProcName;
    FETCH NEXT FROM proc_cursor INTO @ProcName
END

CLOSE proc_cursor
DEALLOCATE proc_cursor

PRINT ''
PRINT 'Metadata refresh completed.'