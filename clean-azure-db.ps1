# Clean Azure SQL Database for Import
Write-Host "=== Cleaning Azure SQL Database ===" -ForegroundColor Cyan

$azureUsername = "admin@nwi@nwiapps"
$azurePassword = "Natweigh88"
$azureServer = "nwiapps.database.windows.net"
$azureDatabase = "sqldb-steel-estimation-sandbox"

Write-Host "This will remove ALL tables from Azure SQL to prepare for import" -ForegroundColor Yellow
$confirm = Read-Host "Continue? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Cancelled." -ForegroundColor Yellow
    exit
}

Write-Host "`nDropping all objects from Azure SQL..." -ForegroundColor Yellow

# SQL script to drop all objects
$dropAllSQL = @'
-- Drop all foreign keys first
DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql = @sql + 'ALTER TABLE [' + OBJECT_SCHEMA_NAME(parent_object_id) + '].[' + OBJECT_NAME(parent_object_id) + '] DROP CONSTRAINT [' + name + ']; '
FROM sys.foreign_keys;
IF @sql != '' EXEC sp_executesql @sql;

-- Drop all tables
DECLARE @sql2 NVARCHAR(MAX) = '';
SELECT @sql2 = @sql2 + 'DROP TABLE [' + SCHEMA_NAME(schema_id) + '].[' + name + ']; '
FROM sys.tables;
IF @sql2 != '' EXEC sp_executesql @sql2;

-- Drop all views
DECLARE @sql3 NVARCHAR(MAX) = '';
SELECT @sql3 = @sql3 + 'DROP VIEW [' + SCHEMA_NAME(schema_id) + '].[' + name + ']; '
FROM sys.views WHERE is_ms_shipped = 0;
IF @sql3 != '' EXEC sp_executesql @sql3;

-- Drop all stored procedures
DECLARE @sql4 NVARCHAR(MAX) = '';
SELECT @sql4 = @sql4 + 'DROP PROCEDURE [' + SCHEMA_NAME(schema_id) + '].[' + name + ']; '
FROM sys.procedures WHERE is_ms_shipped = 0;
IF @sql4 != '' EXEC sp_executesql @sql4;

-- Drop all functions
DECLARE @sql5 NVARCHAR(MAX) = '';
SELECT @sql5 = @sql5 + 'DROP FUNCTION [' + SCHEMA_NAME(schema_id) + '].[' + name + ']; '
FROM sys.objects WHERE type IN ('FN', 'IF', 'TF') AND is_ms_shipped = 0;
IF @sql5 != '' EXEC sp_executesql @sql5;

PRINT 'All objects dropped successfully';
'@

# Execute the cleanup
$dropAllSQL | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S $azureServer `
    -d $azureDatabase `
    -U $azureUsername `
    -P $azurePassword `
    -I

# Verify cleanup
Write-Host "`nVerifying cleanup..." -ForegroundColor Yellow
$tableCount = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S $azureServer `
    -d $azureDatabase `
    -U $azureUsername `
    -P $azurePassword `
    -Q "SELECT COUNT(*) FROM sys.tables" -h -1

Write-Host "Tables remaining: $($tableCount.Trim())" -ForegroundColor Green

if ([int]$tableCount.Trim() -eq 0) {
    Write-Host "`nAzure SQL database is now empty and ready for import!" -ForegroundColor Green
    Write-Host "Run the import again:" -ForegroundColor Yellow
    Write-Host ".\sqlpackage\SqlPackage.exe /Action:Import /TargetServerName:nwiapps.database.windows.net /TargetDatabaseName:sqldb-steel-estimation-sandbox /TargetUser:admin@nwi@nwiapps /TargetPassword:Natweigh88 /SourceFile:backups\SteelEstimation.bacpac" -ForegroundColor White
} else {
    Write-Host "Warning: Some tables still exist. You may need to drop them manually." -ForegroundColor Red
}