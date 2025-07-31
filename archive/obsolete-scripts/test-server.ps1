# Test if we can run the server
Write-Host "Testing Steel Estimation Platform startup..." -ForegroundColor Green

# Navigate to Web project
Push-Location "$PSScriptRoot\SteelEstimation.Web"

# Set environment
$env:ASPNETCORE_ENVIRONMENT = "Development"
$env:ASPNETCORE_URLS = "http://localhost:5000"

Write-Host "`nStarting on HTTP only (no HTTPS) at http://localhost:5000" -ForegroundColor Yellow
Write-Host "This should bypass any certificate issues..." -ForegroundColor Cyan

# Run with explicit HTTP only
dotnet run --urls "http://localhost:5000" --no-launch-profile

Pop-Location