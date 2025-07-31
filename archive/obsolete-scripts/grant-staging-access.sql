-- Grant access to staging slot's Managed Identity
-- Run this in the sqldb-steel-estimation-sandbox database

-- Create user for the staging slot's Managed Identity
CREATE USER [app-steel-estimation-prod/slots/staging] FROM EXTERNAL PROVIDER;

-- Grant necessary permissions
ALTER ROLE db_datareader ADD MEMBER [app-steel-estimation-prod/slots/staging];
ALTER ROLE db_datawriter ADD MEMBER [app-steel-estimation-prod/slots/staging];
ALTER ROLE db_ddladmin ADD MEMBER [app-steel-estimation-prod/slots/staging];

-- Grant execute permissions for stored procedures
GRANT EXECUTE TO [app-steel-estimation-prod/slots/staging];

PRINT 'Permissions granted to staging slot Managed Identity';