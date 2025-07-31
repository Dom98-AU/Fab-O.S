# Complete Database Migration Script - Docker to Azure SQL
Write-Host "=== Steel Estimation Database Migration ===" -ForegroundColor Cyan
Write-Host "This script will migrate all 35 tables from Docker to Azure SQL" -ForegroundColor Yellow

# Step 1: Download SqlPackage if needed
Write-Host "`nStep 1: Checking for SqlPackage..." -ForegroundColor Green

$sqlPackagePath = ".\sqlpackage\SqlPackage.exe"
if (-not (Test-Path $sqlPackagePath)) {
    Write-Host "Downloading SqlPackage..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2196334" -OutFile "sqlpackage.zip"
    
    Write-Host "Extracting SqlPackage..." -ForegroundColor Yellow
    Expand-Archive -Path "sqlpackage.zip" -DestinationPath "sqlpackage" -Force
    Remove-Item "sqlpackage.zip"
}

Write-Host "SqlPackage ready!" -ForegroundColor Green

# Step 2: Export from Docker
Write-Host "`nStep 2: Exporting database from Docker SQL Server..." -ForegroundColor Green
Write-Host "This will export all 35 tables with data" -ForegroundColor Gray

$exportArgs = @(
    "/Action:Export",
    "/SourceServerName:localhost,1433",
    "/SourceDatabaseName:SteelEstimationDB",
    "/SourceUser:sa",
    "/SourcePassword:YourStrong@Password123",
    "/SourceTrustServerCertificate:True",
    "/TargetFile:backups\SteelEstimation.bacpac"
)

& $sqlPackagePath $exportArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "Export completed successfully!" -ForegroundColor Green
} else {
    Write-Host "Export failed. Check the error messages above." -ForegroundColor Red
    exit 1
}

# Step 3: Import to Azure SQL
Write-Host "`nStep 3: Importing to Azure SQL Database..." -ForegroundColor Green
Write-Host "Target: sqldb-steel-estimation-sandbox on nwiapps.database.windows.net" -ForegroundColor Gray

$importArgs = @(
    "/Action:Import",
    "/TargetServerName:nwiapps.database.windows.net",
    "/TargetDatabaseName:sqldb-steel-estimation-sandbox",
    "/TargetUser:admin@nwi@nwiapps",
    "/TargetPassword:Natweigh88",
    "/SourceFile:backups\SteelEstimation.bacpac"
)

& $sqlPackagePath $importArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nImport completed successfully!" -ForegroundColor Green
    Write-Host "All 35 tables and data have been migrated to Azure SQL!" -ForegroundColor Green
} else {
    Write-Host "Import failed. Check the error messages above." -ForegroundColor Red
    exit 1
}

# Step 4: Summary
Write-Host "`n=== Migration Complete ===" -ForegroundColor Cyan
Write-Host "Exported from Docker SQL Server" -ForegroundColor Green
Write-Host "Imported to Azure SQL Database" -ForegroundColor Green
Write-Host "All 35 tables migrated with data" -ForegroundColor Green
Write-Host "`nYour Azure SQL database is ready to use!" -ForegroundColor Yellow
Write-Host "Connection: nwiapps.database.windows.net / sqldb-steel-estimation-sandbox" -ForegroundColor Gray
Write-Host "Login: admin@nwi@nwiapps" -ForegroundColor Gray