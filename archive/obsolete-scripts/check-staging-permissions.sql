-- Check current permissions for the staging managed identity

-- 1. Check what roles the staging user has
SELECT 
    dp.name AS UserName,
    dp.type_desc AS UserType,
    dp.authentication_type_desc AS AuthType,
    STRING_AGG(r.name, ', ') AS Roles
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members rm ON dp.principal_id = rm.member_principal_id
LEFT JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
WHERE dp.name = 'app-steel-estimation-prod/slots/staging'
GROUP BY dp.name, dp.type_desc, dp.authentication_type_desc;

-- 2. Check specific permissions
SELECT 
    p.permission_name,
    p.state_desc,
    p.class_desc,
    OBJECT_NAME(p.major_id) as object_name
FROM sys.database_permissions p
JOIN sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
WHERE dp.name = 'app-steel-estimation-prod/slots/staging'
ORDER BY p.permission_name;

-- 3. Double-check role memberships
SELECT 
    r.name AS RoleName,
    rm.role_principal_id,
    rm.member_principal_id
FROM sys.database_role_members rm
JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
JOIN sys.database_principals m ON rm.member_principal_id = m.principal_id
WHERE m.name = 'app-steel-estimation-prod/slots/staging';