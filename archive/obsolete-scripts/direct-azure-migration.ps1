# Direct migration from Docker to Azure SQL
Write-Host "=== Direct Docker to Azure SQL Migration ===" -ForegroundColor Cyan

$username = "admin@nwi@nwiapps"
$password = "Natweigh88"

# Step 1: Get all tables from Docker in correct order
Write-Host "`n[1/4] Getting table list from Docker..." -ForegroundColor Green

$tables = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P 'YourStrong@Password123' -C `
    -d SteelEstimationDB `
    -Q "SELECT name FROM sys.tables WHERE is_ms_shipped = 0 ORDER BY create_date" -h -1

$tableList = $tables -split "`n" | Where-Object { $_.Trim() -ne "" } | ForEach-Object { $_.Trim() }

Write-Host "Found $($tableList.Count) tables" -ForegroundColor Gray

# Step 2: For each table, script out CREATE statement and apply to Azure
Write-Host "`n[2/4] Creating tables in Azure SQL..." -ForegroundColor Green

foreach ($table in $tableList) {
    if ($table) {
        Write-Host "  Creating table: $table" -ForegroundColor Gray
        
        # Generate CREATE TABLE script
        $createScript = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd `
            -S localhost -U sa -P 'YourStrong@Password123' -C `
            -d SteelEstimationDB `
            -Q "EXEC sp_helptext '$table'" -h -1 2>$null
        
        if (-not $createScript) {
            # Use alternative method to generate CREATE TABLE
            $columns = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd `
                -S localhost -U sa -P 'YourStrong@Password123' -C `
                -d SteelEstimationDB `
                -Q @"
SELECT 
    '[' + c.name + '] ' + 
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
    CASE WHEN c.is_nullable = 0 THEN ' NOT NULL' ELSE ' NULL' END
FROM sys.columns c
WHERE c.object_id = OBJECT_ID('$table')
ORDER BY c.column_id
"@ -h -1
            
            if ($columns) {
                $columnDefs = ($columns -split "`n" | Where-Object { $_.Trim() -ne "" }) -join ",`n    "
                $createStatement = "IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = '$table')`nBEGIN`n    CREATE TABLE [dbo].[$table] (`n    $columnDefs`n    );`nEND"
                
                # Apply to Azure
                $createStatement | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
                    -S "nwiapps.database.windows.net" `
                    -d "sqldb-steel-estimation-sandbox" `
                    -U $username `
                    -P $password 2>$null
            }
        }
    }
}

# Step 3: Add constraints
Write-Host "`n[3/4] Adding constraints..." -ForegroundColor Green

# Primary Keys
$pks = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P 'YourStrong@Password123' -C `
    -d SteelEstimationDB `
    -Q @"
SELECT 
    'ALTER TABLE [' + t.name + '] ADD CONSTRAINT [' + pk.name + '] PRIMARY KEY (' +
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
"@ -h -1

$pks | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S "nwiapps.database.windows.net" `
    -d "sqldb-steel-estimation-sandbox" `
    -U $username `
    -P $password 2>$null

# Step 4: Copy data
Write-Host "`n[4/4] Copying data..." -ForegroundColor Green

# Use the existing export script
& ".\export-for-docker.ps1" -ServerInstance "localhost" -DatabaseName "SteelEstimationDB" -OutputFile "./direct-data-export.sql" -DockerMode $true

# Import to Azure
docker run --rm -v ${PWD}:/scripts mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S "nwiapps.database.windows.net" `
    -d "sqldb-steel-estimation-sandbox" `
    -U $username `
    -P $password `
    -i /scripts/direct-data-export.sql 2>$null

# Verify
Write-Host "`nVerifying migration..." -ForegroundColor Green
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S "nwiapps.database.windows.net" `
    -d "sqldb-steel-estimation-sandbox" `
    -U $username `
    -P $password `
    -Q "SELECT COUNT(*) as TotalTables FROM sys.tables WHERE is_ms_shipped = 0"

Write-Host "`nMigration complete!" -ForegroundColor Green