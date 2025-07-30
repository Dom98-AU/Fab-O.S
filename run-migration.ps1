# Run Time Tracking and Efficiency Migration
# This script applies the database migration for the new features

$ErrorActionPreference = "Stop"

Write-Host "Running Time Tracking and Efficiency Migration..." -ForegroundColor Green

# Get the connection string from appsettings
$connectionString = "Server=localhost;Database=SteelEstimationDb;Trusted_Connection=True;TrustServerCertificate=True;"

# Path to migration file
$migrationPath = Join-Path $PSScriptRoot "SteelEstimation.Infrastructure\Migrations\AddTimeTrackingAndEfficiency.sql"

if (-not (Test-Path $migrationPath)) {
    Write-Error "Migration file not found at: $migrationPath"
    exit 1
}

try {
    # Read the migration SQL
    $migrationSql = Get-Content $migrationPath -Raw
    
    # Execute the migration
    Write-Host "Applying migration to database..." -ForegroundColor Yellow
    Invoke-Sqlcmd -ServerInstance "localhost" -Database "SteelEstimationDb" -Query $migrationSql -TrustServerCertificate
    
    Write-Host "Migration completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "New features added:" -ForegroundColor Cyan
    Write-Host "- Time tracking with EstimationTimeLogs table" -ForegroundColor White
    Write-Host "- Multiple welding connections with WeldingItemConnections table" -ForegroundColor White
    Write-Host "- Processing efficiency column in Packages table" -ForegroundColor White
    Write-Host ""
    Write-Host "You can now restart the application." -ForegroundColor Yellow
}
catch {
    Write-Error "Failed to apply migration: $_"
    exit 1
}