# PowerShell script to run Settings table migration
Write-Host "Running Settings table migration..." -ForegroundColor Cyan

$server = "localhost"
$database = "SteelEstimationDb"
$script = ".\SteelEstimation.Infrastructure\Migrations\AddSettingsTable.sql"

try {
    # Check if SQL script exists
    if (!(Test-Path $script)) {
        Write-Host "Error: Migration script not found at $script" -ForegroundColor Red
        exit 1
    }

    # Run the migration
    Write-Host "Executing migration script..." -ForegroundColor Yellow
    sqlcmd -S $server -d $database -E -i $script
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Settings table migration completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "Error running migration. Exit code: $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}