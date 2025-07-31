# Steel Estimation Platform - Deployment Guide

> **Note**: This project uses a **Cloud-First Development Workflow**. See [CLOUD-FIRST-WORKFLOW.md](CLOUD-FIRST-WORKFLOW.md) for the recommended approach.

## Environment Setup

This application supports two environments:
- **Production**: Live environment for end users
- **Staging/Sandbox**: Development and testing environment (also serves as the primary development environment)

### Azure Resources

#### Production Environment
- **App Service**: `app-steel-estimation-prod`
- **Database**: `sqldb-steel-estimation-prod`
- **URL**: https://app-steel-estimation-prod.azurewebsites.net

#### Staging/Sandbox Environment
- **App Service**: `app-steel-estimation-prod/staging` (deployment slot)
- **Database**: `sqldb-steel-estimation-sandbox`
- **URL**: https://app-steel-estimation-prod-staging.azurewebsites.net

## Initial Setup

### 1. Create Sandbox Database (One-time setup)
```powershell
.\azure-create-sandbox-db.ps1
```
This creates a separate database for the staging environment.

### 2. Configure Staging Slot (One-time setup)
```powershell
.\configure-staging-slot.ps1
```
This configures the staging slot with:
- Connection string to sandbox database
- Environment variables
- Sticky settings (won't swap with production)

### 3. Run Database Migrations
After creating the sandbox database, run Entity Framework migrations:
```powershell
# For sandbox database
dotnet ef database update --connection "Server=nwiapps.database.windows.net;Database=sqldb-steel-estimation-sandbox;[Your Auth]"
```

## Deployment Process

### Cloud-First Approach (Recommended)

1. **Automatic Sandbox Deployment**:
   - Simply push to `develop` branch
   - GitHub Actions automatically deploys to sandbox
   - No manual commands needed!

2. **Production Deployment**:
   - Go to GitHub Actions
   - Run "Deploy to Production" workflow
   - Requires approval and confirmation

### Manual Deployment (Alternative)

If you need to deploy manually, use these PowerShell scripts:

#### Deploy to Staging/Sandbox
```powershell
# From develop branch
.\deploy-from-develop.ps1
```

#### Deploy to Production
```powershell
# From master branch
.\deploy-from-master.ps1
```

#### Promote to Production
```powershell
# Creates PR and handles promotion
.\promote-to-production.ps1
```

## Best Practices

### Development Workflow
1. **Develop locally** with local database
2. **Deploy to staging** for integration testing
3. **Test thoroughly** in staging environment
4. **Swap to production** when ready
5. **Monitor production** after deployment

### Safety Guidelines
- **Always test in staging first**
- **Use slot swaps** for production deployments (zero downtime)
- **Keep staging slot warm** for quick swaps
- **Monitor both environments** after deployment

### Database Management
- **Separate databases** for production and staging
- **No shared data** between environments
- **Regular backups** of production database
- **Test migrations** in staging first

## Rollback Procedures

### Quick Rollback (Recommended)
If issues are found after swapping to production:
```powershell
# Swap again to rollback
.\swap-slots.ps1
```
This immediately reverts to the previous version.

### Direct Deployment Rollback
If needed, deploy a previous version directly:
```powershell
# Checkout previous version
git checkout [previous-tag-or-commit]

# Deploy to production
.\deploy.ps1 -Environment Production
```

## Configuration Files

### Environment-Specific Settings
- `appsettings.json` - Base configuration
- `appsettings.Production.json` - Production overrides
- `appsettings.Staging.json` - Staging/Sandbox overrides

### Key Differences
| Setting | Production | Staging |
|---------|------------|---------|
| Database | sqldb-steel-estimation-prod | sqldb-steel-estimation-sandbox |
| Logging | Warning | Information |
| Detailed Errors | false | true |
| Environment Name | Production | Staging |

## Monitoring

### Application Insights
Both environments share Application Insights for monitoring.

### View Logs
- **Azure Portal**: App Service > Log Stream
- **Kudu Console**: https://[app-name].scm.azurewebsites.net

### Health Checks
- Production: https://app-steel-estimation-prod.azurewebsites.net/health
- Staging: https://app-steel-estimation-prod-staging.azurewebsites.net/health

## Troubleshooting

### Deployment Fails
1. Check build output for errors
2. Verify Azure credentials: `Connect-AzAccount`
3. Check deployment logs in Azure Portal

### Application Won't Start
1. Check Log Stream in Azure Portal
2. Verify connection strings
3. Check for missing migrations
4. Ensure correct .NET version

### Database Connection Issues
1. Verify connection string in App Settings
2. Check firewall rules
3. Ensure Managed Identity is configured
4. Test with SQL auth if needed

## Scripts Reference

| Script | Purpose |
|--------|---------|
| `deploy.ps1` | Unified deployment (choose environment) |
| `deploy-production.ps1` | Deploy directly to production |
| `deploy-staging.ps1` | Deploy to staging slot |
| `swap-slots.ps1` | Swap staging and production |
| `configure-staging-slot.ps1` | Initial staging setup |
| `azure-create-sandbox-db.ps1` | Create sandbox database |

## Emergency Contacts

For production issues:
- Primary: [Your contact]
- Secondary: [Backup contact]
- Azure Support: [Support plan details]