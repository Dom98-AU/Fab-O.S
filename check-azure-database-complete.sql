-- =============================================
-- Azure SQL Database Complete Check
-- Database: sqldb-steel-estimation-sandbox
-- =============================================

-- 1. List all tables with row counts
PRINT '=== ALL TABLES IN DATABASE ==='
SELECT 
    s.name AS SchemaName,
    t.name AS TableName,
    p.rows AS RowCount,
    (SELECT COUNT(*) FROM sys.columns WHERE object_id = t.object_id) as ColumnCount
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0, 1)
ORDER BY s.name, t.name;

-- 2. Check for Customer Management tables
PRINT ''
PRINT '=== CUSTOMER MANAGEMENT TABLES ==='
SELECT 
    CASE WHEN EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Customers') 
         THEN 'EXISTS' ELSE 'MISSING' END AS Customers,
    CASE WHEN EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Contacts') 
         THEN 'EXISTS' ELSE 'MISSING' END AS Contacts,
    CASE WHEN EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Addresses') 
         THEN 'EXISTS' ELSE 'MISSING' END AS Addresses;

-- 3. Check for new feature tables
PRINT ''
PRINT '=== NEW FEATURE TABLES ==='
SELECT 
    CASE WHEN EXISTS (SELECT 1 FROM sys.tables WHERE name = 'EstimationTimeLogs') 
         THEN 'EXISTS' ELSE 'MISSING' END AS EstimationTimeLogs,
    CASE WHEN EXISTS (SELECT 1 FROM sys.tables WHERE name = 'WeldingItemConnections') 
         THEN 'EXISTS' ELSE 'MISSING' END AS WeldingItemConnections,
    CASE WHEN EXISTS (SELECT 1 FROM sys.tables WHERE name = 'EfficiencyRates') 
         THEN 'EXISTS' ELSE 'MISSING' END AS EfficiencyRates,
    CASE WHEN EXISTS (SELECT 1 FROM sys.tables WHERE name = 'PackBundles') 
         THEN 'EXISTS' ELSE 'MISSING' END AS PackBundles,
    CASE WHEN EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DeliveryBundles') 
         THEN 'EXISTS' ELSE 'MISSING' END AS DeliveryBundles;

-- 4. Database size and statistics
PRINT ''
PRINT '=== DATABASE STATISTICS ==='
SELECT 
    DB_NAME() AS DatabaseName,
    (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0) AS TotalTables,
    (SELECT SUM(p.rows) FROM sys.tables t 
     INNER JOIN sys.partitions p ON t.object_id = p.object_id 
     WHERE p.index_id IN (0,1) AND t.is_ms_shipped = 0) AS TotalRows,
    CAST(SUM(size * 8.0 / 1024) AS DECIMAL(10,2)) AS DatabaseSizeMB
FROM sys.database_files
WHERE type = 0;

-- 5. Check Projects table for CustomerId column
PRINT ''
PRINT '=== PROJECTS TABLE CUSTOMER RELATIONSHIP ==='
SELECT 
    CASE WHEN EXISTS (
        SELECT 1 FROM sys.columns 
        WHERE object_id = OBJECT_ID('Projects') 
        AND name = 'CustomerId'
    ) THEN 'CustomerId column EXISTS in Projects table'
    ELSE 'CustomerId column MISSING from Projects table'
    END AS CustomerRelationshipStatus;