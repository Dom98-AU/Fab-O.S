-- Diagnose the int to decimal casting error
-- Run this to identify which column is causing the issue

PRINT 'Checking all numeric columns in related tables...'
PRINT '================================================'

-- Check all columns and their actual data types
SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.system_type_id AS TypeId,
    CASE 
        WHEN ty.name = 'int' THEN 'INTEGER'
        WHEN ty.name = 'decimal' THEN 'DECIMAL'
        WHEN ty.name = 'float' THEN 'FLOAT'
        WHEN ty.name = 'real' THEN 'REAL'
        WHEN ty.name = 'numeric' THEN 'NUMERIC'
        ELSE ty.name
    END AS TypeCategory,
    c.precision,
    c.scale
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name IN ('Packages', 'PackageWorksheets', 'WeldingItems', 'ProcessingItems', 'Projects', 'DeliveryBundles')
    AND ty.name IN ('int', 'decimal', 'float', 'real', 'numeric', 'money', 'smallmoney')
ORDER BY t.name, c.name;

-- Check for any columns that Entity Framework might expect as decimal but are int
PRINT ''
PRINT 'Potential problem columns (int columns that might need to be decimal):'
PRINT '====================================================================='

SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    'ALTER TABLE [dbo].[' + t.name + '] ALTER COLUMN [' + c.name + '] decimal(18,2) NOT NULL;' AS ConversionScript
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name IN ('Packages', 'PackageWorksheets', 'WeldingItems', 'ProcessingItems')
    AND ty.name = 'int'
    AND (
        c.name LIKE '%Rate%' OR 
        c.name LIKE '%Hour%' OR 
        c.name LIKE '%Cost%' OR
        c.name LIKE '%Price%' OR
        c.name IN ('AssembleFitTack', 'Weld', 'WeldCheck', 'Weight', 'WeldLength')
    )
ORDER BY t.name, c.name;

-- Check specific data from the estimation that's failing
PRINT ''
PRINT 'Data from estimation ID 1:'
PRINT '========================='

-- Get package data
SELECT 
    'Package' AS EntityType,
    p.Id,
    p.PackageName,
    p.LaborRatePerHour,
    SQL_VARIANT_PROPERTY(p.LaborRatePerHour, 'BaseType') AS LaborRateType
FROM Projects pr
INNER JOIN Packages p ON pr.Id = p.ProjectId
WHERE pr.Id = 1;

-- Get welding items data
SELECT TOP 5
    'WeldingItem' AS EntityType,
    wi.Id,
    wi.AssembleFitTack,
    SQL_VARIANT_PROPERTY(wi.AssembleFitTack, 'BaseType') AS AssembleFitTackType,
    wi.Weld,
    SQL_VARIANT_PROPERTY(wi.Weld, 'BaseType') AS WeldType,
    wi.WeldCheck,
    SQL_VARIANT_PROPERTY(wi.WeldCheck, 'BaseType') AS WeldCheckType
FROM Projects pr
INNER JOIN Packages p ON pr.Id = p.ProjectId
INNER JOIN PackageWorksheets pw ON p.Id = pw.PackageId
INNER JOIN WeldingItems wi ON pw.Id = wi.PackageWorksheetId
WHERE pr.Id = 1;