# Script to run the EfficiencyRates migration
# This adds support for configurable efficiency rates

Write-Host "Running EfficiencyRates migration..." -ForegroundColor Green

# Get the SQL Server instance
$serverInstance = "localhost"

# Define the database name
$databaseName = "SteelEstimationDB"

# Path to migration script
$scriptPath = ".\SteelEstimation.Infrastructure\Migrations\AddEfficiencyRates.sql"

# Check if script exists
if (!(Test-Path $scriptPath)) {
    Write-Host "Error: Migration script not found at $scriptPath" -ForegroundColor Red
    exit 1
}

try {
    # Run the migration
    Write-Host "Executing migration script..." -ForegroundColor Yellow
    Invoke-Sqlcmd -ServerInstance $serverInstance -Database $databaseName -InputFile $scriptPath -ErrorAction Stop
    
    Write-Host "Migration completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "The following changes have been applied:" -ForegroundColor Cyan
    Write-Host "- Created EfficiencyRates table" -ForegroundColor White
    Write-Host "- Added EfficiencyRateId column to Packages table" -ForegroundColor White
    Write-Host "- Created default efficiency rates for all companies" -ForegroundColor White
    Write-Host ""
    Write-Host "You can now:" -ForegroundColor Yellow
    Write-Host "1. Configure efficiency rates in Admin > Worksheet Configuration > Efficiency Rates" -ForegroundColor White
    Write-Host "2. Use configurable efficiency rates in the estimation dashboard" -ForegroundColor White
    Write-Host "3. View detailed welding time analytics in the dashboard" -ForegroundColor White
    
} catch {
    Write-Host "Error running migration: $_" -ForegroundColor Red
    exit 1
}