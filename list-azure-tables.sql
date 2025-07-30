-- List all tables in sqldb-steel-estimation-sandbox
-- Connect to: Server=nwiapps.database.windows.net;Database=sqldb-steel-estimation-sandbox

-- List all user tables with details
SELECT 
    s.name AS SchemaName,
    t.name AS TableName,
    p.rows AS RowCount,
    (SELECT COUNT(*) FROM sys.columns WHERE object_id = t.object_id) as ColumnCount,
    t.create_date AS CreatedDate,
    t.modify_date AS ModifiedDate
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0, 1) -- Heap or clustered index
ORDER BY s.name, t.name;

-- Summary count
SELECT COUNT(*) AS TotalTables FROM sys.tables;

-- Check for specific core tables
SELECT 'Core Tables Check' AS Category;
SELECT 
    TableName,
    CASE WHEN EXISTS (SELECT 1 FROM sys.tables WHERE name = TableName) 
         THEN 'EXISTS' 
         ELSE 'MISSING' 
    END AS Status
FROM (VALUES 
    ('Companies'),
    ('Users'),
    ('Roles'),
    ('UserRoles'),
    ('Projects'),
    ('Estimations'),
    ('Packages'),
    ('ProcessingItems'),
    ('WeldingItems'),
    ('PackageWorksheets'),
    ('EstimationPackages')
) AS CoreTables(TableName);

-- Check for new feature tables
SELECT 'New Feature Tables Check' AS Category;
SELECT 
    TableName,
    CASE WHEN EXISTS (SELECT 1 FROM sys.tables WHERE name = TableName) 
         THEN 'EXISTS' 
         ELSE 'MISSING' 
    END AS Status
FROM (VALUES 
    ('EstimationTimeLogs'),
    ('WeldingItemConnections'),
    ('EfficiencyRates'),
    ('PackBundles'),
    ('DeliveryBundles')
) AS NewTables(TableName);

-- List all columns for a specific table (example: Packages)
-- Uncomment and modify table name as needed
/*
SELECT 
    c.name AS ColumnName,
    t.name AS DataType,
    c.max_length,
    c.is_nullable,
    c.is_identity
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('dbo.Packages')
ORDER BY c.column_id;
*/

-- Database size info
SELECT 
    DB_NAME() AS DatabaseName,
    SUM(CASE WHEN type = 0 THEN size * 8.0 / 1024 ELSE 0 END) AS DataSizeMB,
    SUM(CASE WHEN type = 1 THEN size * 8.0 / 1024 ELSE 0 END) AS LogSizeMB
FROM sys.database_files;