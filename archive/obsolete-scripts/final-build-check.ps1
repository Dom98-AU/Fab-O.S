Write-Host "===========================================" -ForegroundColor Cyan
Write-Host " Final Build Check for Steel Estimation" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Change to the web project directory
Set-Location "SteelEstimation.Web"

# Clean and build
Write-Host "Cleaning previous build..." -ForegroundColor Yellow
dotnet clean --verbosity quiet

Write-Host "Building project..." -ForegroundColor Yellow
Write-Host ""

# Capture build output
$buildOutput = dotnet build --no-incremental 2>&1

# Check for errors
$errors = $buildOutput | Select-String "error CS" 
$warnings = $buildOutput | Select-String "warning CS"

$errorCount = ($errors | Measure-Object).Count
$warningCount = ($warnings | Measure-Object).Count

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host " Build Results" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

if ($errorCount -gt 0) {
    Write-Host "Build FAILED with $errorCount error(s)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Errors:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host $_.Line -ForegroundColor Red }
} else {
    Write-Host "✓ Build SUCCEEDED!" -ForegroundColor Green
    Write-Host ""
    
    if ($warningCount -gt 0) {
        Write-Host "⚠ $warningCount warning(s) found" -ForegroundColor Yellow
    } else {
        Write-Host "✓ No warnings" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Run the application: dotnet run" -ForegroundColor White
    Write-Host "2. Navigate to: https://localhost:5001" -ForegroundColor White
    Write-Host "3. Login with: admin@steelestimation.com / Admin@123" -ForegroundColor White
}

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan

# Return to root directory
Set-Location ..