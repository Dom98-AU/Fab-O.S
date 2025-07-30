# Setup Azure SQL Database Schema and Migrate Data
param(
    [Parameter(Mandatory=$true)]
    [string]$AzureUsername,
    
    [Parameter(Mandatory=$true)]
    [string]$AzurePassword,
    
    [string]$DockerContainer = "steel-estimation-sql"
)

Write-Host "=== Azure SQL Database Setup ===" -ForegroundColor Cyan
Write-Host "Server: nwiapps.database.windows.net" -ForegroundColor Yellow
Write-Host "Database: sqldb-steel-estimation-sandbox" -ForegroundColor Yellow

# Test Azure SQL connection
Write-Host "`n[1/6] Testing Azure SQL connection..." -ForegroundColor Green
$testConnection = docker run --rm mcr.microsoft.com/mssql-tools /opt/mssql-tools18/bin/sqlcmd `
    -S "nwiapps.database.windows.net" `
    -d "master" `
    -U $AzureUsername `
    -P $AzurePassword `
    -C `
    -Q "SELECT name FROM sys.databases WHERE name = 'sqldb-steel-estimation-sandbox'"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Cannot connect to Azure SQL. Please check credentials and firewall." -ForegroundColor Red
    exit 1
}

# Step 1: Export schema from Docker
Write-Host "`n[2/6] Extracting schema from Docker SQL..." -ForegroundColor Green

$schemaFile = ".\azure-schema.sql"
$dataFile = ".\azure-data.sql"

# Generate CREATE statements for all tables
$schemaScript = @"
-- Azure SQL Database Schema
-- Generated from Docker SQL Server

USE [sqldb-steel-estimation-sandbox];
GO

-- Drop existing objects in correct order (reverse dependency)
"@

# Get table creation order
docker exec $DockerContainer /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Password123' -C -Q @"
SET NOCOUNT ON;
-- Get tables in dependency order
WITH TableHierarchy AS (
    SELECT 
        t.name AS TableName,
        0 as Level
    FROM sys.tables t
    WHERE NOT EXISTS (
        SELECT 1 FROM sys.foreign_keys fk 
        WHERE fk.parent_object_id = t.object_id
    )
    
    UNION ALL
    
    SELECT 
        t.name,
        th.Level + 1
    FROM sys.tables t
    INNER JOIN sys.foreign_keys fk ON fk.parent_object_id = t.object_id
    INNER JOIN sys.tables ref ON fk.referenced_object_id = ref.object_id
    INNER JOIN TableHierarchy th ON ref.name = th.TableName
)
SELECT DISTINCT 
    'IF OBJECT_ID(''[dbo].[' + TableName + ']'', ''U'') IS NOT NULL DROP TABLE [dbo].[' + TableName + '];' AS DropStatement
FROM TableHierarchy
ORDER BY 1 DESC;
"@ -h -1 | Out-File -FilePath $schemaFile -Encoding UTF8

# Add GO statement
Add-Content -Path $schemaFile -Value "GO`n"

# Get schema for all tables
Write-Host "Extracting table definitions..." -ForegroundColor Gray

# For each table, generate CREATE statement
$tables = docker exec $DockerContainer /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Password123' -C -h -1 -Q "SELECT name FROM sys.tables WHERE is_ms_shipped = 0 ORDER BY name"

foreach ($table in $tables -split "`n" | Where-Object { $_.Trim() -ne "" }) {
    $tableName = $table.Trim()
    if ($tableName) {
        Write-Host "  Processing table: $tableName" -ForegroundColor DarkGray
        
        # Get table structure
        $tableScript = docker exec $DockerContainer /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Password123' -C -h -1 -W -Q @"
DECLARE @TableName NVARCHAR(128) = '$tableName'
DECLARE @sql NVARCHAR(MAX) = ''

-- Table creation
SELECT @sql = 'CREATE TABLE [dbo].[' + @TableName + '] (' + CHAR(13)

-- Columns
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
    ',' + CHAR(13)
FROM sys.columns c
WHERE c.object_id = OBJECT_ID(@TableName)
ORDER BY c.column_id

-- Remove last comma
SET @sql = LEFT(@sql, LEN(@sql) - 2) + CHAR(13) + ');'

SELECT @sql
"@
        
        Add-Content -Path $schemaFile -Value $tableScript
        Add-Content -Path $schemaFile -Value "GO`n"
    }
}

# Add primary keys
Write-Host "Adding primary key constraints..." -ForegroundColor Gray
$pkScript = docker exec $DockerContainer /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Password123' -C -h -1 -Q @"
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
WHERE pk.type = 'PK'
"@

Add-Content -Path $schemaFile -Value "`n-- Primary Keys"
Add-Content -Path $schemaFile -Value $pkScript
Add-Content -Path $schemaFile -Value "GO`n"

# Add foreign keys
Write-Host "Adding foreign key constraints..." -ForegroundColor Gray
$fkScript = docker exec $DockerContainer /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Password123' -C -h -1 -Q @"
SELECT 
    'ALTER TABLE [dbo].[' + OBJECT_NAME(fk.parent_object_id) + '] ADD CONSTRAINT [' + fk.name + '] FOREIGN KEY ([' + 
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) + ']) REFERENCES [dbo].[' + 
    OBJECT_NAME(fk.referenced_object_id) + ']([' + 
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) + ']);'
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
"@

Add-Content -Path $schemaFile -Value "`n-- Foreign Keys"
Add-Content -Path $schemaFile -Value $fkScript
Add-Content -Path $schemaFile -Value "GO`n"

# Step 3: Apply schema to Azure SQL
Write-Host "`n[3/6] Applying schema to Azure SQL..." -ForegroundColor Green
docker run --rm -v ${PWD}:/scripts mcr.microsoft.com/mssql-tools /opt/mssql-tools18/bin/sqlcmd `
    -S "nwiapps.database.windows.net" `
    -d "sqldb-steel-estimation-sandbox" `
    -U $AzureUsername `
    -P $AzurePassword `
    -C `
    -i /scripts/azure-schema.sql

if ($LASTEXITCODE -ne 0) {
    Write-Host "Schema creation failed. Check azure-schema.sql for issues." -ForegroundColor Red
    exit 1
}

# Step 4: Export data
Write-Host "`n[4/6] Exporting data from Docker SQL..." -ForegroundColor Green

# Use the existing export script logic
& ".\export-for-docker.ps1" -ServerInstance "localhost" -DatabaseName "SteelEstimationDB" -OutputFile $dataFile -DockerMode $true

# Step 5: Import data to Azure
Write-Host "`n[5/6] Importing data to Azure SQL..." -ForegroundColor Green
docker run --rm -v ${PWD}:/scripts mcr.microsoft.com/mssql-tools /opt/mssql-tools18/bin/sqlcmd `
    -S "nwiapps.database.windows.net" `
    -d "sqldb-steel-estimation-sandbox" `
    -U $AzureUsername `
    -P $AzurePassword `
    -C `
    -i /scripts/azure-data.sql

# Step 6: Verify migration
Write-Host "`n[6/6] Verifying migration..." -ForegroundColor Green
$verification = docker run --rm mcr.microsoft.com/mssql-tools /opt/mssql-tools18/bin/sqlcmd `
    -S "nwiapps.database.windows.net" `
    -d "sqldb-steel-estimation-sandbox" `
    -U $AzureUsername `
    -P $AzurePassword `
    -C `
    -Q "SELECT t.name AS TableName, p.rows AS Records FROM sys.tables t JOIN sys.partitions p ON t.object_id = p.object_id WHERE p.index_id <= 1 ORDER BY t.name"

Write-Host $verification

# Save credentials
@"
# Azure SQL Database Configuration
AZURE_SQL_SERVER=nwiapps.database.windows.net
AZURE_SQL_DATABASE=sqldb-steel-estimation-sandbox
AZURE_SQL_USER=$AzureUsername
AZURE_SQL_PASSWORD=$AzurePassword
"@ | Out-File -FilePath ".env.azure" -Encoding UTF8

Write-Host "`n=== Migration Complete! ===" -ForegroundColor Green
Write-Host "To run with Azure SQL:" -ForegroundColor Cyan
Write-Host "docker-compose -f docker-compose.azure.yml --env-file .env.azure up -d" -ForegroundColor Yellow

# Cleanup temporary files
# Remove-Item $schemaFile -Force -ErrorAction SilentlyContinue
# Remove-Item $dataFile -Force -ErrorAction SilentlyContinue