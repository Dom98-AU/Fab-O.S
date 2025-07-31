# Extract complete schema from local database
param(
    [string]$ServerInstance = "localhost",
    [string]$DatabaseName = "SteelEstimationDb_CloudDev",
    [string]$OutputFile = ".\docker\sql\02-complete-schema.sql"
)

Write-Host "Extracting complete schema from $DatabaseName..." -ForegroundColor Green

# Create output directory if it doesn't exist
$outputDir = Split-Path -Parent $OutputFile
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Extract schema using SqlPackage (if available) or SMO
try {
    # Try using SMO first
    Write-Host "Using SQL Server Management Objects (SMO) to extract schema..." -ForegroundColor Cyan
    
    $extractQuery = @"
-- This will generate the complete schema
DECLARE @sql NVARCHAR(MAX) = N'';

-- Drop existing tables (in reverse dependency order)
SELECT @sql = @sql + 'IF OBJECT_ID(''' + QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name) + ''', ''U'') IS NOT NULL DROP TABLE ' + QUOTENAME(SCHEMA_NAME(schema_id)) + '.' + QUOTENAME(name) + ';' + CHAR(13)
FROM sys.tables
ORDER BY create_date DESC;

PRINT '-- Drop existing tables';
PRINT @sql;
PRINT '';

-- Extract table definitions
EXEC sp_helpdb '$DatabaseName';
"@

    # For now, let's use a simpler approach - script out the schema
    $schemaScript = @"
-- Steel Estimation Database Schema
-- Generated from local database: $DatabaseName

USE SteelEstimationDB;
GO

-- Drop existing tables in dependency order
IF OBJECT_ID('WeldingItemConnections', 'U') IS NOT NULL DROP TABLE WeldingItemConnections;
IF OBJECT_ID('WeldingItems', 'U') IS NOT NULL DROP TABLE WeldingItems;
IF OBJECT_ID('ProcessingItems', 'U') IS NOT NULL DROP TABLE ProcessingItems;
IF OBJECT_ID('PackBundles', 'U') IS NOT NULL DROP TABLE PackBundles;
IF OBJECT_ID('DeliveryBundles', 'U') IS NOT NULL DROP TABLE DeliveryBundles;
IF OBJECT_ID('EstimationTimeLogs', 'U') IS NOT NULL DROP TABLE EstimationTimeLogs;
IF OBJECT_ID('Packages', 'U') IS NOT NULL DROP TABLE Packages;
IF OBJECT_ID('Estimations', 'U') IS NOT NULL DROP TABLE Estimations;
IF OBJECT_ID('ProjectMaterials', 'U') IS NOT NULL DROP TABLE ProjectMaterials;
IF OBJECT_ID('Projects', 'U') IS NOT NULL DROP TABLE Projects;
IF OBJECT_ID('Customers', 'U') IS NOT NULL DROP TABLE Customers;
IF OBJECT_ID('EfficiencyRates', 'U') IS NOT NULL DROP TABLE EfficiencyRates;
IF OBJECT_ID('UserRoles', 'U') IS NOT NULL DROP TABLE UserRoles;
IF OBJECT_ID('Roles', 'U') IS NOT NULL DROP TABLE Roles;
IF OBJECT_ID('Users', 'U') IS NOT NULL DROP TABLE Users;
IF OBJECT_ID('Companies', 'U') IS NOT NULL DROP TABLE Companies;
IF OBJECT_ID('Postcodes', 'U') IS NOT NULL DROP TABLE Postcodes;
IF OBJECT_ID('__EFMigrationsHistory', 'U') IS NOT NULL DROP TABLE __EFMigrationsHistory;
GO

"@

    # Use SQLCMD to get the actual schema
    Write-Host "Extracting schema using SQLCMD..." -ForegroundColor Yellow
    
    # Get all tables
    $tables = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME"
    
    foreach ($table in $tables) {
        $tableName = $table.TABLE_NAME
        Write-Host "  Extracting schema for table: $tableName" -ForegroundColor Gray
        
        # Get create table script using sp_helptext alternative
        $tableScript = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query "
            DECLARE @TableName NVARCHAR(128) = '$tableName'
            DECLARE @sql NVARCHAR(MAX) = ''
            
            -- Get table definition
            SELECT @sql = @sql + 'CREATE TABLE [' + @TableName + '] (' + CHAR(13)
            
            -- Get columns
            SELECT @sql = @sql + '    [' + COLUMN_NAME + '] ' + 
                DATA_TYPE + 
                CASE 
                    WHEN DATA_TYPE IN ('varchar', 'nvarchar', 'char', 'nchar') 
                    THEN '(' + CASE WHEN CHARACTER_MAXIMUM_LENGTH = -1 THEN 'MAX' ELSE CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR) END + ')'
                    WHEN DATA_TYPE IN ('decimal', 'numeric') 
                    THEN '(' + CAST(NUMERIC_PRECISION AS VARCHAR) + ',' + CAST(NUMERIC_SCALE AS VARCHAR) + ')'
                    ELSE ''
                END +
                CASE WHEN IS_NULLABLE = 'NO' THEN ' NOT NULL' ELSE ' NULL' END +
                CASE WHEN COLUMN_DEFAULT IS NOT NULL THEN ' DEFAULT ' + COLUMN_DEFAULT ELSE '' END +
                ',' + CHAR(13)
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_NAME = @TableName
            ORDER BY ORDINAL_POSITION
            
            SELECT @sql AS Script
        " -MaxCharLength 65536
        
        if ($tableScript.Script) {
            $schemaScript += "`n" + $tableScript.Script
        }
    }
    
    # For now, let's create a basic script to run the export command
    Write-Host "Creating extraction script..." -ForegroundColor Cyan
    
    $extractionScript = @'
# Run this in PowerShell to extract your complete schema
# This will generate the schema using SQL Server tools

$serverInstance = "localhost"
$database = "SteelEstimationDb_CloudDev"
$outputFile = ".\docker\sql\02-complete-schema.sql"

Write-Host "Please use SQL Server Management Studio (SSMS) to:" -ForegroundColor Yellow
Write-Host "1. Connect to $serverInstance" -ForegroundColor Cyan
Write-Host "2. Right-click on database '$database'" -ForegroundColor Cyan
Write-Host "3. Select Tasks > Generate Scripts" -ForegroundColor Cyan
Write-Host "4. Choose 'Script entire database and all database objects'" -ForegroundColor Cyan
Write-Host "5. In Advanced options set:" -ForegroundColor Cyan
Write-Host "   - Types of data to script: Schema only" -ForegroundColor Green
Write-Host "   - Script Indexes: True" -ForegroundColor Green
Write-Host "   - Script Primary Keys: True" -ForegroundColor Green
Write-Host "   - Script Foreign Keys: True" -ForegroundColor Green
Write-Host "   - Script Check Constraints: True" -ForegroundColor Green
Write-Host "6. Save to: $outputFile" -ForegroundColor Cyan

Write-Host "`nAlternatively, install SqlPackage and run:" -ForegroundColor Yellow
Write-Host "SqlPackage /a:Script /ssn:$serverInstance /sdn:$database /tf:$outputFile /p:ScriptDatabaseOptions=False" -ForegroundColor Green
'@
    
    $extractionScript | Out-File -FilePath ".\extract-schema-instructions.ps1" -Encoding UTF8
    
    Write-Host "`nSchema extraction instructions saved to: extract-schema-instructions.ps1" -ForegroundColor Green
    Write-Host "Please follow the instructions in that file to extract your complete schema." -ForegroundColor Yellow
    
} catch {
    Write-Host "Error extracting schema: $_" -ForegroundColor Red
}