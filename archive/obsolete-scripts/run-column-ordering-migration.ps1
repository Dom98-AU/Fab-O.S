# Run Column Ordering Migration Script
param(
    [string]$ServerInstance = "localhost",
    [string]$Database = "SteelEstimationDB"
)

Write-Host "Running Column Ordering migration..." -ForegroundColor Green

$scriptPath = Join-Path $PSScriptRoot "SteelEstimation.Infrastructure\Migrations\Scripts\AddColumnOrdering.sql"

if (-not (Test-Path $scriptPath)) {
    Write-Host "Migration script not found at: $scriptPath" -ForegroundColor Red
    exit 1
}

try {
    # Execute the migration script
    Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -InputFile $scriptPath -ErrorAction Stop
    Write-Host "Column Ordering migration completed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Error running migration: $_" -ForegroundColor Red
    exit 1
}