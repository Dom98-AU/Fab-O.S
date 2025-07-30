-- Fix all numeric columns that should be decimal instead of int
-- This script handles the conversion for existing data

-- Package table fixes
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Packages]') AND name = 'LaborRatePerHour' AND system_type_id = 56) -- 56 = int
BEGIN
    PRINT 'Converting Package.LaborRatePerHour from int to decimal...'
    ALTER TABLE [dbo].[Packages]
    ALTER COLUMN [LaborRatePerHour] decimal(18,2) NOT NULL;
END

-- ProcessingItems table fixes
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'Weight' AND system_type_id = 56)
BEGIN
    PRINT 'Converting ProcessingItems.Weight from int to decimal...'
    ALTER TABLE [dbo].[ProcessingItems]
    ALTER COLUMN [Weight] decimal(18,3) NOT NULL;
END

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'ProcessingHours' AND system_type_id = 56)
BEGIN
    PRINT 'Converting ProcessingItems.ProcessingHours from int to decimal...'
    ALTER TABLE [dbo].[ProcessingItems]
    ALTER COLUMN [ProcessingHours] decimal(18,2) NOT NULL;
END

-- FabricationItems table fixes
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[FabricationItems]') AND name = 'Weight' AND system_type_id = 56)
BEGIN
    PRINT 'Converting FabricationItems.Weight from int to decimal...'
    ALTER TABLE [dbo].[FabricationItems]
    ALTER COLUMN [Weight] decimal(18,3) NOT NULL;
END

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[FabricationItems]') AND name = 'FabricationHours' AND system_type_id = 56)
BEGIN
    PRINT 'Converting FabricationItems.FabricationHours from int to decimal...'
    ALTER TABLE [dbo].[FabricationItems]
    ALTER COLUMN [FabricationHours] decimal(18,2) NOT NULL;
END

-- WeldingItems - already handled but let's make sure
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'WeldLength' AND system_type_id = 56)
BEGIN
    PRINT 'Converting WeldingItems.WeldLength from int to decimal...'
    ALTER TABLE [dbo].[WeldingItems]
    ALTER COLUMN [WeldLength] decimal(18,2) NOT NULL;
END

-- Add any missing columns with proper defaults for existing records
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'WeldingConnectionId')
BEGIN
    ALTER TABLE [dbo].[WeldingItems]
    ADD [WeldingConnectionId] int NULL;
    
    ALTER TABLE [dbo].[WeldingItems]
    ADD CONSTRAINT [FK_WeldingItems_WeldingConnections] 
    FOREIGN KEY ([WeldingConnectionId]) REFERENCES [dbo].[WeldingConnections] ([Id]) 
    ON DELETE SET NULL;
END

-- Verify all changes
PRINT ''
PRINT 'Verification of column types:'
PRINT '============================='

SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.precision,
    c.scale,
    CASE 
        WHEN ty.name = 'decimal' THEN 'OK'
        WHEN ty.name = 'int' AND c.name IN ('Id', 'Quantity', 'ConnectionQty', 'PackageId', 'EstimationId', 'PackageWorksheetId', 'WeldingConnectionId') THEN 'OK - ID/Qty field'
        ELSE 'NEEDS REVIEW'
    END AS Status
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name IN ('Packages', 'WeldingItems', 'ProcessingItems', 'FabricationItems')
    AND (c.name LIKE '%Hour%' OR c.name LIKE '%Rate%' OR c.name LIKE '%Weight%' 
         OR c.name IN ('AssembleFitTack', 'Weld', 'WeldCheck', 'WeldLength'))
ORDER BY t.name, c.name;

PRINT 'Migration completed successfully';