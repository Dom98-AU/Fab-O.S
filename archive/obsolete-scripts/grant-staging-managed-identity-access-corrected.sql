-- Grant database access to the staging slot's managed identity
-- Object ID: f273623f-b857-47af-862a-9c5bcb0ac6b6

-- IMPORTANT: Run these commands in the correct order

-- Step 1: First, connect to the MASTER database and run this:
-- CREATE LOGIN [app-steel-estimation-prod/slots/staging] FROM EXTERNAL PROVIDER;

-- Step 2: Then, connect to your APPLICATION database (sqldb-steel-estimation-sandbox) and run:

-- Create user from the external provider (Azure AD)
CREATE USER [app-steel-estimation-prod/slots/staging] FROM EXTERNAL PROVIDER;

-- Grant necessary permissions for the application to function
ALTER ROLE db_datareader ADD MEMBER [app-steel-estimation-prod/slots/staging];
ALTER ROLE db_datawriter ADD MEMBER [app-steel-estimation-prod/slots/staging];

-- Grant execute permissions for stored procedures (if any)
GRANT EXECUTE TO [app-steel-estimation-prod/slots/staging];

-- Verify the user was created and has correct permissions
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

-- Check if the staging managed identity user already exists
SELECT 
    name,
    type_desc,
    authentication_type_desc,
    create_date
FROM sys.database_principals
WHERE name LIKE '%staging%' OR name LIKE '%f273623f%';