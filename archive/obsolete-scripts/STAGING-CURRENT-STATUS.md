# Staging Environment Current Status

## What We've Done
✅ Successfully deployed the application files to staging
✅ Configured the staging slot with .NET 8 runtime
✅ Set environment variables correctly
✅ Connection string is configured

## Current Issue
The application is experiencing a startup failure (Error 500.30). This typically means:
- The app crashes during startup
- Database connection fails
- Missing configuration or dependencies

## To Fix This Issue

### Option 1: Check Application Logs (Recommended)
Run this in PowerShell to see the actual error:

```powershell
# Download the logs
az webapp log download --resource-group "NWIApps" --name "app-steel-estimation-prod" --slot "staging" --log-file "staging-logs.zip"

# Extract and view
Expand-Archive -Path "staging-logs.zip" -DestinationPath "staging-logs" -Force
Get-Content "staging-logs\LogFiles\Application\*.txt" | Select-Object -Last 100
```

### Option 2: Enable Stdout Logging
This will show you the exact startup error:

```powershell
# Download current web.config
az webapp deployment source download-zip --resource-group "NWIApps" --name "app-steel-estimation-prod" --slot "staging" --output-path "current-staging.zip"

# Extract it
Expand-Archive -Path "current-staging.zip" -DestinationPath "current-staging" -Force

# Edit web.config in current-staging folder
# Change stdoutLogEnabled="false" to stdoutLogEnabled="true"
# Save and rezip, then redeploy
```

### Option 3: Test Database Connection
The most likely issue is the database connection. Check if the app can connect to the sandbox database:

```powershell
# Test the connection string
$connString = az webapp config connection-string list --resource-group "NWIApps" --name "app-steel-estimation-prod" --slot "staging" --query "[0].value" -o tsv

# This will show you the actual connection string being used
Write-Host $connString
```

## Most Common Fixes

1. **Database Authentication**: The Managed Identity might not have access to the sandbox database. You may need to:
   ```sql
   -- Run this in the sandbox database
   CREATE USER [app-steel-estimation-prod] FROM EXTERNAL PROVIDER;
   ALTER ROLE db_datareader ADD MEMBER [app-steel-estimation-prod];
   ALTER ROLE db_datawriter ADD MEMBER [app-steel-estimation-prod];
   ALTER ROLE db_ddladmin ADD MEMBER [app-steel-estimation-prod];
   ```

2. **Missing JWT Secret**: Add the JWT secret key:
   ```powershell
   az webapp config appsettings set --resource-group "NWIApps" --name "app-steel-estimation-prod" --slot "staging" --settings "JwtSettings:SecretKey=your-staging-secret-key-32-characters-long"
   ```

3. **Use SQL Authentication**: If Managed Identity isn't working, switch to SQL authentication in the connection string.

## Quick Test
To verify it's a database issue, you can temporarily remove the database dependency:
1. Comment out database initialization in Program.cs
2. Redeploy
3. If it works, the issue is definitely database-related

## Next Steps
1. Check the application logs to see the exact error
2. Fix the identified issue (usually database or configuration)
3. Redeploy and test
4. Once working, test the deployment UI at `/admin/deployment`

The infrastructure is ready - we just need to resolve the startup error.