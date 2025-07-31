# Run Pack Bundle Migration Script (Safe Version)
# This script adds pack bundle functionality to the database

Write-Host "Running Pack Bundle Migration (Safe Version)..." -ForegroundColor Green

# Get the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$migrationFile = Join-Path $scriptDir "SteelEstimation.Infrastructure\Migrations\SQL\AddPackBundles_Safe.sql"

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
    $output = Invoke-Sqlcmd -ServerInstance $serverName -Database $databaseName -InputFile $migrationFile -Verbose -ErrorAction Stop
    
    # Display any output
    if ($output) {
        $output | ForEach-Object { Write-Host $_ }
    }
    
    Write-Host ""
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
    Write-Host ""
    Write-Host "Full error details:" -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Stack trace:" -ForegroundColor Yellow
    Write-Host $_.Exception.StackTrace -ForegroundColor Gray
    exit 1
}