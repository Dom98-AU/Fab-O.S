# Run Steel Estimation Platform Locally
Write-Host "Starting Steel Estimation Platform..." -ForegroundColor Green

# Navigate to the Web project
Push-Location "$PSScriptRoot\SteelEstimation.Web"

# Set environment to Development
$env:ASPNETCORE_ENVIRONMENT = "Development"

# Run the application
Write-Host "`nStarting application..." -ForegroundColor Green
Write-Host "Environment: Development" -ForegroundColor Cyan
Write-Host "Database: Azure SQL (sqldb-steel-estimation-sandbox)" -ForegroundColor Cyan
Write-Host "`nThe application will start at:" -ForegroundColor Yellow
Write-Host "  https://localhost:5003" -ForegroundColor Green
Write-Host "  http://localhost:5002" -ForegroundColor Green
Write-Host "`nLogin credentials:" -ForegroundColor Yellow
Write-Host "  Email: admin@steelestimation.com" -ForegroundColor White
Write-Host "  Password: Admin@123" -ForegroundColor White
Write-Host "`nPress Ctrl+C to stop the application" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Cyan

dotnet run

Pop-Location