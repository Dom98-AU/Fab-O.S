Write-Host "Running Worksheet Template Migrations..." -ForegroundColor Cyan
Write-Host ""

Push-Location "SteelEstimation.Infrastructure\Migrations"

try {
    Write-Host "1. Executing AddWorksheetTemplates.sql..." -ForegroundColor Yellow
    sqlcmd -S localhost -d SteelEstimationDb -E -i AddWorksheetTemplates.sql
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Worksheet templates created successfully!" -ForegroundColor Green
    } else {
        Write-Host "   Error: Worksheet templates migration failed!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "2. Executing AddUserWorksheetPreferences.sql..." -ForegroundColor Yellow
    sqlcmd -S localhost -d SteelEstimationDb -E -i AddUserWorksheetPreferences.sql
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   User preferences table created successfully!" -ForegroundColor Green
    } else {
        Write-Host "   Error: User preferences migration failed!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "All migrations completed successfully!" -ForegroundColor Green
} catch {
    Write-Host "Error executing migrations: $_" -ForegroundColor Red
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")