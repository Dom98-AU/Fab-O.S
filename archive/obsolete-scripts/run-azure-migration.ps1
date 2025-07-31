# Complete Azure SQL Migration - Run All Steps
Write-Host "=== Steel Estimation Platform - Azure SQL Migration ===" -ForegroundColor Cyan
Write-Host "This will migrate your Docker SQL Server database to Azure SQL Database" -ForegroundColor White
Write-Host ""

# Confirm before proceeding
$confirm = Read-Host "This will overwrite existing data in Azure SQL. Continue? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Migration cancelled." -ForegroundColor Yellow
    exit
}

Write-Host ""
Write-Host "Starting migration process..." -ForegroundColor Green

try {
    # Step 1: Apply Schema
    Write-Host "`n📋 Step 1: Applying database schema to Azure SQL..." -ForegroundColor Cyan
    & ".\apply-azure-schema.ps1"
    
    if ($LASTEXITCODE -ne 0) {
        throw "Schema application failed"
    }
    
    # Wait a moment
    Start-Sleep -Seconds 3
    
    # Step 2: Migrate Data  
    Write-Host "`n📊 Step 2: Migrating data from Docker to Azure SQL..." -ForegroundColor Cyan
    & ".\migrate-data-to-azure.ps1"
    
    if ($LASTEXITCODE -ne 0) {
        throw "Data migration failed"
    }
    
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