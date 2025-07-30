# Quick check of Azure SQL tables
Write-Host "=== Checking Azure SQL Database State ===" -ForegroundColor Cyan

$azureUsername = "admin@nwi@nwiapps"
$azurePassword = "Natweigh88"
$azureServer = "nwiapps.database.windows.net"
$azureDatabase = "sqldb-steel-estimation-sandbox"

Write-Host "`nTesting connection..." -ForegroundColor Yellow
try {
    $connectionTest = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "SELECT 'Connection OK'" -h -1 -t 10
    Write-Host "✅ Connection successful" -ForegroundColor Green
} catch {
    Write-Host "❌ Connection failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`nChecking existing tables..." -ForegroundColor Yellow
$tableList = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "SELECT name FROM sys.tables WHERE is_ms_shipped = 0 ORDER BY name" -t 10

Write-Host "Current tables:" -ForegroundColor Green
Write-Host $tableList

$tableCount = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0" -h -1 -t 10

Write-Host "`nTotal tables: $($tableCount.Trim())" -ForegroundColor Cyan

# Check specific core tables
$coreTablesCheck = @"
SELECT 
    CASE WHEN EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Companies') THEN 'EXISTS' ELSE 'MISSING' END as Companies,
    CASE WHEN EXISTS(SELECT 1 FROM sys.tables WHERE name = 'AspNetRoles') THEN 'EXISTS' ELSE 'MISSING' END as AspNetRoles,
    CASE WHEN EXISTS(SELECT 1 FROM sys.tables WHERE name = 'AspNetUsers') THEN 'EXISTS' ELSE 'MISSING' END as AspNetUsers,
    CASE WHEN EXISTS(SELECT 1 FROM sys.tables WHERE name = 'AspNetUserRoles') THEN 'EXISTS' ELSE 'MISSING' END as AspNetUserRoles,
    CASE WHEN EXISTS(SELECT 1 FROM sys.tables WHERE name = 'EfficiencyRates') THEN 'EXISTS' ELSE 'MISSING' END as EfficiencyRates,
    CASE WHEN EXISTS(SELECT 1 FROM sys.tables WHERE name = 'Postcodes') THEN 'EXISTS' ELSE 'MISSING' END as Postcodes
"@

Write-Host "`nCore tables status:" -ForegroundColor Yellow
$coreStatus = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q $coreTablesCheck -t 10
Write-Host $coreStatus

Write-Host "`nCheck complete!" -ForegroundColor Cyan