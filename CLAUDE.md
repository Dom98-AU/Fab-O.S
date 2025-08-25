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

### 🚨 Claude Code Hooks (Automatic Docker Rebuild Detection)

This project has **automatic hooks** that detect when you need to rebuild Docker:

1. **File Change Detection**: When you edit C#/Razor files, you'll see:
   ```
   ⚠️ C#/Razor file changed! 
   Required action: .\rebuild.ps1
   ```

2. **Command Interception**: If you try `docker-compose restart` with pending C# changes:
   ```
   ❌ WARNING: You have C#/Razor changes!
   Use .\rebuild.ps1 instead of restart!
   ```

3. **Session Reminders**: Each new prompt reminds you of pending rebuilds

**To test hooks**: Run `.\test-hooks.ps1`

**Hook files**:
- `.claude-code-project/settings.json` - Hook configuration
- `.claude-code/track-changes.ps1` - Change tracking script

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

#### Common Issues & Solutions

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

4. **Changes not appearing after saving**:
   - **FIRST**: Run `.\check-changes.ps1` to detect what needs to be done
   - **CSS/JS not updating**: Hard refresh browser (Ctrl+F5)
   - **C# changes not working**: Run `.\rebuild.ps1` (NOT just restart!)
   - **Still not working**: Full cache clear with `.\rebuild.ps1`

5. **Container won't start**:
   ```powershell
   # Check logs
   docker-compose logs web
   
   # If port in use
   docker-compose down
   docker ps -a  # Check for orphaned containers
   docker-compose up -d
   ```

6. **"File not found" errors after adding new files**:
   - New static files (CSS/JS): Should work immediately with volume mounts
   - New C# files: Run `docker-compose restart web`
   - New projects/packages: Run `./rebuild.ps1`

### Deployment Considerations

When deploying to Azure:
1. Connection string will use Managed Identity
2. Secrets should be in Key Vault, not appsettings
3. Run migrations before deployment
4. Test in Staging environment first

### Development Workflow with Docker

#### ⚠️ CRITICAL: Always Check First!
```powershell
.\check-changes.ps1  # This tells you EXACTLY what to do!
```

#### File Change Guide
- **CSS/JS/Image Changes**: Just save and refresh browser (auto-synced via volume mounts)
- **HTML in Razor Pages**: Just save and refresh (synced via volumes)
- **C# Code Changes**: Run `.\rebuild.ps1` ⚠️ (NOT just restart - rebuild required!)
- **Razor @code blocks**: Run `.\rebuild.ps1` ⚠️ (These compile to DLLs - rebuild required!)
- **New NuGet Packages**: Run `.\rebuild.ps1` (Full rebuild required)
- **Docker Config Changes**: Run `.\rebuild.ps1` (Dockerfile, docker-compose.yml changes)
- **Strange Issues**: Run `.\rebuild.ps1` (Clears cache and rebuilds fresh)

#### Volume Mounts
The following directories are mounted for instant updates:
- `./SteelEstimation.Web/wwwroot` → `/app/wwwroot` (CSS, JS, images)
- `./SteelEstimation.Web/Pages` → `/app/Pages` (Razor pages)
- `./SteelEstimation.Web/Shared` → `/app/Shared` (Shared components)
- `./SteelEstimation.Web/Components` → `/app/Components` (Blazor components)

#### Quick Commands Reference

**For C# Code Changes** (Controllers, Services, Models, @code blocks):
```powershell
docker-compose restart web
# Wait ~10 seconds for restart
```

**For New NuGet Packages or Major Changes**:
```powershell
./rebuild.ps1
# This will stop, rebuild, and restart everything fresh
```

#### When to Use Each Command

| Change Type | Command | Wait Time |
|------------|---------|-----------|
| CSS/JS/Images | None - just refresh | Instant |
| HTML in Razor | None - just refresh | Instant |
| @code blocks | `./rebuild.ps1` ⚠️ | ~2-3 min |
| C# files (.cs) | `./rebuild.ps1` ⚠️ | ~2-3 min |
| Component files (.razor) | `./rebuild.ps1` ⚠️ | ~2-3 min |
| New NuGet package | `./rebuild.ps1` | ~2-3 min |
| **Not sure?** | **`./check-changes.ps1`** | **Tells you!** |
| appsettings.json | `docker-compose restart web` | ~10 sec |
| Dockerfile | `./rebuild.ps1` | ~2-3 min |
| docker-compose.yml | `./rebuild.ps1` | ~2-3 min |

### Common Commands

```powershell
# Quick rebuild (when needed)
./rebuild.ps1

# View logs
docker-compose logs -f web

# Restart container (for C# changes)
docker-compose restart web

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

### Memories

- If playwrite MCP Test fully pass  delete them after
- I prefer to run sql scripts (.sql) when updating databases 
- When making changes to the system please always remove docker images, clear all build cache objects, rebuild completely from scratch