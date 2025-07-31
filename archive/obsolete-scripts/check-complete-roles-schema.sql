-- 1. Check if Roles table exists and its schema
SELECT 'Checking Roles table:' as Info;
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Roles'
ORDER BY ORDINAL_POSITION;

-- 2. Check UserRoles table schema
SELECT '';
SELECT 'Checking UserRoles table:' as Info;
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'UserRoles'
ORDER BY ORDINAL_POSITION;

-- 3. Check what roles exist in the Roles table
SELECT '';
SELECT 'Existing roles:' as Info;
SELECT * FROM Roles;

-- 4. Check if there's already an admin user
SELECT '';
SELECT 'Existing admin users:' as Info;
SELECT 
    u.*,
    ur.RoleId,
    r.RoleName
FROM Users u
LEFT JOIN UserRoles ur ON u.Id = ur.UserId
LEFT JOIN Roles r ON ur.RoleId = r.Id
WHERE u.Email = 'admin@steelestimation.com' OR u.Username = 'admin';