# Run Pack Bundle Migration Script
# This script adds pack bundle functionality to the database

Write-Host "Running Pack Bundle Migration..." -ForegroundColor Green

# Get the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$migrationFile = Join-Path $scriptDir "SteelEstimation.Infrastructure\Migrations\SQL\AddPackBundles.sql"

# Check if migration file exists
if (-not (Test-Path $migrationFile)) {
    Write-Host "Error: Migration file not found at $migrationFile" -ForegroundColor Red
    exit 1
}

# Database connection parameters
$serverName = "localhost"
$databaseName = "SteelEstimationDb_CloudDev"

Write-Host "Connecting to database: $databaseName on server: $serverName" -ForegroundColor Yellow

try {
    # Run the migration
    Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -InputFile $migrationFile -ErrorAction Stop
    
    Write-Host "Pack Bundle migration completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "New features added:" -ForegroundColor Cyan
    Write-Host "- PackBundles table for grouping processing items" -ForegroundColor White
    Write-Host "- Pack bundle fields in ProcessingItems table" -ForegroundColor White
    Write-Host "- Pack bundle parent/child relationship support" -ForegroundColor White
    Write-Host ""
    Write-Host "You can now use pack bundles to group items for handling operations." -ForegroundColor Yellow
}
catch {
    Write-Host "Error running migration: $_" -ForegroundColor Red
    exit 1
}