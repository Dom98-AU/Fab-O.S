-- Check what columns exist in Users table
SELECT 
    c.name AS ColumnName,
    t.name AS DataType,
    c.max_length,
    CASE WHEN c.is_nullable = 1 THEN 'YES' ELSE 'NO' END as IsNullable
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('Users')
ORDER BY c.column_id;