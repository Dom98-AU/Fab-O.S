# Steel Estimation Platform - Development Guide

## Local Development Setup

### Prerequisites
- .NET 8 SDK
- Visual Studio 2022 or VS Code
- Docker Desktop (for containerized development)
- Access to Azure SQL Database (connection details in appsettings)

### Quick Start

1. **Run the application locally**:
   ```powershell
   .\run-local.ps1
   ```

2. **Or run with Docker**:
   ```bash
   docker-compose up
   ```

3. **Access the application**:
   - Local: https://localhost:5003 or http://localhost:5002
   - Docker: http://localhost:8080
   - Login: admin@steelestimation.com
   - Password: Admin@123

### Authentication Structure

The application uses **Cookie-based authentication** with the following structure:
- Session-based authentication (NOT JWT)
- 8-hour session timeout with sliding expiration
- Password hashing: PBKDF2 with HMACSHA256
- Role-based authorization: Administrator, Project Manager, Senior Estimator, Estimator, Viewer

### Key Differences: Development vs Production

| Feature | Development (Local/Docker) | Production (Azure) |
|---------|---------------------------|--------------------|
| Database | Azure SQL with SQL Auth | Azure SQL with Managed Identity |
| Connection String | In appsettings.json | In Key Vault |
| Secrets | appsettings.json | Azure Key Vault |
| SSL Certificate | Self-signed | Azure-managed |
| Environment | Development/DockerLocal | Staging/Production |
| Migrations | Run manually | Must be run manually |
| Logging | Debug level, file output | Information level, Application Insights |

### Important Files

- `appsettings.Development.json` - Local development configuration
- `appsettings.Staging.json` - Staging environment configuration  
- `appsettings.Production.json` - Production environment configuration
- `Program.cs` - Environment-specific configuration logic

### Troubleshooting

1. **Database connection fails**:
   - Check Azure SQL firewall rules
   - Verify connection string in appsettings
   - Ensure your IP is whitelisted in Azure

2. **Login fails**:
   - Check admin user exists in database
   - Verify password hash is correct
   - Check roles are properly assigned

3. **Blazor components not loading**:
   - Clear browser cache
   - Check browser console for errors
   - Ensure all NuGet packages are restored

### Deployment Considerations

When deploying to Azure:
1. Connection string will use Managed Identity
2. Secrets should be in Key Vault, not appsettings
3. Run migrations before deployment
4. Test in Staging environment first

### Common Commands

```powershell
# Run migrations manually
cd SteelEstimation.Web
dotnet ef database update

# Create a new migration
dotnet ef migrations add MigrationName --project ..\SteelEstimation.Infrastructure

# Run tests
dotnet test

# Build for production
dotnet publish -c Release
```

### Database Migrations

When new features require database changes, run the appropriate migration:

```powershell
# Run the latest migration (Time Tracking & Efficiency features)
.\run-migration.ps1

# Or use the batch file
.\run-migration.bat
```

#### Recent Migrations:
- **AddTimeTrackingAndEfficiency.sql** - Adds:
  - `EstimationTimeLogs` table for time tracking
  - `WeldingItemConnections` table for multiple welding connections
  - `ProcessingEfficiency` column to Packages table
- **AddEfficiencyRates.sql** - Adds:
  - `EfficiencyRates` table for configurable efficiency presets
  - `EfficiencyRateId` column to Packages table
  - Default efficiency rates for all companies
- **AddPackBundles.sql** - Adds:
  - `PackBundles` table for grouping processing items
  - `PackBundleId` and `IsParentInPackBundle` columns to ProcessingItems table
  - Foreign key relationships and indexes

### New Features (January 2025)

1. **Time Tracking**: Automatically tracks time spent on estimations with pause during inactivity
2. **Multiple Welding Connections**: Support for multiple connection types per welding item
3. **Processing Efficiency**: Filter processing hours by efficiency percentage on dashboard
4. **Configurable Efficiency Rates**: Admin-managed efficiency rates with company-specific presets
5. **Welding Time Dashboard**: Detailed analytics for welding operations with charts and breakdowns
6. **Pack Bundles**: Group processing items for handling operations (Move to Assembly & Move After Weld)
   - Similar to delivery bundles but for pack/handling operations
   - Only parent items in pack bundles have handling times applied
   - Separate visual indicators (blue badges) from delivery bundles
   - Full CRUD operations with collapse/expand functionality