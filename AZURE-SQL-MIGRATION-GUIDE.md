# Steel Estimation Platform - Azure SQL Migration Guide

## Overview
This guide documents the complete migration process from Docker SQL Server to Azure SQL Database for the Steel Estimation Platform.

## Azure SQL Database Details
- **Server**: nwiapps.database.windows.net
- **Database**: sqldb-steel-estimation-sandbox
- **Username**: admin@nwi@nwiapps
- **Password**: [Stored securely in Azure Key Vault]

## Migration Summary
Successfully migrated all 35 tables with complete data integrity:
- 454 ProcessingItems
- 161 WeldingItems  
- 48 DeliveryBundles
- 30 PackageWorksheets
- Plus all other tables and relationships

## Quick Start - Running with Azure SQL

### 1. Test the Azure SQL Connection
```powershell
.\test-azure-app.ps1
```

### 2. Access the Application
- URL: http://localhost:8080
- Login: admin@steelestimation.com
- Password: Admin@123

### 3. Stop the Application
```powershell
docker-compose -f docker-compose-azure.yml down
```

## Migration Process (If Needed Again)

### Option 1: Using SqlPackage (Recommended)
```powershell
# Run the complete migration script
.\migrate-to-azure.ps1
```

This script will:
1. Download SqlPackage if not present
2. Export all data from Docker SQL to a .bacpac file
3. Import the .bacpac file to Azure SQL
4. Preserve all tables, data, indexes, and relationships

### Option 2: Manual Migration
If you need to migrate manually:

```powershell
# Export from Docker
.\sqlpackage\SqlPackage.exe /Action:Export `
  /SourceServerName:localhost,1433 `
  /SourceDatabaseName:SteelEstimationDB `
  /SourceUser:sa `
  /SourcePassword:YourStrong@Password123 `
  /SourceTrustServerCertificate:True `
  /TargetFile:backups\SteelEstimation.bacpac

# Import to Azure
.\sqlpackage\SqlPackage.exe /Action:Import `
  /TargetServerName:nwiapps.database.windows.net `
  /TargetDatabaseName:sqldb-steel-estimation-sandbox `
  /TargetUser:admin@nwi@nwiapps `
  /TargetPassword:Natweigh88 `
  /SourceFile:backups\SteelEstimation.bacpac
```

## Configuration Files

### docker-compose-azure.yml
- Uses Azure SQL instead of local SQL container
- Configures the application with Azure connection string
- Removes dependency on SQL Server container

### Dockerfile.azure
- Special Dockerfile that removes Docker-specific configuration
- Forces use of environment variables for connection strings
- Optimized for Azure SQL connectivity

### Connection String Format
```
Server=tcp:nwiapps.database.windows.net,1433;
Initial Catalog=sqldb-steel-estimation-sandbox;
User ID=admin@nwi@nwiapps;
Password=Natweigh88;
Encrypt=True;
TrustServerCertificate=False;
Connection Timeout=30;
MultipleActiveResultSets=true
```

## Troubleshooting

### Connection Issues
1. Ensure Azure SQL firewall allows your IP
2. Verify username format: `admin@nwi@nwiapps` (note the double @)
3. Check that all 35 tables exist in Azure SQL

### Application Not Using Azure SQL
1. Make sure you're using `docker-compose-azure.yml`
2. Verify `Dockerfile.azure` is being used
3. Check that appsettings.Docker.json is not overriding the connection

### Performance Issues
- Azure SQL may need scaling based on usage
- Consider adding indexes if queries are slow
- Monitor DTU usage in Azure Portal

## Scripts Reference

- `migrate-to-azure.ps1` - Complete migration script
- `test-azure-app.ps1` - Test application with Azure SQL
- `check-azure-tables.ps1` - Verify all tables in Azure
- `clean-azure-db.ps1` - Clean Azure DB before migration

## Important Notes

1. **Backup**: Always backup your data before migration
2. **Costs**: Azure SQL has ongoing costs based on DTU/vCore
3. **Security**: Store passwords in Azure Key Vault for production
4. **Scaling**: Start with Basic tier and scale as needed
5. **Monitoring**: Enable Azure SQL analytics for performance insights

## Next Steps

1. Set up Azure Key Vault for secure password storage
2. Configure automated backups in Azure
3. Set up monitoring and alerts
4. Consider implementing Managed Identity for enhanced security
5. Plan for production deployment with proper SSL certificates