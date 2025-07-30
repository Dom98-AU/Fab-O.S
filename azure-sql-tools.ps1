# Azure SQL Management Tools

# Run SQL commands against Azure SQL
function Invoke-AzureSql {
    param(
        [string]$Query,
        [string]$Server = $env:AZURE_SQL_SERVER,
        [string]$Database = $env:AZURE_SQL_DATABASE,
        [string]$User = $env:AZURE_SQL_USER,
        [string]$Password = $env:AZURE_SQL_PASSWORD
    )
    
    docker run --rm mcr.microsoft.com/mssql-tools /opt/mssql-tools18/bin/sqlcmd `
        -S $Server -d $Database -U $User -P $Password -C `
        -Q "$Query"
}

# Backup Azure SQL Database
function Backup-AzureSqlToBlob {
    param(
        [string]$BackupName = "FabOS-$(Get-Date -Format 'yyyyMMdd-HHmmss').bacpac"
    )
    
    Write-Host "Creating backup of Azure SQL Database..." -ForegroundColor Cyan
    
    # Use Azure CLI
    az sql db export `
        --resource-group FabOS-RG `
        --server fabos-sql-server `
        --name FabOS-DB `
        --storage-key-type StorageAccessKey `
        --storage-key "your-storage-key" `
        --storage-uri "https://yourstorage.blob.core.windows.net/backups/$BackupName" `
        --admin-user $env:AZURE_SQL_USER `
        --admin-password $env:AZURE_SQL_PASSWORD
}

# Run migration scripts
function Invoke-AzureSqlMigration {
    param(
        [string]$ScriptPath
    )
    
    Write-Host "Running migration script: $ScriptPath" -ForegroundColor Cyan
    
    # Read script
    $script = Get-Content $ScriptPath -Raw
    
    # Run via docker
    docker run --rm -v ${PWD}:/scripts mcr.microsoft.com/mssql-tools /opt/mssql-tools18/bin/sqlcmd `
        -S $env:AZURE_SQL_SERVER -d $env:AZURE_SQL_DATABASE `
        -U $env:AZURE_SQL_USER -P $env:AZURE_SQL_PASSWORD -C `
        -i /scripts/$ScriptPath
}

# Quick connection test
function Test-AzureSqlConnection {
    Write-Host "Testing Azure SQL Connection..." -ForegroundColor Cyan
    Invoke-AzureSql -Query "SELECT @@VERSION"
}

# Get database size and stats
function Get-AzureSqlStats {
    $query = @"
SELECT 
    DB_NAME() as DatabaseName,
    SUM(size * 8 / 1024) as SizeMB
FROM sys.database_files;

SELECT COUNT(*) as TableCount FROM sys.tables;
SELECT COUNT(*) as UserCount FROM Users;
SELECT COUNT(*) as ProjectCount FROM Projects;
"@
    
    Invoke-AzureSql -Query $query
}

Write-Host "Azure SQL Tools Loaded!" -ForegroundColor Green
Write-Host "Available functions:" -ForegroundColor Cyan
Write-Host "  - Invoke-AzureSql 'SELECT * FROM Users'" -ForegroundColor Yellow
Write-Host "  - Test-AzureSqlConnection" -ForegroundColor Yellow
Write-Host "  - Get-AzureSqlStats" -ForegroundColor Yellow
Write-Host "  - Invoke-AzureSqlMigration 'path/to/script.sql'" -ForegroundColor Yellow
Write-Host "  - Backup-AzureSqlToBlob" -ForegroundColor Yellow