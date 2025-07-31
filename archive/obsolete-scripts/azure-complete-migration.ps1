# Complete Azure SQL Migration Script
# This script extracts the full schema from Docker and applies it to Azure SQL

Write-Host "=== Complete Docker to Azure SQL Migration ===" -ForegroundColor Cyan

$azureUsername = "admin@nwi@nwiapps"
$azurePassword = "Natweigh88"
$azureServer = "nwiapps.database.windows.net"
$azureDatabase = "sqldb-steel-estimation-sandbox"

# Step 1: Extract complete schema from Docker SQL
Write-Host "`n[1/5] Extracting complete schema from Docker SQL..." -ForegroundColor Green

# Get all tables from Docker in dependency order
$tableOrder = @(
    "Companies",
    "AspNetRoles",
    "AspNetUsers",
    "AspNetUserRoles",
    "AspNetUserClaims",
    "AspNetUserLogins",
    "AspNetUserTokens",
    "AspNetRoleClaims",
    "Projects",
    "Estimations",
    "EstimationTimeLogs",
    "EfficiencyRates",
    "Packages",
    "ProcessingItems",
    "DeliveryBundles",
    "PackBundles",
    "WeldingItems",
    "WeldingItemConnections",
    "Customers",
    "Postcodes"
)

# Create schema file
$schemaFile = "./azure-complete-schema.sql"
@"
-- Complete Azure SQL Schema
-- Generated from Docker SQL Server

USE [sqldb-steel-estimation-sandbox];
GO

"@ | Out-File -FilePath $schemaFile -Encoding UTF8

# Extract each table's schema
foreach ($table in $tableOrder) {
    Write-Host "  Extracting schema for: $table" -ForegroundColor Gray
    
    # Get table definition using information schema
    $tableSchema = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd `
        -S localhost -U sa -P 'YourStrong@Password123' -C `
        -d SteelEstimationDB `
        -Q "SELECT 
            'CREATE TABLE [dbo].[$table] (' + CHAR(13) +
            STUFF((
                SELECT ',' + CHAR(13) + '    [' + c.name + '] ' + 
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
                    CASE WHEN dc.definition IS NOT NULL THEN ' DEFAULT ' + dc.definition ELSE '' END
                FROM sys.columns c
                LEFT JOIN sys.default_constraints dc ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id
                WHERE c.object_id = OBJECT_ID('$table')
                ORDER BY c.column_id
                FOR XML PATH('')
            ), 1, 1, '') + CHAR(13) + ');'"
        -h -1 -W
    
    if ($tableSchema -and $tableSchema.Trim()) {
        Add-Content -Path $schemaFile -Value ""
        Add-Content -Path $schemaFile -Value "-- Table: $table"
        Add-Content -Path $schemaFile -Value "IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[$table]') AND type in (N'U'))"
        Add-Content -Path $schemaFile -Value "BEGIN"
        Add-Content -Path $schemaFile -Value ($tableSchema -join "`n")
        Add-Content -Path $schemaFile -Value "END"
        Add-Content -Path $schemaFile -Value "GO"
    }
}

# Step 2: Extract constraints
Write-Host "`n[2/5] Extracting constraints..." -ForegroundColor Green

# Primary Keys
$primaryKeys = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P 'YourStrong@Password123' -C `
    -d SteelEstimationDB `
    -Q "SELECT 
        'ALTER TABLE [dbo].[' + t.name + '] ADD CONSTRAINT [' + pk.name + '] PRIMARY KEY CLUSTERED (' +
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
    WHERE pk.type = 'PK'" -h -1 -W

Add-Content -Path $schemaFile -Value "`n-- Primary Keys"
$primaryKeys -split "`n" | Where-Object { $_.Trim() } | ForEach-Object {
    $constraint = $_.Trim()
    if ($constraint) {
        Add-Content -Path $schemaFile -Value "IF NOT EXISTS (SELECT * FROM sys.key_constraints WHERE name = '$($constraint -match "CONSTRAINT \[([^\]]+)\]" | Out-Null; $matches[1])')"
        Add-Content -Path $schemaFile -Value "BEGIN"
        Add-Content -Path $schemaFile -Value "    $constraint"
        Add-Content -Path $schemaFile -Value "END"
        Add-Content -Path $schemaFile -Value "GO"
    }
}

# Foreign Keys
$foreignKeys = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P 'YourStrong@Password123' -C `
    -d SteelEstimationDB `
    -Q "SELECT 
        'ALTER TABLE [dbo].[' + OBJECT_NAME(fk.parent_object_id) + '] ADD CONSTRAINT [' + fk.name + '] FOREIGN KEY ([' + 
        COL_NAME(fkc.parent_object_id, fkc.parent_column_id) + ']) REFERENCES [dbo].[' + 
        OBJECT_NAME(fk.referenced_object_id) + '] ([' + 
        COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) + '])' +
        CASE 
            WHEN fk.delete_referential_action = 1 THEN ' ON DELETE CASCADE'
            WHEN fk.delete_referential_action = 2 THEN ' ON DELETE SET NULL'
            ELSE ''
        END + ';'
    FROM sys.foreign_keys fk
    INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id" -h -1 -W

Add-Content -Path $schemaFile -Value "`n-- Foreign Keys"
$foreignKeys -split "`n" | Where-Object { $_.Trim() } | ForEach-Object {
    $constraint = $_.Trim()
    if ($constraint) {
        Add-Content -Path $schemaFile -Value "IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = '$($constraint -match "CONSTRAINT \[([^\]]+)\]" | Out-Null; $matches[1])')"
        Add-Content -Path $schemaFile -Value "BEGIN"
        Add-Content -Path $schemaFile -Value "    $constraint"
        Add-Content -Path $schemaFile -Value "END"
        Add-Content -Path $schemaFile -Value "GO"
    }
}

# Indexes
$indexes = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P 'YourStrong@Password123' -C `
    -d SteelEstimationDB `
    -Q "SELECT 
        'CREATE ' + CASE WHEN i.is_unique = 1 THEN 'UNIQUE ' ELSE '' END + 
        'INDEX [' + i.name + '] ON [dbo].[' + OBJECT_NAME(i.object_id) + '] (' +
        STUFF((
            SELECT ',[' + c.name + ']'
            FROM sys.index_columns ic
            INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
            WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
            ORDER BY ic.key_ordinal
            FOR XML PATH('')
        ), 1, 1, '') + ')' +
        CASE WHEN i.has_filter = 1 THEN ' WHERE ' + i.filter_definition ELSE '' END + ';'
    FROM sys.indexes i
    WHERE i.is_primary_key = 0 AND i.is_unique_constraint = 0 AND i.type > 0
    AND OBJECT_NAME(i.object_id) IN ('$($tableOrder -join "','")')" -h -1 -W

Add-Content -Path $schemaFile -Value "`n-- Indexes"
$indexes -split "`n" | Where-Object { $_.Trim() } | ForEach-Object {
    $index = $_.Trim()
    if ($index) {
        Add-Content -Path $schemaFile -Value "IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = '$($index -match "INDEX \[([^\]]+)\]" | Out-Null; $matches[1])')"
        Add-Content -Path $schemaFile -Value "BEGIN"
        Add-Content -Path $schemaFile -Value "    $index"
        Add-Content -Path $schemaFile -Value "END"
        Add-Content -Path $schemaFile -Value "GO"
    }
}

Write-Host "  Schema extraction complete" -ForegroundColor Green

# Step 3: Apply schema to Azure SQL
Write-Host "`n[3/5] Applying schema to Azure SQL..." -ForegroundColor Green

# First, drop existing foreign keys
Write-Host "  Dropping existing foreign keys..." -ForegroundColor Gray
$dropFKs = @"
DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql = @sql + 'ALTER TABLE [' + OBJECT_NAME(parent_object_id) + '] DROP CONSTRAINT [' + name + ']; '
FROM sys.foreign_keys;
EXEC sp_executesql @sql;
"@

$dropFKs | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S $azureServer `
    -d $azureDatabase `
    -U $azureUsername `
    -P $azurePassword 2>$null

# Apply the schema
Get-Content $schemaFile | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S $azureServer `
    -d $azureDatabase `
    -U $azureUsername `
    -P $azurePassword `
    -I 2>$null

# Step 4: Export data from Docker
Write-Host "`n[4/5] Exporting data from Docker..." -ForegroundColor Green

$dataFile = "./azure-complete-data.sql"
@"
-- Data export from Docker SQL
USE [sqldb-steel-estimation-sandbox];
GO

SET NOCOUNT ON;
GO

"@ | Out-File -FilePath $dataFile -Encoding UTF8

foreach ($table in $tableOrder) {
    Write-Host "  Exporting data from: $table" -ForegroundColor Gray
    
    # Check if table has data
    $rowCount = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd `
        -S localhost -U sa -P 'YourStrong@Password123' -C `
        -d SteelEstimationDB `
        -Q "SELECT COUNT(*) FROM $table" -h -1
    
    if ([int]$rowCount.Trim() -gt 0) {
        # Get column list
        $columns = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd `
            -S localhost -U sa -P 'YourStrong@Password123' -C `
            -d SteelEstimationDB `
            -Q "SELECT STRING_AGG('[' + name + ']', ',') FROM sys.columns WHERE object_id = OBJECT_ID('$table') AND is_computed = 0" -h -1
        
        # Check for identity column
        $hasIdentity = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd `
            -S localhost -U sa -P 'YourStrong@Password123' -C `
            -d SteelEstimationDB `
            -Q "SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID('$table') AND is_identity = 1" -h -1
        
        if ([int]$hasIdentity.Trim() -gt 0) {
            Add-Content -Path $dataFile -Value "SET IDENTITY_INSERT [dbo].[$table] ON;"
        }
        
        # Export data using bcp format
        Add-Content -Path $dataFile -Value "DELETE FROM [dbo].[$table];"
        
        # Generate INSERT statements
        $insertScript = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd `
            -S localhost -U sa -P 'YourStrong@Password123' -C `
            -d SteelEstimationDB `
            -Q "SET NOCOUNT ON;
                DECLARE @sql NVARCHAR(MAX) = '';
                SELECT @sql = 'INSERT INTO [$table] ($($columns.Trim())) VALUES (' + 
                    STUFF((
                        SELECT ',' + 
                            CASE 
                                WHEN c.user_type_id IN (167, 175, 231, 239) THEN 
                                    CASE WHEN ' + QUOTENAME(c.name) + ' IS NULL THEN ''NULL'' ELSE '''''''' + REPLACE(CAST(' + QUOTENAME(c.name) + ' AS NVARCHAR(MAX)), '''''''', '''''''''''') + '''''''' END'
                                WHEN c.user_type_id IN (40, 41, 42, 43, 58, 61) THEN 
                                    'CASE WHEN ' + QUOTENAME(c.name) + ' IS NULL THEN ''NULL'' ELSE '''''''' + CONVERT(NVARCHAR(30), ' + QUOTENAME(c.name) + ', 121) + '''''''' END'
                                WHEN c.user_type_id = 104 THEN 
                                    'CASE WHEN ' + QUOTENAME(c.name) + ' IS NULL THEN ''NULL'' ELSE CAST(' + QUOTENAME(c.name) + ' AS NVARCHAR) END'
                                ELSE 
                                    'CASE WHEN ' + QUOTENAME(c.name) + ' IS NULL THEN ''NULL'' ELSE CAST(' + QUOTENAME(c.name) + ' AS NVARCHAR(MAX)) END'
                            END
                        FROM sys.columns c
                        WHERE c.object_id = OBJECT_ID('$table') AND c.is_computed = 0
                        ORDER BY c.column_id
                        FOR XML PATH('')
                    ), 1, 1, '') + ');'
                FROM $table;
                SELECT @sql;" -h -1 -W -s "|" -k
        
        if ($insertScript -and $insertScript.Trim()) {
            $insertScript -split "`n" | Where-Object { $_.Trim() -and $_.Trim() -ne "INSERT INTO [$table] ($($columns.Trim())) VALUES ();" } | ForEach-Object {
                Add-Content -Path $dataFile -Value $_.Trim()
            }
        }
        
        if ([int]$hasIdentity.Trim() -gt 0) {
            Add-Content -Path $dataFile -Value "SET IDENTITY_INSERT [dbo].[$table] OFF;"
        }
        Add-Content -Path $dataFile -Value "GO"
    }
}

# Step 5: Import data to Azure
Write-Host "`n[5/5] Importing data to Azure SQL..." -ForegroundColor Green

Get-Content $dataFile | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S $azureServer `
    -d $azureDatabase `
    -U $azureUsername `
    -P $azurePassword `
    -I 2>$null

# Verify migration
Write-Host "`nVerifying migration..." -ForegroundColor Green
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S $azureServer `
    -d $azureDatabase `
    -U $azureUsername `
    -P $azurePassword `
    -Q "SELECT t.name AS TableName, p.rows AS RowCount 
        FROM sys.tables t 
        INNER JOIN sys.partitions p ON t.object_id = p.object_id 
        WHERE p.index_id IN (0,1) 
        ORDER BY t.name"

Write-Host "`nMigration complete!" -ForegroundColor Green
Write-Host "Schema file: $schemaFile" -ForegroundColor Gray
Write-Host "Data file: $dataFile" -ForegroundColor Gray