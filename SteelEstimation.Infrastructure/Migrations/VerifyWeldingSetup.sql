-- Verify the welding worksheet setup is complete

PRINT 'Verifying Welding Worksheet Setup'
PRINT '================================='
PRINT ''

-- 1. Check WeldingConnections table
PRINT '1. WeldingConnections Table:'
SELECT COUNT(*) AS TotalConnections FROM WeldingConnections;

-- Show sample connections
SELECT TOP 5 
    Id, 
    Name, 
    Category, 
    Size,
    DefaultAssembleFitTack,
    DefaultWeld,
    DefaultWeldCheck,
    DefaultWeldTest,
    IsActive
FROM WeldingConnections
ORDER BY DisplayOrder;

-- 2. Check WeldingItems structure
PRINT ''
PRINT '2. WeldingItems Table Structure:'
SELECT 
    c.name AS ColumnName,
    ty.name AS DataType,
    c.is_nullable
FROM sys.columns c
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE c.object_id = OBJECT_ID(N'[dbo].[WeldingItems]')
    AND c.name IN ('WeldingConnectionId', 'AssembleFitTack', 'Weld', 'WeldCheck', 'WeldTest', 'IsDeleted')
ORDER BY c.name;

-- 3. Check ImageUploads structure
PRINT ''
PRINT '3. ImageUploads Table Structure:'
SELECT 
    c.name AS ColumnName,
    ty.name AS DataType,
    c.is_nullable
FROM sys.columns c
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE c.object_id = OBJECT_ID(N'[dbo].[ImageUploads]')
    AND c.name IN ('UploadedBy', 'WeldingItemId', 'FilePath', 'IsDeleted')
ORDER BY c.name;

-- 4. Check existing welding items
PRINT ''
PRINT '4. Existing Welding Items:'
SELECT 
    COUNT(*) AS TotalWeldingItems,
    COUNT(DISTINCT PackageWorksheetId) AS WorksheetsWithItems
FROM WeldingItems
WHERE IsDeleted = 0;

-- 5. Check for any welding worksheets
PRINT ''
PRINT '5. Welding Worksheets:'
SELECT 
    pw.Id,
    p.PackageName,
    pw.WorksheetName,
    pw.WorksheetType,
    (SELECT COUNT(*) FROM WeldingItems wi WHERE wi.PackageWorksheetId = pw.Id AND wi.IsDeleted = 0) AS ItemCount
FROM PackageWorksheets pw
INNER JOIN Packages p ON pw.PackageId = p.Id
WHERE pw.WorksheetType = 'Welding'
ORDER BY p.Id, pw.DisplayOrder;

PRINT ''
PRINT 'Verification complete!'