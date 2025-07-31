# Fix Pack Bundle Foreign Key
# This script fixes the foreign key constraint issue

Write-Host "Fixing Pack Bundle Foreign Key..." -ForegroundColor Green

# Get the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$migrationFile = Join-Path $scriptDir "SteelEstimation.Infrastructure\Migrations\SQL\AddPackBundles_FK_Fix.sql"

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
    Write-Host "Foreign key constraint fixed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "The pack bundle feature is now ready to use." -ForegroundColor Cyan
}
catch {
    Write-Host "Error running migration: $_" -ForegroundColor Red
    exit 1
}