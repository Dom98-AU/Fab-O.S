# Check ALL tables in Docker SQL Server
Write-Host "=== Checking ALL Docker Database Tables ===" -ForegroundColor Cyan

# First, make sure Docker SQL is running
Write-Host "`nStarting Docker SQL container if needed..." -ForegroundColor Yellow
docker-compose up -d sql-server 2>$null
Start-Sleep -Seconds 10

# Get total table count
Write-Host "`nCounting tables in Docker SQL..." -ForegroundColor Yellow
$tableCount = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Password123' -C -d SteelEstimationDB -Q "SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0" -h -1

Write-Host "Total tables in Docker: $($tableCount.Trim())" -ForegroundColor Cyan

# Get all table names
Write-Host "`nListing ALL tables in Docker SQL:" -ForegroundColor Yellow
$allTables = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Password123' -C -d SteelEstimationDB -Q "SELECT name FROM sys.tables WHERE is_ms_shipped = 0 ORDER BY name" -h -1

$tableList = $allTables -split "`n" | Where-Object { $_.Trim() -ne "" } | ForEach-Object { $_.Trim() }

$counter = 1
foreach ($table in $tableList) {
    if ($table) {
        # Get row count
        $rowCount = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Password123' -C -d SteelEstimationDB -Q "SELECT COUNT(*) FROM [$table]" -h -1 2>$null
        
        if ($rowCount) {
            Write-Host "  $counter. $table - $($rowCount.Trim()) rows" -ForegroundColor Gray
        } else {
            Write-Host "  $counter. $table" -ForegroundColor Gray
        }
        $counter++
    }
}

Write-Host "`nCOMPARISON:" -ForegroundColor Cyan
Write-Host "Docker SQL: $($tableCount.Trim()) tables" -ForegroundColor Green
Write-Host "Azure SQL: 8 tables (only core tables migrated so far)" -ForegroundColor Yellow

Write-Host "`nMISSING TABLES need to be migrated!" -ForegroundColor Red
Write-Host "Would you like me to create a script to migrate ALL tables? (Including the missing ones)" -ForegroundColor White