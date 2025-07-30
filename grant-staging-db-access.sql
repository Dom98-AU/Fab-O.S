-- Run this script in the sandbox database (sqldb-steel-estimation-sandbox)
-- Connect using SQL Server Management Studio or Azure Portal Query Editor

-- Create user for the staging slot's managed identity
CREATE USER [app-steel-estimation-prod/slots/staging] FROM EXTERNAL PROVIDER;

-- Grant necessary permissions
ALTER ROLE db_datareader ADD MEMBER [app-steel-estimation-prod/slots/staging];
ALTER ROLE db_datawriter ADD MEMBER [app-steel-estimation-prod/slots/staging];
ALTER ROLE db_ddladmin ADD MEMBER [app-steel-estimation-prod/slots/staging];

-- Verify the user was created
SELECT name, type_desc, authentication_type_desc 
FROM sys.database_principals 
WHERE name = 'app-steel-estimation-prod/slots/staging';

PRINT 'Permissions granted successfully!';