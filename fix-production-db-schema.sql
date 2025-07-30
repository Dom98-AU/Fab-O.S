-- First, let's check what columns exist in the Users table
SELECT COLUMN_NAME 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Users';

-- If 'Role' column is missing, add it
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = 'Role')
BEGIN
    ALTER TABLE [dbo].[Users] ADD [Role] [nvarchar](50) NULL;
    PRINT 'Added Role column to Users table';
END

-- Grant Managed Identity access
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'app-steel-estimation-prod')
BEGIN
    CREATE USER [app-steel-estimation-prod] FROM EXTERNAL PROVIDER;
    PRINT 'Created user for Managed Identity';
END

-- Grant permissions
ALTER ROLE db_datareader ADD MEMBER [app-steel-estimation-prod];
ALTER ROLE db_datawriter ADD MEMBER [app-steel-estimation-prod];
ALTER ROLE db_ddladmin ADD MEMBER [app-steel-estimation-prod];

PRINT 'Permissions granted successfully!';