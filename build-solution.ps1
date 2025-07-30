# Build Solution Script
Write-Host "Building Steel Estimation Solution..." -ForegroundColor Cyan

# Restore NuGet packages
Write-Host "Restoring NuGet packages..." -ForegroundColor Yellow
dotnet restore

# Build the solution
Write-Host "Building solution..." -ForegroundColor Yellow
dotnet build --configuration Debug

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build completed successfully!" -ForegroundColor Green
} else {
    Write-Host "Build failed with errors." -ForegroundColor Red
    exit 1
}