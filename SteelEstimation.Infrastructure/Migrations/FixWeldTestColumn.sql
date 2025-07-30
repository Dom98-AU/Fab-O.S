-- Fix WeldTest column type mismatch
-- Entity Framework expects decimal but database has int

-- Check current type of WeldTest column
SELECT 
    c.name AS ColumnName,
    ty.name AS DataType,
    c.precision,
    c.scale
FROM sys.columns c
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE c.object_id = OBJECT_ID(N'[dbo].[WeldingItems]') 
    AND c.name = 'WeldTest';

-- Convert WeldTest from int to decimal
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[WeldingItems]') AND name = 'WeldTest' AND system_type_id = 56) -- 56 = int
BEGIN
    PRINT 'Converting WeldingItems.WeldTest from int to decimal...';
    
    -- Show current values
    SELECT TOP 10 Id, DrawingNumber, WeldTest FROM WeldingItems;
    
    -- Convert the column
    ALTER TABLE [dbo].[WeldingItems]
    ALTER COLUMN [WeldTest] decimal(10,2) NOT NULL;
    
    PRINT 'Conversion complete!';
    
    -- Verify after conversion
    SELECT TOP 10 Id, DrawingNumber, WeldTest FROM WeldingItems;
END
ELSE
BEGIN
    PRINT 'WeldTest column is already the correct type or does not exist.';
END

-- Final verification of all WeldingItems numeric columns
PRINT ''
PRINT 'Final verification of WeldingItems numeric columns:';
SELECT 
    c.name AS ColumnName,
    ty.name AS DataType,
    c.precision,
    c.scale
FROM sys.columns c
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE c.object_id = OBJECT_ID(N'[dbo].[WeldingItems]') 
    AND c.name IN ('AssembleFitTack', 'Weld', 'WeldCheck', 'WeldTest', 'WeldLength')
ORDER BY c.name;