-- Simple test to verify managed identity permissions
-- Run this in sqldb-steel-estimation-sandbox database

-- 1. Check current user context
SELECT 
    SUSER_NAME() AS CurrentLogin,
    USER_NAME() AS DatabaseUser,
    CONNECTIONPROPERTY('auth_scheme') AS AuthScheme;

-- 2. List all database users that might be the managed identity
SELECT 
    name,
    type_desc,
    authentication_type_desc,
    create_date
FROM sys.database_principals
WHERE type IN ('E', 'X') -- External users
   OR name LIKE '%app-%'
   OR name LIKE '%staging%'
ORDER BY create_date DESC;

-- 3. Check permissions for the staging managed identity
SELECT 
    p.permission_name,
    p.state_desc,
    r.name AS role_name
FROM sys.database_permissions p
LEFT JOIN sys.database_role_members rm ON p.grantee_principal_id = rm.member_principal_id
LEFT JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
WHERE p.grantee_principal_id = USER_ID('app-steel-estimation-prod/slots/staging')
   OR r.name IN ('db_datareader', 'db_datawriter')
GROUP BY p.permission_name, p.state_desc, r.name;