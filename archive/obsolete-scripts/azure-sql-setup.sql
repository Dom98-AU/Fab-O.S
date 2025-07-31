-- Azure SQL Database Setup for Managed Identity
-- Run this script in Azure SQL Database after creating the App Service with Managed Identity

-- This script grants database access to the App Service Managed Identity
CREATE USER [app-steel-estimation-prod] FROM EXTERNAL PROVIDER;

-- Grant necessary permissions
ALTER ROLE db_datareader ADD MEMBER [app-steel-estimation-prod];
ALTER ROLE db_datawriter ADD MEMBER [app-steel-estimation-prod];
ALTER ROLE db_ddladmin ADD MEMBER [app-steel-estimation-prod];

-- Verify the user was created
SELECT name, type_desc, authentication_type_desc 
FROM sys.database_principals 
WHERE name = 'app-steel-estimation-prod';

-- Grant execute permissions on all stored procedures (if you plan to use any)
GRANT EXECUTE TO [app-steel-estimation-prod];