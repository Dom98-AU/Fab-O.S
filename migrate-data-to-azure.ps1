# Migrate data from Docker to Azure SQL
Write-Host "=== Migrating Data to Azure SQL ===" -ForegroundColor Cyan

$azureUsername = "admin@nwi@nwiapps"
$azurePassword = "Natweigh88"
$azureServer = "nwiapps.database.windows.net"
$azureDatabase = "sqldb-steel-estimation-sandbox"

# Define table order for data migration (respecting foreign key dependencies)
$tableOrder = @(
    "Companies",
    "AspNetRoles", 
    "AspNetUsers",
    "AspNetUserRoles",
    "AspNetUserClaims",
    "AspNetUserLogins", 
    "AspNetUserTokens",
    "AspNetRoleClaims",
    "EfficiencyRates",
    "Customers",
    "Postcodes",
    "Projects",
    "Estimations",
    "EstimationTimeLogs",
    "Packages",
    "DeliveryBundles",
    "PackBundles",
    "ProcessingItems",
    "WeldingItems",
    "WeldingItemConnections"
)

Write-Host "`nMigrating data for $($tableOrder.Count) tables..." -ForegroundColor Green

foreach ($table in $tableOrder) {
    Write-Host "`n  Processing table: $table" -ForegroundColor Yellow
    
    # Check if table exists in Docker
    $dockerTableExists = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd `
        -S localhost -U sa -P 'YourStrong@Password123' -C `
        -d SteelEstimationDB `
        -Q "SELECT COUNT(*) FROM sys.tables WHERE name = '$table'" -h -1 2>$null
    
    if (-not $dockerTableExists -or [int]$dockerTableExists.Trim() -eq 0) {
        Write-Host "    Table $table not found in Docker - skipping" -ForegroundColor Gray
        continue
    }
    
    # Get row count from Docker
    $dockerRowCount = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd `
        -S localhost -U sa -P 'YourStrong@Password123' -C `
        -d SteelEstimationDB `
        -Q "SELECT COUNT(*) FROM [$table]" -h -1 2>$null
    
    if (-not $dockerRowCount -or [int]$dockerRowCount.Trim() -eq 0) {
        Write-Host "    No data in $table - skipping" -ForegroundColor Gray
        continue
    }
    
    Write-Host "    Found $($dockerRowCount.Trim()) rows to migrate" -ForegroundColor Gray
    
    # Clear existing data in Azure
    Write-Host "    Clearing existing data in Azure..." -ForegroundColor Gray
    docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
        -S $azureServer `
        -d $azureDatabase `
        -U $azureUsername `
        -P $azurePassword `
        -Q "DELETE FROM [$table]" 2>$null
    
    # Check if table has identity column
    $hasIdentity = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd `
        -S localhost -U sa -P 'YourStrong@Password123' -C `
        -d SteelEstimationDB `
        -Q "SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID('$table') AND is_identity = 1" -h -1 2>$null
    
    # Turn on identity insert if needed
    if ([int]$hasIdentity.Trim() -gt 0) {
        Write-Host "    Enabling identity insert..." -ForegroundColor Gray
        docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
            -S $azureServer `
            -d $azureDatabase `
            -U $azureUsername `
            -P $azurePassword `
            -Q "SET IDENTITY_INSERT [$table] ON" 2>$null
    }
    
    # Export data from Docker using BCP-like approach
    Write-Host "    Exporting data from Docker..." -ForegroundColor Gray
    
    # Get column information
    $columns = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd `
        -S localhost -U sa -P 'YourStrong@Password123' -C `
        -d SteelEstimationDB `
        -Q "SELECT STRING_AGG(QUOTENAME(name), ',') FROM sys.columns WHERE object_id = OBJECT_ID('$table') AND is_computed = 0 ORDER BY column_id" -h -1 2>$null
    
    if (-not $columns -or $columns.Trim() -eq "") {
        Write-Host "    Could not get column information - skipping $table" -ForegroundColor Red
        continue
    }
    
    # Create a simple INSERT script by batching data
    $batchSize = 100
    $offset = 0
    
    do {
        # Get batch of data
        $dataQuery = @"
SET NOCOUNT ON;
WITH NumberedRows AS (
    SELECT *, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as rn 
    FROM [$table]
)
SELECT $($columns.Trim())
FROM NumberedRows 
WHERE rn > $offset AND rn <= $($offset + $batchSize)
"@
        
        $batchData = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd `
            -S localhost -U sa -P 'YourStrong@Password123' -C `
            -d SteelEstimationDB `
            -Q $dataQuery -s "|" -W -h -1 2>$null
        
        if ($batchData -and $batchData.Count -gt 0) {
            # Process each row and create INSERT statements
            $insertStatements = @()
            foreach ($row in $batchData) {
                if ($row.Trim()) {
                    $values = $row -split "\|"
                    $formattedValues = @()
                    foreach ($value in $values) {
                        if ($value -eq "" -or $value -eq " " -or $value -eq "NULL") {
                            $formattedValues += "NULL"
                        } else {
                            # Escape single quotes and wrap in quotes
                            $escapedValue = $value -replace "'", "''"
                            $formattedValues += "'$escapedValue'"
                        }
                    }
                    $insertStatements += "INSERT INTO [$table] ($($columns.Trim())) VALUES ($($formattedValues -join ','));"
                }
            }
            
            if ($insertStatements.Count -gt 0) {
                Write-Host "    Inserting batch of $($insertStatements.Count) rows..." -ForegroundColor Gray
                $insertScript = $insertStatements -join "`n"
                $insertScript | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
                    -S $azureServer `
                    -d $azureDatabase `
                    -U $azureUsername `
                    -P $azurePassword 2>$null
            }
        }
        
        $offset += $batchSize
    } while ($batchData -and $batchData.Count -eq $batchSize)
    
    # Turn off identity insert if it was on
    if ([int]$hasIdentity.Trim() -gt 0) {
        Write-Host "    Disabling identity insert..." -ForegroundColor Gray
        docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
            -S $azureServer `
            -d $azureDatabase `
            -U $azureUsername `
            -P $azurePassword `
            -Q "SET IDENTITY_INSERT [$table] OFF" 2>$null
    }
    
    # Verify row count in Azure
    $azureRowCount = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
        -S $azureServer `
        -d $azureDatabase `
        -U $azureUsername `
        -P $azurePassword `
        -Q "SELECT COUNT(*) FROM [$table]" -h -1 2>$null
    
    Write-Host "    Migration result: Docker($($dockerRowCount.Trim())) -> Azure($($azureRowCount.Trim()))" -ForegroundColor $(if($dockerRowCount.Trim() -eq $azureRowCount.Trim()) { "Green" } else { "Red" })
}

# Final verification
Write-Host "`n=== Migration Summary ===" -ForegroundColor Cyan
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S $azureServer `
    -d $azureDatabase `
    -U $azureUsername `
    -P $azurePassword `
    -Q "SELECT 
        t.name AS TableName, 
        ISNULL(p.rows, 0) AS RowCount
    FROM sys.tables t 
    LEFT JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
    WHERE t.is_ms_shipped = 0
    ORDER BY t.name"

Write-Host "`nData migration complete!" -ForegroundColor Green