# Migrating Your Exact Database to Docker

This guide will help you migrate your local Steel Estimation database with its exact schema and all data to Docker.

## Option 1: Backup and Restore (Recommended)

This is the most reliable method that preserves everything exactly as it is in your local database.

### Steps:

1. **Stop current Docker containers** (if running):
   ```powershell
   docker-compose down
   docker volume rm steelestimation-clouddev_sql-data  # Remove old data
   ```

2. **Start fresh Docker SQL Server**:
   ```powershell
   docker-compose -f docker-compose-clean.yml up -d sql-server
   ```

3. **Wait for SQL Server to be ready** (about 30 seconds):
   ```powershell
   docker logs steel-estimation-sql --follow
   # Press Ctrl+C when you see "SQL Server is now ready for client connections"
   ```

4. **Run the backup and restore migration**:
   ```powershell
   .\backup-restore-to-docker.ps1
   ```

   This script will:
   - Backup your local database
   - Copy the backup to Docker
   - Restore it with the exact schema and all data

5. **Start the web application**:
   ```powershell
   docker-compose -f docker-compose-clean.yml up -d
   ```

6. **Access your application**:
   - URL: http://localhost:8080
   - Use your existing login credentials

## Option 2: Schema and Data Migration

If the backup/restore method encounters issues, use this alternative:

1. **Stop and clean Docker** (if needed):
   ```powershell
   docker-compose down
   docker volume rm steelestimation-clouddev_sql-data
   ```

2. **Start fresh Docker SQL Server**:
   ```powershell
   docker-compose -f docker-compose-clean.yml up -d sql-server
   ```

3. **Wait for SQL Server to be ready**:
   ```powershell
   # Wait about 30 seconds, then verify:
   docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Password123' -C -Q "SELECT @@VERSION"
   ```

4. **Run the migration script**:
   ```powershell
   .\migrate-exact-schema.ps1
   ```

   This will:
   - Export your complete schema (tables, keys, indexes)
   - Export all your data
   - Recreate everything in Docker

5. **Start the web application**:
   ```powershell
   docker-compose -f docker-compose-clean.yml up -d
   ```

## Troubleshooting

### If backup/restore fails with logical file name errors:

1. Check the logical file names:
   ```powershell
   docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Password123' -C -Q "RESTORE FILELISTONLY FROM DISK = '/var/opt/mssql/backup/SteelEstimationBackup.bak'"
   ```

2. Update the restore script with the correct logical names shown in the output.

### If you get permission errors:

Run PowerShell as Administrator.

### If Docker SQL Server won't start:

1. Check if port 1433 is already in use:
   ```powershell
   netstat -an | findstr :1433
   ```

2. If your local SQL Server is using port 1433, either:
   - Stop your local SQL Server temporarily
   - Or change the Docker SQL port in docker-compose-clean.yml (e.g., `1434:1433`)

### Verify the migration:

```powershell
# Check tables and record counts
docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Password123' -C -Q "USE SteelEstimationDB; SELECT t.name AS TableName, p.rows AS Records FROM sys.tables t INNER JOIN sys.partitions p ON t.object_id = p.object_id WHERE p.index_id <= 1 ORDER BY t.name"

# Test a login
docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Password123' -C -Q "USE SteelEstimationDB; SELECT TOP 5 Email, UserName FROM Users"
```

## Important Notes

1. **Connection String**: The Docker environment uses SQL authentication (sa user) instead of Windows Authentication.

2. **Data Persistence**: Your data is stored in a Docker volume. To completely reset, you must remove the volume:
   ```powershell
   docker-compose down
   docker volume rm steelestimation-clouddev_sql-data
   ```

3. **Performance**: The first startup may be slow as Docker initializes. Subsequent startups will be faster.

4. **Backups**: To backup your Docker database:
   ```powershell
   docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Password123' -C -Q "BACKUP DATABASE SteelEstimationDB TO DISK = '/var/opt/mssql/backup/docker-backup.bak'"
   docker cp steel-estimation-sql:/var/opt/mssql/backup/docker-backup.bak ./docker-backup.bak
   ```

## Next Steps

After successful migration:
1. Test all functionality with your existing data
2. Verify user logins work correctly
3. Check that all projects and estimations are accessible
4. Test creating new records

The Docker environment now has your exact database schema and data!