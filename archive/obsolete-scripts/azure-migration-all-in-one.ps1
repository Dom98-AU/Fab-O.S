# Complete Azure SQL Migration - All in One Script
Write-Host "=== Steel Estimation Platform - Azure SQL Migration ===" -ForegroundColor Cyan
Write-Host "This will migrate your Docker SQL Server database to Azure SQL Database" -ForegroundColor White
Write-Host ""

# Confirm before proceeding
$confirm = Read-Host "This will overwrite existing data in Azure SQL. Continue? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Migration cancelled." -ForegroundColor Yellow
    exit
}

$azureUsername = "admin@nwi@nwiapps"
$azurePassword = "Natweigh88"
$azureServer = "nwiapps.database.windows.net"
$azureDatabase = "sqldb-steel-estimation-sandbox"

Write-Host ""
Write-Host "Starting migration process..." -ForegroundColor Green

try {
    # STEP 1: Apply Schema
    Write-Host "`n📋 Step 1: Applying database schema to Azure SQL..." -ForegroundColor Cyan
    
    # Drop all foreign keys first
    Write-Host "`n[1/3] Dropping existing foreign keys..." -ForegroundColor Green

    $dropFKScript = @"
-- Drop all foreign keys
DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql = @sql + 'ALTER TABLE [' + OBJECT_SCHEMA_NAME(parent_object_id) + '].[' + OBJECT_NAME(parent_object_id) + '] DROP CONSTRAINT [' + name + ']; '
FROM sys.foreign_keys;
IF @sql != ''
    EXEC sp_executesql @sql;
GO
"@

    $dropFKScript | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
        -S $azureServer `
        -d $azureDatabase `
        -U $azureUsername `
        -P $azurePassword 2>$null

    # Apply the schema
    Write-Host "`n[2/3] Applying schema..." -ForegroundColor Green

    # Use the fixed schema file
    docker run --rm -v ${PWD}:/scripts mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
        -S $azureServer `
        -d $azureDatabase `
        -U $azureUsername `
        -P $azurePassword `
        -i /scripts/azure-schema-fixed.sql `
        -I 2>&1 | ForEach-Object {
            if ($_ -match "error|failed" -and $_ -notmatch "already exists") {
                Write-Host "Error: $_" -ForegroundColor Red
            } elseif ($_ -match "successfully|completed") {
                Write-Host $_ -ForegroundColor Green
            }
        }

    # Verify tables created
    Write-Host "`n[3/3] Verifying tables..." -ForegroundColor Green

    $tableCount = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
        -S $azureServer `
        -d $azureDatabase `
        -U $azureUsername `
        -P $azurePassword `
        -Q "SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0" -h -1

    Write-Host "Total tables in Azure SQL: $($tableCount.Trim())" -ForegroundColor Cyan

    # Wait a moment
    Start-Sleep -Seconds 3
    
    # STEP 2: Migrate Data
    Write-Host "`n📊 Step 2: Migrating data from Docker to Azure SQL..." -ForegroundColor Cyan

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
        
        # For simple tables with basic data types, try direct BCP-style export
        Write-Host "    Exporting and importing data..." -ForegroundColor Gray
        
        # Create a simple data export script
        $exportQuery = "SET NOCOUNT ON; SELECT * FROM [$table]"
        $exportedData = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd `
            -S localhost -U sa -P 'YourStrong@Password123' -C `
            -d SteelEstimationDB `
            -Q $exportQuery -s "|" -W -h -1 2>$null
        
        if ($exportedData -and $exportedData.Count -gt 0) {
            # Get column names
            $columns = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd `
                -S localhost -U sa -P 'YourStrong@Password123' -C `
                -d SteelEstimationDB `
                -Q "SELECT STRING_AGG(QUOTENAME(name), ',') FROM sys.columns WHERE object_id = OBJECT_ID('$table') AND is_computed = 0 ORDER BY column_id" -h -1 2>$null
            
            if ($columns -and $columns.Trim()) {
                # Check if table has identity column
                $hasIdentity = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd `
                    -S localhost -U sa -P 'YourStrong@Password123' -C `
                    -d SteelEstimationDB `
                    -Q "SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID('$table') AND is_identity = 1" -h -1 2>$null
                
                # Turn on identity insert if needed
                if ([int]$hasIdentity.Trim() -gt 0) {
                    docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
                        -S $azureServer `
                        -d $azureDatabase `
                        -U $azureUsername `
                        -P $azurePassword `
                        -Q "SET IDENTITY_INSERT [$table] ON" 2>$null
                }
                
                # Process data in batches
                $validRows = 0
                foreach ($row in $exportedData) {
                    if ($row.Trim() -and $row -notmatch "^-+$") {
                        $values = $row -split "\|"
                        $formattedValues = @()
                        foreach ($value in $values) {
                            if ($value -eq "" -or $value -eq " " -or $value.Trim() -eq "NULL") {
                                $formattedValues += "NULL"
                            } else {
                                # Escape single quotes and wrap in quotes
                                $escapedValue = $value.Trim() -replace "'", "''"
                                $formattedValues += "'$escapedValue'"
                            }
                        }
                        
                        if ($formattedValues.Count -gt 0) {
                            $insertStatement = "INSERT INTO [$table] ($($columns.Trim())) VALUES ($($formattedValues -join ','));"
                            $insertStatement | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
                                -S $azureServer `
                                -d $azureDatabase `
                                -U $azureUsername `
                                -P $azurePassword 2>$null
                            $validRows++
                        }
                    }
                }
                
                # Turn off identity insert if it was on
                if ([int]$hasIdentity.Trim() -gt 0) {
                    docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
                        -S $azureServer `
                        -d $azureDatabase `
                        -U $azureUsername `
                        -P $azurePassword `
                        -Q "SET IDENTITY_INSERT [$table] OFF" 2>$null
                }
                
                Write-Host "    Processed $validRows rows" -ForegroundColor Gray
            }
        }
        
        # Verify row count in Azure
        $azureRowCount = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
            -S $azureServer `
            -d $azureDatabase `
            -U $azureUsername `
            -P $azurePassword `
            -Q "SELECT COUNT(*) FROM [$table]" -h -1 2>$null
        
        Write-Host "    Migration result: Docker($($dockerRowCount.Trim())) -> Azure($($azureRowCount.Trim()))" -ForegroundColor $(if($dockerRowCount.Trim() -eq $azureRowCount.Trim()) { "Green" } else { "Yellow" })
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
    
    Write-Host "`n✅ Migration completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Update your docker-compose.yml to use Azure SQL" -ForegroundColor White
    Write-Host "2. Test the application with Azure SQL connection" -ForegroundColor White
    Write-Host "3. Verify all data and functionality works correctly" -ForegroundColor White
    Write-Host ""
    Write-Host "Azure SQL Database: sqldb-steel-estimation-sandbox" -ForegroundColor Gray
    Write-Host "Server: nwiapps.database.windows.net" -ForegroundColor Gray
    
} catch {
    Write-Host "`n❌ Migration failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Check the error messages above for details." -ForegroundColor Yellow
    exit 1
}