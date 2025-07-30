-- Test if the app's managed identity can access the database

-- 1. Check current user context
SELECT 
    SUSER_NAME() AS CurrentUser,
    USER_NAME() AS DatabaseUser,
    IS_MEMBER('db_datareader') AS HasDataReader,
    IS_MEMBER('db_datawriter') AS HasDataWriter,
    CONNECTIONPROPERTY('auth_scheme') AS AuthScheme;

-- 2. Test read permission on Users table
SELECT TOP 1 'Can read Users table' AS TestResult
FROM Users;

-- 3. Test if can read admin user specifically
SELECT 
    'Admin user found' AS TestResult,
    Id,
    Username,
    Email,
    IsActive,
    IsEmailConfirmed
FROM Users
WHERE Email = 'admin@steelestimation.com';

-- 4. Check database permissions
SELECT 
    p.permission_name,
    p.state_desc,
    p.class_desc,
    p.major_id,
    OBJECT_NAME(p.major_id) as object_name
FROM sys.database_permissions p
WHERE p.grantee_principal_id = USER_ID()
ORDER BY p.permission_name;