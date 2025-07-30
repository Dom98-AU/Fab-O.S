# Backup local database and restore to Docker
param(
    [string]$ServerInstance = "localhost",
    [string]$DatabaseName = "SteelEstimationDb_CloudDev",
    [string]$BackupPath = "C:\Temp\SteelEstimationBackup.bak",
    [string]$ContainerName = "steel-estimation-sql",
    [string]$Password = "YourStrong@Password123"
)

Write-Host "=== Steel Estimation Database Migration to Docker ===" -ForegroundColor Cyan
Write-Host "This will backup your local database and restore it in Docker with the exact schema and data" -ForegroundColor Yellow

# Step 1: Create backup directory if it doesn't exist
$backupDir = Split-Path -Parent $BackupPath
if (-not (Test-Path $backupDir)) {
    Write-Host "Creating backup directory: $backupDir" -ForegroundColor Gray
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

# Step 2: Backup the local database
Write-Host "`n[1/5] Backing up local database..." -ForegroundColor Green
$backupQuery = @"
BACKUP DATABASE [$DatabaseName] 
TO DISK = N'$BackupPath' 
WITH FORMAT, INIT, 
NAME = N'$DatabaseName-Full Database Backup', 
SKIP, NOREWIND, NOUNLOAD, STATS = 10
"@

try {
    Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $backupQuery -QueryTimeout 300
    Write-Host "Backup completed successfully!" -ForegroundColor Green
    Write-Host "Backup file: $BackupPath" -ForegroundColor Gray
} catch {
    Write-Host "Error creating backup: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Check if Docker container is running
Write-Host "`n[2/5] Checking Docker container..." -ForegroundColor Green
$containerStatus = docker ps --filter "name=$ContainerName" --format "{{.Status}}"
if (-not $containerStatus) {
    Write-Host "Container '$ContainerName' is not running." -ForegroundColor Red
    Write-Host "Please run 'docker-compose up -d' first." -ForegroundColor Yellow
    exit 1
}
Write-Host "Container is running: $containerStatus" -ForegroundColor Gray

# Step 4: Copy backup file to Docker container
Write-Host "`n[3/5] Copying backup to Docker container..." -ForegroundColor Green

# First, ensure the backup directory exists in the container
docker exec $ContainerName mkdir -p /var/opt/mssql/backup

# Convert Windows path to a format Docker can handle
$BackupFileName = Split-Path $BackupPath -Leaf
$TempPath = ".\$BackupFileName"

# Copy to current directory first if needed
if ($BackupPath -ne $TempPath) {
    Copy-Item -Path $BackupPath -Destination $TempPath -Force
}

# Now copy to Docker
docker cp $TempPath "${ContainerName}:/var/opt/mssql/backup/$BackupFileName"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error copying backup file to container" -ForegroundColor Red
    # Clean up temp file
    if ($BackupPath -ne $TempPath) {
        Remove-Item $TempPath -Force -ErrorAction SilentlyContinue
    }
    exit 1
}
Write-Host "Backup file copied successfully" -ForegroundColor Gray

# Clean up temp file if we created one
if ($BackupPath -ne $TempPath) {
    Remove-Item $TempPath -Force -ErrorAction SilentlyContinue
}

# Step 5: Drop existing database and restore from backup
Write-Host "`n[4/5] Restoring database in Docker..." -ForegroundColor Green
Write-Host "This will replace the existing database completely" -ForegroundColor Yellow

$restoreCommands = @"
-- First, drop existing database if it exists
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'SteelEstimationDB')
BEGIN
    ALTER DATABASE [SteelEstimationDB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [SteelEstimationDB];
END
GO

-- Get logical file names from backup
RESTORE FILELISTONLY FROM DISK = '/var/opt/mssql/backup/$BackupFileName'
GO

-- Restore the database
RESTORE DATABASE [SteelEstimationDB] 
FROM DISK = '/var/opt/mssql/backup/$BackupFileName'
WITH REPLACE,
MOVE 'SteelEstimationDb' TO '/var/opt/mssql/data/SteelEstimationDB.mdf',
MOVE 'SteelEstimationDb_log' TO '/var/opt/mssql/data/SteelEstimationDB_log.ldf',
STATS = 10
GO

-- Verify the restore
SELECT name, state_desc FROM sys.databases WHERE name = 'SteelEstimationDB'
GO
"@

# Save commands to a file
$restoreCommands | Out-File -FilePath ".\restore-commands.sql" -Encoding UTF8

# Copy SQL file to container
docker cp ".\restore-commands.sql" "${ContainerName}:/tmp/"

# Execute the restore
Write-Host "Executing restore (this may take a few minutes)..." -ForegroundColor Cyan
docker exec $ContainerName /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P $Password -C -i /tmp/restore-commands.sql

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[5/5] Verifying the restore..." -ForegroundColor Green
    
    # Verify database and show table counts
    $verifyQuery = @"
USE SteelEstimationDB;
SELECT 
    'Database restored successfully!' as Status;
    
SELECT 
    t.name AS TableName,
    p.rows AS RecordCount
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
WHERE i.index_id <= 1
  AND t.name NOT LIKE 'spt_%'
  AND t.name NOT LIKE 'MSrep%'
GROUP BY t.name, p.rows
ORDER BY t.name;
"@
    
    docker exec $ContainerName /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P $Password -C -Q "$verifyQuery"
    
    Write-Host "`n=== Migration Complete! ===" -ForegroundColor Green
    Write-Host "Your complete database (schema + data) has been migrated to Docker" -ForegroundColor Cyan
    Write-Host "The application should now work with your existing data at: http://localhost:8080" -ForegroundColor Yellow
    
    # Clean up
    Remove-Item ".\restore-commands.sql" -Force
    docker exec $ContainerName rm /tmp/restore-commands.sql
    
} else {
    Write-Host "`nError during restore. Checking for issues..." -ForegroundColor Red
    
    # Try to get logical file names
    Write-Host "`nGetting logical file names from backup..." -ForegroundColor Yellow
    docker exec $ContainerName /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P $Password -C -Q "RESTORE FILELISTONLY FROM DISK = '/var/opt/mssql/backup/$BackupFileName'"
    
    Write-Host "`nPlease check the logical file names above and update the MOVE statements in the script if needed." -ForegroundColor Yellow
}