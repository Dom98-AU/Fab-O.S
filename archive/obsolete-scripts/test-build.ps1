Write-Host "Testing Steel Estimation Platform build..." -ForegroundColor Cyan
Write-Host ""

# Change to the web project directory
Set-Location "SteelEstimation.Web"

# Clean the build
Write-Host "Cleaning build..." -ForegroundColor Yellow
dotnet clean --verbosity quiet

# Build the project
Write-Host "Building project..." -ForegroundColor Yellow
$buildResult = dotnet build --no-incremental 2>&1

# Check for errors
$errors = $buildResult | Select-String "error CS" 
$errorCount = ($errors | Measure-Object).Count

if ($errorCount -gt 0) {
    Write-Host ""
    Write-Host "Build failed with $errorCount errors:" -ForegroundColor Red
    Write-Host ""
    
    # Display unique errors
    $uniqueErrors = @{}
    $errors | ForEach-Object {
        $errorLine = $_.Line
        if ($errorLine -match "error (CS\d+):(.*)") {
            $errorCode = $matches[1]
            $errorMsg = $matches[2].Trim()
            $key = "$errorCode - $errorMsg"
            
            if (-not $uniqueErrors.ContainsKey($key)) {
                $uniqueErrors[$key] = 1
            } else {
                $uniqueErrors[$key]++
            }
        }
    }
    
    $uniqueErrors.GetEnumerator() | Sort-Object Key | ForEach-Object {
        Write-Host "$($_.Key) (x$($_.Value))" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Run 'dotnet build' to see full error details." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "Build succeeded!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now run the application with:" -ForegroundColor Cyan
    Write-Host "  cd SteelEstimation.Web" -ForegroundColor White
    Write-Host "  dotnet run" -ForegroundColor White
}

# Return to root directory
Set-Location ..