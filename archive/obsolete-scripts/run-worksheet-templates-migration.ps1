Write-Host "Running Worksheet Templates Migration..." -ForegroundColor Cyan
Write-Host ""

Push-Location "SteelEstimation.Infrastructure\Migrations"

try {
    Write-Host "Executing AddWorksheetTemplates.sql..." -ForegroundColor Yellow
    
    # Execute the migration
    sqlcmd -S localhost -d SteelEstimationDb -E -i AddWorksheetTemplates.sql
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Migration completed successfully!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "Error: Migration failed!" -ForegroundColor Red
    }
} catch {
    Write-Host "Error executing migration: $_" -ForegroundColor Red
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")