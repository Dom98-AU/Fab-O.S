# Add Pack Bundle Columns Migration
# This script adds the missing columns for pack bundle functionality

Write-Host "Adding Pack Bundle Columns..." -ForegroundColor Green

# Get the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$migrationFile = Join-Path $scriptDir "SteelEstimation.Infrastructure\Migrations\SQL\AddPackBundleColumns.sql"

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
    Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -InputFile $migrationFile -Verbose -ErrorAction Stop
    
    Write-Host ""
    Write-Host "Pack bundle columns added successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "The pack bundle feature is now ready to use." -ForegroundColor Cyan
}
catch {
    Write-Host "Error running migration: $_" -ForegroundColor Red
    exit 1
}