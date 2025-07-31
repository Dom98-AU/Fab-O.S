# Complete Database Migration Guide: Docker SQL to Azure SQL using SSMS

## Prerequisites
1. **Install SQL Server Management Studio (SSMS)**
   - Download from: https://aka.ms/ssmsfullsetup
   - Install with default options

2. **Ensure Docker SQL is running**
   ```powershell
   docker ps
   # Should show: steel-estimation-sql container running
   ```

## Step 1: Connect to Both Databases in SSMS

### 1.1 Connect to Docker SQL Server
1. Open SSMS
2. Click "Connect" → "Database Engine"
3. Enter connection details:
   - **Server name**: `localhost,1433`
   - **Authentication**: SQL Server Authentication
   - **Login**: `sa`
   - **Password**: `YourStrong@Password123`
4. Click "Connect"

### 1.2 Connect to Azure SQL Database
1. In SSMS, click "Connect" → "Database Engine" again
2. Enter connection details:
   - **Server name**: `nwiapps.database.windows.net`
   - **Authentication**: SQL Server Authentication
   - **Login**: `admin@nwi@nwiapps`
   - **Password**: `Natweigh88`
3. Click "Options >>"
4. In "Connection Properties" tab:
   - **Connect to database**: `sqldb-steel-estimation-sandbox`
5. Click "Connect"

## Step 2: Export Data from Docker SQL

### 2.1 Start the Export Wizard
1. In Object Explorer, expand the Docker connection (localhost,1433)
2. Expand "Databases"
3. Right-click on **"SteelEstimationDB"**
4. Select **"Tasks"** → **"Export Data..."**

### 2.2 Configure the Export Wizard

#### Source Configuration
1. **Data source**: Microsoft OLE DB Provider for SQL Server
2. **Server name**: localhost,1433
3. **Authentication**: Use SQL Server Authentication
   - User name: `sa`
   - Password: `YourStrong@Password123`
4. **Database**: SteelEstimationDB
5. Click "Next"

#### Destination Configuration
1. **Destination**: Microsoft OLE DB Provider for SQL Server
2. **Server name**: nwiapps.database.windows.net
3. **Authentication**: Use SQL Server Authentication
   - User name: `admin@nwi@nwiapps`
   - Password: `Natweigh88`
4. **Database**: sqldb-steel-estimation-sandbox
5. Click "Next"

#### Table Selection
1. Select "Copy data from one or more tables or views"
2. Click "Next"
3. **IMPORTANT**: Check "Select All" to select all 35 tables
4. Review the mappings:
   - Source tables should show all 35 tables
   - Destination tables will be created automatically
5. Click "Next"

#### Save and Run Package
1. Select "Run immediately"
2. Optionally check "Save SSIS Package" for future use
3. Click "Next"
4. Review the summary
5. Click "Finish"

## Step 3: Monitor the Migration

The wizard will show progress for each table:
- ✅ Green checkmarks = Successfully migrated
- ❌ Red X = Failed (check error message)
- 📊 Shows row counts transferred

Expected results:
- **35 tables** should be processed
- Key tables with data:
  - ProcessingItems: 454 rows
  - WeldingItems: 161 rows
  - DeliveryBundles: 48 rows
  - PackageWorksheets: 30 rows
  - ImageUploads: 29 rows
  - And more...

## Step 4: Verify Migration

### In SSMS:
1. Refresh the Azure SQL connection
2. Expand sqldb-steel-estimation-sandbox → Tables
3. Verify all 35 tables are present
4. Right-click any table → "Select Top 1000 Rows" to verify data

### Quick verification query:
```sql
-- Run this in Azure SQL to check all tables
SELECT 
    t.name AS TableName,
    p.rows AS RowCount
FROM sys.tables t
INNER JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0,1)
AND t.is_ms_shipped = 0
ORDER BY p.rows DESC;
```

## Step 5: Handle Common Issues

### Issue: "Identity Insert" errors
**Solution**: In the wizard, click "Edit Mappings" for affected tables and check "Enable identity insert"

### Issue: Foreign Key constraint errors
**Solution**: 
1. Cancel the wizard
2. Run this in Azure SQL first:
```sql
-- Disable all foreign keys
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT all'
```
3. Run the migration again
4. After migration, re-enable:
```sql
-- Re-enable all foreign keys
EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT all'
```

### Issue: Data type mismatches
**Solution**: Click "Edit Mappings" and adjust data type mappings

## Step 6: Post-Migration Tasks

1. **Update statistics** (run in Azure SQL):
```sql
EXEC sp_updatestats;
```

2. **Verify row counts** match between source and destination

3. **Test your application**:
```powershell
.\test-azure-app.ps1
```

## Alternative: Using Import/Export via BACPAC

If the wizard has issues, you can use BACPAC:

1. In SSMS, right-click Docker database
2. Tasks → "Export Data-tier Application..."
3. Save as .bacpac file
4. Right-click Azure SQL Server
5. "Import Data-tier Application..."
6. Select the .bacpac file

## Success Checklist
- [ ] All 35 tables created in Azure SQL
- [ ] Row counts match between Docker and Azure
- [ ] No error messages during migration
- [ ] Application connects successfully
- [ ] Can login with admin@steelestimation.com

## Connection Strings Summary

**Docker SQL (Source)**:
- Server: localhost,1433
- Database: SteelEstimationDB
- User: sa
- Password: YourStrong@Password123

**Azure SQL (Destination)**:
- Server: nwiapps.database.windows.net
- Database: sqldb-steel-estimation-sandbox
- User: admin@nwi@nwiapps
- Password: Natweigh88

---

After completing this migration, all your data will be in Azure SQL and your application will be ready for cloud deployment!