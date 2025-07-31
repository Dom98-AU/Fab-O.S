# Staging Deployment Status

## Actions Completed

1. ✅ **Created staging environment infrastructure**
   - Staging slot configured with .NET 8 runtime
   - Environment variables set (ASPNETCORE_ENVIRONMENT=Staging)
   - Connection string pointed to sandbox database
   - Always On enabled for consistent performance

2. ✅ **Successfully deployed application files**
   - Deployed compiled Release build from `bin/Release/net8.0`
   - Deployment completed successfully (status 4)
   - All required DLLs and configuration files are present

3. ✅ **Enabled logging and diagnostics**
   - Detailed error messages enabled
   - Failed request tracing enabled
   - Application logging set to Verbose

## Current Issue

The staging site returns a **502.5 - ANCM Out-Of-Process Startup Failure** error. This indicates the ASP.NET Core Module cannot start the .NET process.

## Root Cause Analysis

The most likely causes are:
1. **Missing ASP.NET Core Runtime** - The App Service might not have the correct .NET 8 runtime installed
2. **Connection String Issue** - The app might be failing to connect to the sandbox database
3. **Missing Dependencies** - Some required system libraries might be missing

## Resolution Steps

To fix the staging environment, you need to:

### Option 1: Use PowerShell on Windows (Recommended)
```powershell
# 1. Open PowerShell as Administrator
# 2. Navigate to the project folder
cd "C:\Steel Estimation Platform\SteelEstimation"

# 3. Build the application
dotnet publish SteelEstimation.Web\SteelEstimation.Web.csproj -c Release -o publish-new --runtime win-x64 --self-contained

# 4. Deploy using the script
.\deploy-staging.ps1
```

### Option 2: Check Runtime Installation
```powershell
# Check if .NET 8 runtime is installed on App Service
az webapp config show --resource-group "NWIApps" --name "app-steel-estimation-prod" --slot "staging" --query "windowsFxVersion"

# If empty, set it explicitly
az webapp config set --resource-group "NWIApps" --name "app-steel-estimation-prod" --slot "staging" --windows-fx-version "DOTNET|8.0"
```

### Option 3: Deploy Self-Contained
The issue might be that the App Service doesn't have the exact .NET 8 runtime version. A self-contained deployment includes the runtime:

```powershell
# Build self-contained
dotnet publish SteelEstimation.Web\SteelEstimation.Web.csproj -c Release -o publish-selfcontained --runtime win-x64 --self-contained true

# Then deploy the publish-selfcontained folder
```

## Quick Diagnostic Commands

```bash
# Check recent logs
az webapp log download --resource-group "NWIApps" --name "app-steel-estimation-prod" --slot "staging"

# Stream live logs
az webapp log tail --resource-group "NWIApps" --name "app-steel-estimation-prod" --slot "staging"

# Check deployment status
az webapp deployment list --resource-group "NWIApps" --name "app-steel-estimation-prod" --slot "staging"
```

## Deployment Management UI

Once staging is working, the deployment management features are ready at `/admin/deployment`:
- Compare Production and Staging environments
- View pending GitHub commits
- One-click promotion to Production
- Deployment history tracking

## Next Steps

1. Run one of the resolution options above
2. Once staging is working, test the deployment management UI
3. Make a test change and promote from Staging to Production

The infrastructure is fully configured - we just need to resolve the runtime startup issue.