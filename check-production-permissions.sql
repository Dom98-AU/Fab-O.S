-- Check what roles the user has
SELECT 
    p.name AS PrincipalName,
    p.type_desc AS PrincipalType,
    r.name AS RoleName
FROM sys.database_role_members rm
JOIN sys.database_principals p ON rm.member_principal_id = p.principal_id
JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
WHERE p.name = 'app-steel-estimation-prod'
ORDER BY r.name;

-- If no roles are shown, grant them again
ALTER ROLE db_datareader ADD MEMBER [app-steel-estimation-prod];
ALTER ROLE db_datawriter ADD MEMBER [app-steel-estimation-prod];
ALTER ROLE db_ddladmin ADD MEMBER [app-steel-estimation-prod];

-- Also check if we can grant CONNECT permission explicitly
GRANT CONNECT TO [app-steel-estimation-prod];

PRINT 'Permissions verified/granted';