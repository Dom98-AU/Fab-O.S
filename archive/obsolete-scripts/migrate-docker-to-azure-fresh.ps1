# Complete Docker to Azure SQL Migration (Fresh Start)
param(
    [string]$Username = "admin@nwi@nwiapps",
    [string]$Password = "Natweigh88",
    [string]$DockerContainer = "steel-estimation-sql",
    [switch]$SkipUserBackup
)

Write-Host "=== Complete Docker to Azure SQL Migration ===" -ForegroundColor Cyan
Write-Host "This will replace ALL data in Azure SQL with your Docker database" -ForegroundColor Yellow
Write-Host "Target: nwiapps.database.windows.net / sqldb-steel-estimation-sandbox" -ForegroundColor Yellow

# Confirm action
$confirm = Read-Host "`nThis will DELETE all existing data in Azure SQL. Continue? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Migration cancelled." -ForegroundColor Red
    exit
}

# Step 1: Backup existing Azure users (optional)
if (-not $SkipUserBackup) {
    Write-Host "`n[1/8] Backing up existing Azure SQL users..." -ForegroundColor Green
    
    $userBackup = @"
-- Backup of existing users from Azure SQL
-- Generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
    
    docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
        -S "nwiapps.database.windows.net" `
        -d "sqldb-steel-estimation-sandbox" `
        -U $Username `
        -P $Password `
        -Q "SELECT Id, Email, UserName, FirstName, LastName, PhoneNumber, IsActive FROM Users" `
        -h -1 | Out-File -FilePath ".\azure-users-backup.txt" -Encoding UTF8
    
    Write-Host "Users backed up to azure-users-backup.txt" -ForegroundColor Gray
}

# Step 2: Export complete schema from Docker
Write-Host "`n[2/8] Exporting complete schema from Docker SQL..." -ForegroundColor Green

$schemaFile = ".\azure-complete-schema.sql"
$dataFile = ".\azure-complete-data.sql"

# Get tables in dependency order (tables with no FK first)
Write-Host "Analyzing table dependencies..." -ForegroundColor Gray

$tableOrder = docker exec $DockerContainer /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P 'YourStrong@Password123' -C `
    -Q @"
WITH deps AS (
    SELECT 
        t.name as TableName,
        0 as Level
    FROM sys.tables t
    WHERE t.is_ms_shipped = 0
        AND NOT EXISTS (
            SELECT 1 FROM sys.foreign_keys fk 
            WHERE fk.parent_object_id = t.object_id
        )
    
    UNION ALL
    
    SELECT 
        t.name,
        d.Level + 1
    FROM sys.tables t
    INNER JOIN sys.foreign_keys fk ON fk.parent_object_id = t.object_id
    INNER JOIN sys.tables p ON fk.referenced_object_id = p.object_id
    INNER JOIN deps d ON p.name = d.TableName
    WHERE t.is_ms_shipped = 0
)
SELECT DISTINCT TableName 
FROM deps
ORDER BY Level DESC, TableName
"@ -h -1

# Step 3: Generate drop script for Azure
Write-Host "`n[3/8] Generating cleanup script for Azure SQL..." -ForegroundColor Green

$dropScript = @"
-- Complete cleanup of Azure SQL Database
-- This will remove ALL objects

USE [sqldb-steel-estimation-sandbox];
GO

-- Disable all constraints
EXEC sp_msforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT all'
GO

-- Drop all foreign keys
DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql = @sql + 'ALTER TABLE [' + OBJECT_SCHEMA_NAME(parent_object_id) + '].[' + OBJECT_NAME(parent_object_id) + '] DROP CONSTRAINT [' + name + '];' + CHAR(13)
FROM sys.foreign_keys;
EXEC sp_executesql @sql;
GO

-- Drop all tables
DECLARE @sql2 NVARCHAR(MAX) = '';
SELECT @sql2 = @sql2 + 'DROP TABLE [' + SCHEMA_NAME(schema_id) + '].[' + name + '];' + CHAR(13)
FROM sys.tables WHERE is_ms_shipped = 0;
EXEC sp_executesql @sql2;
GO

PRINT 'All tables dropped successfully';
GO
"@

Out-File -FilePath ".\azure-cleanup.sql" -InputObject $dropScript -Encoding UTF8

# Step 4: Execute cleanup on Azure
Write-Host "`n[4/8] Cleaning Azure SQL Database..." -ForegroundColor Green

docker run --rm -v ${PWD}:/scripts mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S "nwiapps.database.windows.net" `
    -d "sqldb-steel-estimation-sandbox" `
    -U $Username `
    -P $Password `
    -i /scripts/azure-cleanup.sql

# Step 5: Export complete schema from Docker
Write-Host "`n[5/8] Extracting complete schema from Docker..." -ForegroundColor Green

# Start schema file
@"
-- Complete Steel Estimation Database Schema
-- Migrated from Docker to Azure SQL
-- Generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

USE [sqldb-steel-estimation-sandbox];
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

"@ | Out-File -FilePath $schemaFile -Encoding UTF8

# Export each table schema
foreach ($tableName in $tableOrder -split "`n" | Where-Object { $_.Trim() -ne "" }) {
    $table = $tableName.Trim()
    if ($table) {
        Write-Host "  Exporting schema for: $table" -ForegroundColor DarkGray
        
        # Get CREATE TABLE statement
        $createTable = docker exec $DockerContainer /opt/mssql-tools18/bin/sqlcmd `
            -S localhost -U sa -P 'YourStrong@Password123' -C `
            -Q @"
DECLARE @table_name NVARCHAR(128) = '$table';
DECLARE @sql NVARCHAR(MAX) = '';

-- Generate CREATE TABLE
SELECT @sql = 'CREATE TABLE [dbo].[' + @table_name + '] (' + CHAR(13);

-- Add columns
SELECT @sql = @sql + '    [' + c.name + '] ' + 
    TYPE_NAME(c.user_type_id) + 
    CASE 
        WHEN TYPE_NAME(c.user_type_id) IN ('varchar', 'nvarchar', 'char', 'nchar') 
        THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' 
                       WHEN TYPE_NAME(c.user_type_id) IN ('nvarchar', 'nchar') THEN CAST(c.max_length/2 AS VARCHAR)
                       ELSE CAST(c.max_length AS VARCHAR) END + ')'
        WHEN TYPE_NAME(c.user_type_id) IN ('decimal', 'numeric') 
        THEN '(' + CAST(c.precision AS VARCHAR) + ',' + CAST(c.scale AS VARCHAR) + ')'
        ELSE ''
    END +
    CASE WHEN c.is_identity = 1 THEN ' IDENTITY(1,1)' ELSE '' END +
    CASE WHEN c.is_nullable = 0 THEN ' NOT NULL' ELSE ' NULL' END +
    CASE 
        WHEN dc.definition IS NOT NULL THEN ' DEFAULT ' + dc.definition
        ELSE ''
    END +
    ',' + CHAR(13)
FROM sys.columns c
LEFT JOIN sys.default_constraints dc ON c.default_object_id = dc.object_id
WHERE c.object_id = OBJECT_ID(@table_name)
ORDER BY c.column_id;

-- Remove last comma
SET @sql = LEFT(@sql, LEN(@sql) - 2) + CHAR(13) + ');';

SELECT @sql;
"@ -h -1
        
        Add-Content -Path $schemaFile -Value $createTable
        Add-Content -Path $schemaFile -Value "GO`n"
    }
}

# Add Primary Keys
Write-Host "  Adding primary keys..." -ForegroundColor DarkGray
$pkScript = docker exec $DockerContainer /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P 'YourStrong@Password123' -C `
    -Q @"
SELECT 
    'ALTER TABLE [dbo].[' + t.name + '] ADD CONSTRAINT [' + pk.name + '] PRIMARY KEY (' +
    STUFF((
        SELECT ',[' + c.name + ']'
        FROM sys.index_columns ic
        INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = pk.parent_object_id AND ic.index_id = pk.unique_index_id
        ORDER BY ic.key_ordinal
        FOR XML PATH('')
    ), 1, 1, '') + ');'
FROM sys.key_constraints pk
INNER JOIN sys.tables t ON pk.parent_object_id = t.object_id
WHERE pk.type = 'PK' AND t.is_ms_shipped = 0
"@ -h -1

Add-Content -Path $schemaFile -Value "`n-- Primary Keys"
Add-Content -Path $schemaFile -Value $pkScript
Add-Content -Path $schemaFile -Value "GO`n"

# Add Foreign Keys
Write-Host "  Adding foreign keys..." -ForegroundColor DarkGray
$fkScript = docker exec $DockerContainer /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P 'YourStrong@Password123' -C `
    -Q @"
SELECT 
    'ALTER TABLE [dbo].[' + OBJECT_NAME(fk.parent_object_id) + '] ADD CONSTRAINT [' + fk.name + '] FOREIGN KEY ([' + 
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) + ']) REFERENCES [dbo].[' + 
    OBJECT_NAME(fk.referenced_object_id) + ']([' + 
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) + '])' +
    CASE 
        WHEN fk.delete_referential_action = 1 THEN ' ON DELETE CASCADE'
        ELSE ''
    END + ';'
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
WHERE OBJECT_SCHEMA_NAME(fk.parent_object_id) = 'dbo'
"@ -h -1

Add-Content -Path $schemaFile -Value "`n-- Foreign Keys"
Add-Content -Path $schemaFile -Value $fkScript
Add-Content -Path $schemaFile -Value "GO`n"

# Add Indexes
Write-Host "  Adding indexes..." -ForegroundColor DarkGray
$indexScript = docker exec $DockerContainer /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P 'YourStrong@Password123' -C `
    -Q @"
SELECT 
    'CREATE ' + CASE WHEN i.is_unique = 1 THEN 'UNIQUE ' ELSE '' END + 
    'INDEX [' + i.name + '] ON [dbo].[' + OBJECT_NAME(i.object_id) + '] (' +
    STUFF((
        SELECT ',[' + c.name + ']' + CASE WHEN ic.is_descending_key = 1 THEN ' DESC' ELSE '' END
        FROM sys.index_columns ic
        INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
        ORDER BY ic.key_ordinal
        FOR XML PATH('')
    ), 1, 1, '') + ');'
FROM sys.indexes i
WHERE i.is_primary_key = 0 
    AND i.is_unique_constraint = 0 
    AND i.type > 0
    AND OBJECT_SCHEMA_NAME(i.object_id) = 'dbo'
    AND i.name IS NOT NULL
"@ -h -1

Add-Content -Path $schemaFile -Value "`n-- Indexes"
Add-Content -Path $schemaFile -Value $indexScript
Add-Content -Path $schemaFile -Value "GO`n"

# Step 6: Apply schema to Azure
Write-Host "`n[6/8] Applying schema to Azure SQL..." -ForegroundColor Green

docker run --rm -v ${PWD}:/scripts mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S "nwiapps.database.windows.net" `
    -d "sqldb-steel-estimation-sandbox" `
    -U $Username `
    -P $Password `
    -i /scripts/azure-complete-schema.sql

if ($LASTEXITCODE -ne 0) {
    Write-Host "Schema creation failed. Check azure-complete-schema.sql for issues." -ForegroundColor Red
    exit 1
}

# Step 7: Export and import data
Write-Host "`n[7/8] Migrating data from Docker to Azure..." -ForegroundColor Green

# Export data using existing script
& ".\export-for-docker.ps1" `
    -ServerInstance "localhost" `
    -DatabaseName "SteelEstimationDB" `
    -OutputFile $dataFile `
    -DockerMode $true

# Import to Azure
Write-Host "Importing data to Azure SQL..." -ForegroundColor Gray
docker run --rm -v ${PWD}:/scripts mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S "nwiapps.database.windows.net" `
    -d "sqldb-steel-estimation-sandbox" `
    -U $Username `
    -P $Password `
    -i /scripts/azure-complete-data.sql

# Step 8: Verify migration
Write-Host "`n[8/8] Verifying migration..." -ForegroundColor Green

$verification = @"
SELECT 'Tables' as Category, COUNT(*) as Count FROM sys.tables WHERE is_ms_shipped = 0
UNION ALL
SELECT 'Users', COUNT(*) FROM Users
UNION ALL
SELECT 'Projects', COUNT(*) FROM Projects
UNION ALL
SELECT 'Companies', COUNT(*) FROM Companies
UNION ALL
SELECT 'ProcessingItems', COUNT(*) FROM ProcessingItems
UNION ALL
SELECT 'WeldingItems', COUNT(*) FROM WeldingItems
"@

docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S "nwiapps.database.windows.net" `
    -d "sqldb-steel-estimation-sandbox" `
    -U $Username `
    -P $Password `
    -Q $verification

# Save connection info
@"
# Azure SQL Database Configuration
AZURE_SQL_SERVER=nwiapps.database.windows.net
AZURE_SQL_DATABASE=sqldb-steel-estimation-sandbox
AZURE_SQL_USER=$Username
AZURE_SQL_PASSWORD=$Password
"@ | Out-File -FilePath ".env.azure" -Encoding UTF8

Write-Host "`n=== Migration Complete! ===" -ForegroundColor Green
Write-Host "Your Docker database has been completely migrated to Azure SQL" -ForegroundColor Cyan
Write-Host "`nTo run with Azure SQL:" -ForegroundColor Yellow
Write-Host "docker-compose -f docker-compose.azure.yml --env-file .env.azure up -d" -ForegroundColor Cyan

# Cleanup option
$cleanup = Read-Host "`nDelete temporary migration files? (yes/no)"
if ($cleanup -eq "yes") {
    Remove-Item ".\azure-cleanup.sql" -Force -ErrorAction SilentlyContinue
    Remove-Item ".\azure-complete-schema.sql" -Force -ErrorAction SilentlyContinue
    Remove-Item ".\azure-complete-data.sql" -Force -ErrorAction SilentlyContinue
    Write-Host "Temporary files cleaned up." -ForegroundColor Gray
}