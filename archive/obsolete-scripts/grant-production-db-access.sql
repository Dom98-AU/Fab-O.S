-- Run this script in the production database (sqldb-steel-estimation-prod)
-- Connect using SQL Server Management Studio or Azure Portal Query Editor

-- Create user for the production app's managed identity
CREATE USER [app-steel-estimation-prod] FROM EXTERNAL PROVIDER;

-- Grant necessary permissions
ALTER ROLE db_datareader ADD MEMBER [app-steel-estimation-prod];
ALTER ROLE db_datawriter ADD MEMBER [app-steel-estimation-prod];
ALTER ROLE db_ddladmin ADD MEMBER [app-steel-estimation-prod];

-- Verify the user was created
SELECT name, type_desc, authentication_type_desc 
FROM sys.database_principals 
WHERE name = 'app-steel-estimation-prod';

PRINT 'Permissions granted successfully!';