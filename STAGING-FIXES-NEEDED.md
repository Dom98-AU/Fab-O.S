# Staging Environment - Fixes Needed

## Issues Found and Fixed
✅ **Managed Identity** - Was not enabled, now enabled with Principal ID: `f273623f-b857-47af-862a-9c5bcb0ac6b6`
✅ **JWT Settings** - Were missing, now added
✅ **Deployment** - Application files successfully deployed
✅ **Logging** - Stdout logging enabled for debugging

## Remaining Issue: Database Access
The application is failing to start because the Managed Identity doesn't have access to the sandbox database.

## Fix Required: Grant Database Access

### Option 1: Grant Managed Identity Access (Recommended)
1. Open Azure Portal or SQL Server Management Studio
2. Connect to your SQL Server: `nwiapps.database.windows.net`
3. Switch to database: `sqldb-steel-estimation-sandbox`
4. Run this SQL script:

```sql
-- The staging slot needs its own user
CREATE USER [app-steel-estimation-prod/slots/staging] FROM EXTERNAL PROVIDER;

-- Grant permissions
ALTER ROLE db_datareader ADD MEMBER [app-steel-estimation-prod/slots/staging];
ALTER ROLE db_datawriter ADD MEMBER [app-steel-estimation-prod/slots/staging];
ALTER ROLE db_ddladmin ADD MEMBER [app-steel-estimation-prod/slots/staging];
```

### Option 2: Use SQL Authentication
If Managed Identity isn't working, switch to SQL authentication:

1. Create a SQL user in the sandbox database:
```sql
CREATE LOGIN [staging_user] WITH PASSWORD = 'YourSecurePassword123!';
CREATE USER [staging_user] FOR LOGIN [staging_user];
ALTER ROLE db_datareader ADD MEMBER [staging_user];
ALTER ROLE db_datawriter ADD MEMBER [staging_user];
ALTER ROLE db_ddladmin ADD MEMBER [staging_user];
```

2. Update the connection string:
```powershell
.\use-sql-auth-staging.ps1 -SqlUsername "staging_user" -SqlPassword "YourSecurePassword123!"
```

## After Fixing Database Access
Once you've granted database access, the staging site should start working:

1. Test the staging site: https://app-steel-estimation-prod-staging.azurewebsites.net
2. Login with your credentials
3. Test the deployment management UI at `/admin/deployment`
4. You'll be able to:
   - See side-by-side comparison of Production and Staging
   - View pending GitHub commits
   - Promote changes from Staging to Production
   - Track deployment history

## Quick Test Commands
```powershell
# Check if site is up
Start-Process "https://app-steel-estimation-prod-staging.azurewebsites.net"

# Stream logs
az webapp log tail --resource-group "NWIApps" --name "app-steel-estimation-prod" --slot "staging"

# Check recent errors
az webapp log download --resource-group "NWIApps" --name "app-steel-estimation-prod" --slot "staging" --log-file "logs.zip"
```

The staging infrastructure is fully configured - you just need to grant database access!