# Run Steel Estimation Platform Locally
Write-Host "Starting Steel Estimation Platform..." -ForegroundColor Green

# Navigate to the Web project
Push-Location "$PSScriptRoot\SteelEstimation.Web"

# Check if database exists
Write-Host "Checking database connection..." -ForegroundColor Yellow
$testConnection = @"
SELECT DB_NAME() as DatabaseName
"@

try {
    $result = sqlcmd -S localhost -E -d SteelEstimationDb -Q $testConnection -h -1 2>$null
    if ($result -match "SteelEstimationDb") {
        Write-Host "Database connection successful!" -ForegroundColor Green
    } else {
        throw "Database not found"
    }
} catch {
    Write-Host "Database not found. Running setup script..." -ForegroundColor Yellow
    Pop-Location
    & "$PSScriptRoot\setup-local-db.ps1"
    Push-Location "$PSScriptRoot\SteelEstimation.Web"
}

# Set environment to Development
$env:ASPNETCORE_ENVIRONMENT = "Development"

# Run the application
Write-Host "`nStarting application..." -ForegroundColor Green
Write-Host "Environment: Development" -ForegroundColor Cyan
Write-Host "Database: localhost\SteelEstimationDb" -ForegroundColor Cyan
Write-Host "`nThe application will start at:" -ForegroundColor Yellow
Write-Host "  https://localhost:5001" -ForegroundColor Green
Write-Host "  http://localhost:5000" -ForegroundColor Green
Write-Host "`nPress Ctrl+C to stop the application" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

dotnet run

Pop-Location