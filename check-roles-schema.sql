-- Check if Roles table exists
SELECT 
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE '%Role%'
ORDER BY TABLE_NAME;

-- Check if UserRoles table exists
SELECT 
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE '%UserRole%'
ORDER BY TABLE_NAME;

-- Check all columns in any table that might be role-related
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME LIKE '%Role%' OR COLUMN_NAME LIKE '%Role%'
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- Specifically check if there's a Roles table
SELECT 
    'Roles table exists' as Status
WHERE EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'Roles'
);

-- Check if there's a UserRoles junction table
SELECT 
    'UserRoles table exists' as Status
WHERE EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'UserRoles'
);