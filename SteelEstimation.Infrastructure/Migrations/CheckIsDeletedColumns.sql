-- Check if IsDeleted columns exist
SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.is_nullable,
    dc.definition AS DefaultValue
FROM sys.tables t
LEFT JOIN sys.columns c ON t.object_id = c.object_id AND c.name = 'IsDeleted'
LEFT JOIN sys.types ty ON c.user_type_id = ty.user_type_id
LEFT JOIN sys.default_constraints dc ON c.default_object_id = dc.object_id
WHERE t.name IN ('ProcessingItems', 'WeldingItems')
ORDER BY t.name;

-- Check for related indexes
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
WHERE t.name IN ('ProcessingItems', 'WeldingItems')
    AND i.name LIKE '%IsDeleted%'
ORDER BY t.name, i.name;