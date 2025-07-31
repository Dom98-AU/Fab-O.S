-- Check if the staging slot's managed identity has access to the database

-- 1. List all database users
SELECT 
    name AS UserName,
    type_desc AS UserType,
    authentication_type_desc AS AuthType,
    create_date,
    modify_date
FROM sys.database_principals
WHERE type IN ('S', 'U', 'E', 'X')  -- SQL user, Windows user, External user, External group
ORDER BY name;

-- 2. Check for app service managed identity users (they usually contain the app name)
SELECT 
    name AS UserName,
    type_desc AS UserType,
    authentication_type_desc AS AuthType
FROM sys.database_principals
WHERE name LIKE '%steel%' OR name LIKE '%app-%'
ORDER BY name;

-- 3. Check role memberships for managed identity users
SELECT 
    dp.name AS PrincipalName,
    dp.type_desc AS PrincipalType,
    dp2.name AS RoleName
FROM sys.database_role_members rm
JOIN sys.database_principals dp ON rm.member_principal_id = dp.principal_id
JOIN sys.database_principals dp2 ON rm.role_principal_id = dp2.principal_id
WHERE dp.name LIKE '%steel%' OR dp.name LIKE '%app-%'
ORDER BY dp.name, dp2.name;