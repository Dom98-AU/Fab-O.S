-- Grant database access to the staging slot's managed identity
-- Run this in the master database first to create the login, then in your database

-- Step 1: Run this in the MASTER database
-- Replace [app-steel-estimation-prod/slots/staging] with the actual identity name if different
CREATE LOGIN [app-steel-estimation-prod/slots/staging] FROM EXTERNAL PROVIDER;

-- Step 2: Run these in your APPLICATION database (sqldb-steel-estimation-sandbox)
-- Create user from the login
CREATE USER [app-steel-estimation-prod/slots/staging] FROM EXTERNAL PROVIDER;

-- Grant necessary permissions
ALTER ROLE db_datareader ADD MEMBER [app-steel-estimation-prod/slots/staging];
ALTER ROLE db_datawriter ADD MEMBER [app-steel-estimation-prod/slots/staging];

-- Verify the user was created and has correct permissions
SELECT 
    dp.name AS UserName,
    dp.type_desc AS UserType,
    dp.authentication_type_desc AS AuthType,
    r.name AS RoleName
FROM sys.database_principals dp
LEFT JOIN sys.database_role_members rm ON dp.principal_id = rm.member_principal_id
LEFT JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
WHERE dp.name = 'app-steel-estimation-prod/slots/staging';