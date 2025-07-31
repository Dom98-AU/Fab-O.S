# Migrate exact schema and data from local to Docker
param(
    [string]$ServerInstance = "localhost",
    [string]$DatabaseName = "SteelEstimationDb_CloudDev",
    [string]$ContainerName = "steel-estimation-sql",
    [string]$Password = "YourStrong@Password123"
)

Write-Host "=== Migrating Exact Schema and Data to Docker ===" -ForegroundColor Cyan
Write-Host "This will recreate your local database structure exactly in Docker" -ForegroundColor Yellow

# Step 1: Export complete schema with all objects
Write-Host "`n[1/4] Exporting complete database schema..." -ForegroundColor Green

$schemaFile = ".\docker\sql\complete-schema.sql"
$dataFile = ".\docker\sql\complete-data.sql"

# Ensure directory exists
$outputDir = Split-Path -Parent $schemaFile
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Export schema using PowerShell and SQL
Write-Host "Extracting schema objects..." -ForegroundColor Cyan

# Get all user tables
$tables = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query @"
SELECT 
    t.name AS TableName,
    s.name AS SchemaName
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.is_ms_shipped = 0
ORDER BY t.name
"@

# Build schema script
$schemaScript = @"
-- Complete Schema for Steel Estimation Database
-- Generated from: $DatabaseName on $ServerInstance
-- Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

USE SteelEstimationDB;
GO

-- Drop all foreign keys first
DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql = @sql + 'ALTER TABLE [' + OBJECT_SCHEMA_NAME(parent_object_id) + '].[' + OBJECT_NAME(parent_object_id) + '] DROP CONSTRAINT [' + name + '];' + CHAR(13)
FROM sys.foreign_keys;
EXEC sp_executesql @sql;
GO

-- Drop all tables
"@

# Add drop statements for all tables
foreach ($table in $tables) {
    $schemaScript += "IF OBJECT_ID('[$($table.SchemaName)].[$($table.TableName)]', 'U') IS NOT NULL DROP TABLE [$($table.SchemaName)].[$($table.TableName)];`n"
}
$schemaScript += "GO`n`n"

Write-Host "Generating CREATE TABLE statements..." -ForegroundColor Gray

# Generate CREATE TABLE statements for each table
foreach ($table in $tables) {
    $tableName = $table.TableName
    $schemaName = $table.SchemaName
    
    Write-Host "  Processing table: $schemaName.$tableName" -ForegroundColor DarkGray
    
    # Get table creation script
    $createScript = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query @"
DECLARE @TableName NVARCHAR(128) = '$tableName'
DECLARE @SchemaName NVARCHAR(128) = '$schemaName'
DECLARE @SQL NVARCHAR(MAX) = ''

-- Start CREATE TABLE
SET @SQL = 'CREATE TABLE [' + @SchemaName + '].[' + @TableName + '] (' + CHAR(13)

-- Add columns
SELECT @SQL = @SQL + '    [' + c.name + '] ' + 
    t.name + 
    CASE 
        WHEN t.name IN ('varchar', 'nvarchar', 'char', 'nchar') 
        THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' 
                       WHEN t.name IN ('nvarchar', 'nchar') THEN CAST(c.max_length/2 AS VARCHAR)
                       ELSE CAST(c.max_length AS VARCHAR) END + ')'
        WHEN t.name IN ('decimal', 'numeric') 
        THEN '(' + CAST(c.precision AS VARCHAR) + ',' + CAST(c.scale AS VARCHAR) + ')'
        WHEN t.name IN ('float')
        THEN '(' + CAST(c.precision AS VARCHAR) + ')'
        ELSE ''
    END +
    CASE WHEN c.is_identity = 1 THEN ' IDENTITY(' + CAST(IDENT_SEED(@SchemaName + '.' + @TableName) AS VARCHAR) + ',' + CAST(IDENT_INCR(@SchemaName + '.' + @TableName) AS VARCHAR) + ')' ELSE '' END +
    CASE WHEN c.is_nullable = 0 THEN ' NOT NULL' ELSE ' NULL' END +
    CASE WHEN dc.definition IS NOT NULL THEN ' DEFAULT ' + dc.definition ELSE '' END +
    ',' + CHAR(13)
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
LEFT JOIN sys.default_constraints dc ON c.default_object_id = dc.object_id
WHERE c.object_id = OBJECT_ID(@SchemaName + '.' + @TableName)
ORDER BY c.column_id

-- Remove last comma
SET @SQL = LEFT(@SQL, LEN(@SQL) - 2) + CHAR(13) + ');' + CHAR(13)

SELECT @SQL AS CreateStatement
"@ -MaxCharLength 65536

    if ($createScript.CreateStatement) {
        $schemaScript += $createScript.CreateStatement + "`nGO`n`n"
    }
}

# Add primary keys
Write-Host "Adding primary key constraints..." -ForegroundColor Gray
$pkScript = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query @"
SELECT 
    'ALTER TABLE [' + s.name + '].[' + t.name + '] ADD CONSTRAINT [' + pk.name + '] PRIMARY KEY (' +
    STUFF((
        SELECT ',[' + c.name + ']'
        FROM sys.index_columns ic
        INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = pk.parent_object_id AND ic.index_id = pk.unique_index_id
        ORDER BY ic.key_ordinal
        FOR XML PATH('')
    ), 1, 1, '') + ');' AS PkStatement
FROM sys.key_constraints pk
INNER JOIN sys.tables t ON pk.parent_object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE pk.type = 'PK'
"@

foreach ($pk in $pkScript) {
    if ($pk.PkStatement) {
        $schemaScript += $pk.PkStatement + "`n"
    }
}
$schemaScript += "GO`n`n"

# Add foreign keys
Write-Host "Adding foreign key constraints..." -ForegroundColor Gray
$fkScript = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query @"
SELECT 
    'ALTER TABLE [' + OBJECT_SCHEMA_NAME(fk.parent_object_id) + '].[' + OBJECT_NAME(fk.parent_object_id) + '] ADD CONSTRAINT [' + fk.name + '] FOREIGN KEY ([' + 
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) + ']) REFERENCES [' + 
    OBJECT_SCHEMA_NAME(fk.referenced_object_id) + '].[' + OBJECT_NAME(fk.referenced_object_id) + ']([' + 
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) + '])' +
    CASE 
        WHEN fk.delete_referential_action = 1 THEN ' ON DELETE CASCADE'
        WHEN fk.delete_referential_action = 2 THEN ' ON DELETE SET NULL'
        ELSE ''
    END + ';' AS FkStatement
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
"@

foreach ($fk in $fkScript) {
    if ($fk.FkStatement) {
        $schemaScript += $fk.FkStatement + "`n"
    }
}
$schemaScript += "GO`n`n"

# Add indexes
Write-Host "Adding indexes..." -ForegroundColor Gray
$indexScript = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query @"
SELECT 
    'CREATE ' + CASE WHEN i.is_unique = 1 THEN 'UNIQUE ' ELSE '' END + 
    i.type_desc COLLATE DATABASE_DEFAULT + ' INDEX [' + i.name + '] ON [' + 
    OBJECT_SCHEMA_NAME(i.object_id) + '].[' + OBJECT_NAME(i.object_id) + '] (' +
    STUFF((
        SELECT ',[' + c.name + ']' + CASE WHEN ic.is_descending_key = 1 THEN ' DESC' ELSE '' END
        FROM sys.index_columns ic
        INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
        ORDER BY ic.key_ordinal
        FOR XML PATH('')
    ), 1, 1, '') + ')' +
    CASE 
        WHEN EXISTS (SELECT 1 FROM sys.index_columns ic WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 1)
        THEN ' INCLUDE (' + STUFF((
            SELECT ',[' + c.name + ']'
            FROM sys.index_columns ic
            INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
            WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 1
            ORDER BY ic.index_column_id
            FOR XML PATH('')
        ), 1, 1, '') + ')'
        ELSE ''
    END + ';' AS IndexStatement
FROM sys.indexes i
WHERE i.is_primary_key = 0 
    AND i.is_unique_constraint = 0 
    AND i.type > 0
    AND OBJECT_SCHEMA_NAME(i.object_id) != 'sys'
"@

foreach ($idx in $indexScript) {
    if ($idx.IndexStatement) {
        $schemaScript += $idx.IndexStatement + "`n"
    }
}

# Save schema script
$schemaScript | Out-File -FilePath $schemaFile -Encoding UTF8
Write-Host "Schema exported to: $schemaFile" -ForegroundColor Green

# Step 2: Export data
Write-Host "`n[2/4] Exporting all data..." -ForegroundColor Green

# Use the existing export script
& ".\export-for-docker.ps1" -ServerInstance $ServerInstance -DatabaseName $DatabaseName -OutputFile $dataFile

# Step 3: Copy files to Docker and execute
Write-Host "`n[3/4] Applying schema and data to Docker..." -ForegroundColor Green

# Copy schema file
docker cp $schemaFile "${ContainerName}:/tmp/schema.sql"
# Copy data file  
docker cp $dataFile "${ContainerName}:/tmp/data.sql"

# Apply schema first
Write-Host "Creating schema in Docker..." -ForegroundColor Cyan
docker exec $ContainerName /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P $Password -C -i /tmp/schema.sql

if ($LASTEXITCODE -eq 0) {
    Write-Host "Schema created successfully!" -ForegroundColor Green
    
    # Apply data
    Write-Host "Importing data..." -ForegroundColor Cyan
    docker exec $ContainerName /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P $Password -C -i /tmp/data.sql
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Data imported successfully!" -ForegroundColor Green
    } else {
        Write-Host "Warning: Some data import errors occurred" -ForegroundColor Yellow
    }
} else {
    Write-Host "Error creating schema" -ForegroundColor Red
    exit 1
}

# Step 4: Verify
Write-Host "`n[4/4] Verifying migration..." -ForegroundColor Green
$verifyQuery = @"
USE SteelEstimationDB;
SELECT 
    t.name AS TableName,
    p.rows AS RecordCount
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
WHERE i.index_id <= 1
  AND t.is_ms_shipped = 0
GROUP BY t.name, p.rows
ORDER BY t.name;
"@

docker exec $ContainerName /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P $Password -C -Q "$verifyQuery"

Write-Host "`n=== Migration Complete! ===" -ForegroundColor Green
Write-Host "Your exact database schema and data have been migrated to Docker" -ForegroundColor Cyan

# Clean up
docker exec $ContainerName rm /tmp/schema.sql /tmp/data.sql

Write-Host "`nYou can now run your application with Docker!" -ForegroundColor Yellow
Write-Host "URL: http://localhost:8080" -ForegroundColor Cyan