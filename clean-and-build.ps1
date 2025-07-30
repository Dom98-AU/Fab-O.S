# Clean and Build Solution Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Clean and Build Steel Estimation Solution" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Clean all projects
Write-Host "Cleaning solution..." -ForegroundColor Yellow
dotnet clean

# Remove obj and bin directories
Write-Host "Removing obj and bin directories..." -ForegroundColor Yellow
Get-ChildItem -Path . -Include bin,obj -Recurse -Directory | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# Restore NuGet packages
Write-Host "Restoring NuGet packages..." -ForegroundColor Yellow
dotnet restore

# Build Core project first
Write-Host "Building Core project..." -ForegroundColor Yellow
dotnet build SteelEstimation.Core/SteelEstimation.Core.csproj --configuration Debug

if ($LASTEXITCODE -ne 0) {
    Write-Host "Core project build failed!" -ForegroundColor Red
    exit 1
}

# Build Infrastructure project
Write-Host "Building Infrastructure project..." -ForegroundColor Yellow
dotnet build SteelEstimation.Infrastructure/SteelEstimation.Infrastructure.csproj --configuration Debug

if ($LASTEXITCODE -ne 0) {
    Write-Host "Infrastructure project build failed!" -ForegroundColor Red
    exit 1
}

# Build Web project
Write-Host "Building Web project..." -ForegroundColor Yellow
dotnet build SteelEstimation.Web/SteelEstimation.Web.csproj --configuration Debug

if ($LASTEXITCODE -eq 0) {
    Write-Host "" 
    Write-Host "✓ Build completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Run the application: .\run-local.ps1" -ForegroundColor White
    Write-Host "2. Login as admin@steelestimation.com" -ForegroundColor White
    Write-Host "3. Navigate to Admin > Material Settings" -ForegroundColor White
} else {
    Write-Host "Web project build failed!" -ForegroundColor Red
    exit 1
}