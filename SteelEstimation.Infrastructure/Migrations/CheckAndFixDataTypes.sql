-- Check data types for all numeric columns that might be causing issues
-- Check Package table
SELECT 
    c.COLUMN_NAME,
    c.DATA_TYPE,
    c.NUMERIC_PRECISION,
    c.NUMERIC_SCALE,
    c.IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS c
WHERE c.TABLE_NAME = 'Packages' 
    AND c.COLUMN_NAME IN ('LaborRatePerHour', 'TotalWeight', 'TotalHours')
ORDER BY c.ORDINAL_POSITION;

-- Check WeldingItems columns
SELECT 
    c.COLUMN_NAME,
    c.DATA_TYPE,
    c.NUMERIC_PRECISION,
    c.NUMERIC_SCALE,
    c.IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS c
WHERE c.TABLE_NAME = 'WeldingItems' 
    AND c.COLUMN_NAME IN ('AssembleFitTack', 'Weld', 'WeldCheck', 'ConnectionQty', 'WeldLength')
ORDER BY c.ORDINAL_POSITION;

-- Check ProcessingItems columns
SELECT 
    c.COLUMN_NAME,
    c.DATA_TYPE,
    c.NUMERIC_PRECISION,
    c.NUMERIC_SCALE,
    c.IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS c
WHERE c.TABLE_NAME = 'ProcessingItems' 
    AND c.COLUMN_NAME IN ('Quantity', 'Weight', 'ProcessingHours')
ORDER BY c.ORDINAL_POSITION;

-- Check FabricationItems columns
SELECT 
    c.COLUMN_NAME,
    c.DATA_TYPE,
    c.NUMERIC_PRECISION,
    c.NUMERIC_SCALE,
    c.IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS c
WHERE c.TABLE_NAME = 'FabricationItems' 
    AND c.COLUMN_NAME IN ('Quantity', 'Weight', 'FabricationHours')
ORDER BY c.ORDINAL_POSITION;

-- Sample data check
SELECT TOP 5 
    Id,
    PackageName,
    LaborRatePerHour,
    SQL_VARIANT_PROPERTY(LaborRatePerHour, 'BaseType') AS ActualType
FROM Packages;

-- Check for any int columns that should be decimal
SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.precision,
    c.scale
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name IN ('Packages', 'WeldingItems', 'ProcessingItems', 'FabricationItems')
    AND ty.name = 'int'
    AND c.name LIKE '%Hour%' OR c.name LIKE '%Rate%' OR c.name LIKE '%Weight%'
ORDER BY t.name, c.name;