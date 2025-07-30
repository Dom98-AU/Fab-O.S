-- Ensure data compatibility for existing estimations
-- This script updates existing data to work with the new schema

-- 1. First, check what columns exist in each table
PRINT 'Checking existing columns...'
PRINT '============================'

-- Check Packages table
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Packages]') AND name = 'LaborRatePerHour' AND system_type_id = 56)
BEGIN
    PRINT 'Converting Packages.LaborRatePerHour from int to decimal...'
    -- First add a temporary column
    ALTER TABLE [dbo].[Packages] ADD [LaborRatePerHour_Temp] decimal(18,2) NULL;
    -- Copy the data
    UPDATE [dbo].[Packages] SET [LaborRatePerHour_Temp] = CAST([LaborRatePerHour] AS decimal(18,2));
    -- Drop the old column
    ALTER TABLE [dbo].[Packages] DROP COLUMN [LaborRatePerHour];
    -- Rename the temp column
    EXEC sp_rename '[dbo].[Packages].[LaborRatePerHour_Temp]', 'LaborRatePerHour', 'COLUMN';
    -- Make it NOT NULL with default
    ALTER TABLE [dbo].[Packages] ALTER COLUMN [LaborRatePerHour] decimal(18,2) NOT NULL;
END

-- 2. Ensure all new columns exist with proper defaults
-- Add missing columns to WeldingItems
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'WeldingConnectionId')
BEGIN
    ALTER TABLE [dbo].[WeldingItems] ADD [WeldingConnectionId] int NULL;
    PRINT 'Added WeldingConnectionId to WeldingItems'
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'IsDeleted')
BEGIN
    ALTER TABLE [dbo].[WeldingItems] ADD [IsDeleted] bit NOT NULL DEFAULT 0;
    PRINT 'Added IsDeleted to WeldingItems'
END

-- Add missing columns to ProcessingItems
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'IsDeleted')
BEGIN
    ALTER TABLE [dbo].[ProcessingItems] ADD [IsDeleted] bit NOT NULL DEFAULT 0;
    PRINT 'Added IsDeleted to ProcessingItems'
END

-- Add missing columns to Packages
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Packages]') AND name = 'IsDeleted')
BEGIN
    ALTER TABLE [dbo].[Packages] ADD [IsDeleted] bit NOT NULL DEFAULT 0;
    PRINT 'Added IsDeleted to Packages'
END

-- Add missing columns to Projects
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Projects]') AND name = 'Description')
BEGIN
    ALTER TABLE [dbo].[Projects] ADD [Description] nvarchar(max) NULL;
    PRINT 'Added Description to Projects'
END

-- 3. Verify all numeric columns have correct types
PRINT ''
PRINT 'Final column type verification:'
PRINT '==============================='

SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.precision,
    c.scale,
    c.is_nullable
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name IN ('Packages', 'WeldingItems', 'ProcessingItems', 'Projects')
    AND c.name IN ('LaborRatePerHour', 'AssembleFitTack', 'Weld', 'WeldCheck', 'Weight', 
                   'WeldingConnectionId', 'IsDeleted', 'Description')
ORDER BY t.name, c.name;

-- 4. Update default values for any NULL labor rates
UPDATE [dbo].[Packages] 
SET [LaborRatePerHour] = 0 
WHERE [LaborRatePerHour] IS NULL;

PRINT ''
PRINT 'Data compatibility ensured successfully!'

-- 5. Sample data check
PRINT ''
PRINT 'Sample data from existing estimation:'
PRINT '====================================='

SELECT TOP 5
    p.Id,
    p.PackageName,
    p.LaborRatePerHour,
    (SELECT COUNT(*) FROM PackageWorksheets pw WHERE pw.PackageId = p.Id) AS WorksheetCount,
    (SELECT COUNT(*) FROM WeldingItems wi 
     INNER JOIN PackageWorksheets pw ON wi.PackageWorksheetId = pw.Id 
     WHERE pw.PackageId = p.Id) AS WeldingItemCount
FROM Packages p
WHERE p.IsDeleted = 0
ORDER BY p.Id;