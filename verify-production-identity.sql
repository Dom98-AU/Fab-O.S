-- Check existing database users
SELECT name, type_desc, authentication_type_desc 
FROM sys.database_principals 
WHERE type IN ('E', 'X') -- External users
ORDER BY name;

-- Try creating the user with different name formats
-- Sometimes Azure uses different formats for the identity

-- Option 1: Just the app name
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'app-steel-estimation-prod')
BEGIN
    CREATE USER [app-steel-estimation-prod] FROM EXTERNAL PROVIDER;
    ALTER ROLE db_datareader ADD MEMBER [app-steel-estimation-prod];
    ALTER ROLE db_datawriter ADD MEMBER [app-steel-estimation-prod];
    ALTER ROLE db_ddladmin ADD MEMBER [app-steel-estimation-prod];
    PRINT 'Created user: app-steel-estimation-prod';
END

-- Option 2: With resource group prefix (less common)
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'NWIApps/app-steel-estimation-prod')
BEGIN
    CREATE USER [NWIApps/app-steel-estimation-prod] FROM EXTERNAL PROVIDER;
    ALTER ROLE db_datareader ADD MEMBER [NWIApps/app-steel-estimation-prod];
    ALTER ROLE db_datawriter ADD MEMBER [NWIApps/app-steel-estimation-prod];
    ALTER ROLE db_ddladmin ADD MEMBER [NWIApps/app-steel-estimation-prod];
    PRINT 'Created user: NWIApps/app-steel-estimation-prod';
END