# Docker Data Migration Guide

This guide explains how to export data from your local SQL Server and import it into the Docker SQL Server container.

## Prerequisites

1. Local SQL Server with your existing SteelEstimationDB database
2. Docker containers running (`docker-compose up -d`)
3. PowerShell (Run as Administrator)

## Step 1: Export Your Local Database

Run the export script to create a SQL file with all your data:

```powershell
.\export-for-docker.ps1
```

### Optional Parameters:
- `-ServerInstance`: Your SQL Server instance (default: `(localdb)\MSSQLLocalDB`)
- `-DatabaseName`: Database name (default: `SteelEstimationDB`)
- `-OutputFile`: Output SQL file path (default: `.\docker\sql\exported-data.sql`)

### Example with custom server:
```powershell
.\export-for-docker.ps1 -ServerInstance ".\SQLEXPRESS" -DatabaseName "SteelEstimationDB"
```

## Step 2: Import Data into Docker

Once the export is complete, import the data into your Docker SQL Server:

```powershell
.\import-to-docker.ps1
```

### Optional Parameters:
- `-SqlFile`: Path to the exported SQL file (default: `.\docker\sql\exported-data.sql`)
- `-ContainerName`: Docker container name (default: `steel-estimation-sql`)
- `-Password`: SQL Server SA password (default: `YourStrong@Password123`)

## Step 3: Verify the Import

After import, the script will show a table with record counts. You can also verify manually:

```powershell
# Connect to Docker SQL Server
docker exec -it steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Password123' -C

# In SQL prompt, check your data:
SELECT COUNT(*) FROM Projects;
SELECT COUNT(*) FROM Estimations;
SELECT COUNT(*) FROM AspNetUsers;
GO
```

## Alternative: Manual Export/Import

### Export using SQL Server Management Studio (SSMS):

1. Connect to your local SQL Server
2. Right-click on `SteelEstimationDB` > Tasks > Generate Scripts
3. Choose "Script entire database and all database objects"
4. In Advanced options:
   - Set "Types of data to script" to "Schema and data"
   - Set "Script Indexes" to True
   - Set "Script Primary Keys" to True
   - Set "Script Foreign Keys" to True
5. Save to file

### Import manually:

```powershell
# Copy file to container
docker cp your-export.sql steel-estimation-sql:/tmp/

# Import
docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Password123' -C -i /tmp/your-export.sql
```

## Troubleshooting

### "Login failed for user 'sa'"
- Ensure the password matches what's in docker-compose.yml
- Wait for SQL Server to fully start (check with `docker logs steel-estimation-sql`)

### "Cannot insert explicit value for identity column"
- The export script handles identity columns automatically
- If importing manually, ensure you have `SET IDENTITY_INSERT table_name ON/OFF`

### "Foreign key constraint conflict"
- Data is exported in dependency order
- If you still get errors, temporarily disable constraints:
  ```sql
  EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL'
  -- Run your imports
  EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL'
  ```

### Large databases
- For databases > 100MB, consider using backup/restore instead:
  ```powershell
  # On local SQL Server
  BACKUP DATABASE SteelEstimationDB TO DISK = 'C:\backup\SteelEstimationDB.bak'
  
  # Copy to Docker
  docker cp C:\backup\SteelEstimationDB.bak steel-estimation-sql:/var/opt/mssql/backup/
  
  # Restore in Docker
  docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Password123' -C -Q "RESTORE DATABASE SteelEstimationDB FROM DISK = '/var/opt/mssql/backup/SteelEstimationDB.bak' WITH REPLACE"
  ```

## Data Considerations

1. **User Passwords**: Exported password hashes will work as-is
2. **File Paths**: Any stored file paths may need updating for Docker environment
3. **Dates**: All dates are preserved in UTC format
4. **Binary Data**: Images and files in the database are preserved

## Next Steps

After successful import:
1. Test login with your existing users
2. Verify all projects and estimations are present
3. Check that welding items and processing data are intact
4. Test creating new records to ensure sequences work

## Quick Commands Reference

```powershell
# Export data
.\export-for-docker.ps1

# Import to Docker
.\import-to-docker.ps1

# Connect to Docker SQL
docker exec -it steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Password123' -C

# View Docker logs
docker logs steel-estimation-sql

# Restart containers
docker-compose restart
```