-- Check Database State Before Migration
-- Generated: 2025-01-03
-- Description: Checks if migration has already been applied

-- Check if tables exist
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'WeldingConnections')
    PRINT 'WeldingConnections table already exists'
ELSE
    PRINT 'WeldingConnections table does not exist'

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'ImageUploads')
    PRINT 'ImageUploads table already exists'
ELSE
    PRINT 'ImageUploads table does not exist'

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'WorksheetChanges')
    PRINT 'WorksheetChanges table already exists'
ELSE
    PRINT 'WorksheetChanges table does not exist'

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'PackageWeldingConnections')
    PRINT 'PackageWeldingConnections table already exists'
ELSE
    PRINT 'PackageWeldingConnections table does not exist'

-- Check if columns exist in WeldingItems
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'WeldingConnectionId')
    PRINT 'WeldingConnectionId column already exists in WeldingItems'
ELSE
    PRINT 'WeldingConnectionId column does not exist in WeldingItems'

-- Check data type of time fields in WeldingItems
SELECT 
    c.name AS ColumnName,
    t.name AS DataType,
    c.precision,
    c.scale
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID(N'[dbo].[WeldingItems]') 
    AND c.name IN ('AssembleFitTack', 'Weld', 'WeldCheck')
ORDER BY c.name;

-- Check if Description exists in Projects
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'Description')
    PRINT 'Description column already exists in Projects'
ELSE
    PRINT 'Description column does not exist in Projects'

-- Count existing data that might be affected
SELECT 'WeldingItems' as TableName, COUNT(*) as RecordCount FROM [dbo].[WeldingItems]
UNION ALL
SELECT 'Projects' as TableName, COUNT(*) as RecordCount FROM [dbo].[Projects];