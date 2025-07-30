Write-Host "Running final build check..." -ForegroundColor Cyan
cd SteelEstimation.Web

$output = dotnet build 2>&1 | Out-String

if ($output -match "Build succeeded") {
    Write-Host "`n*** BUILD SUCCEEDED! ***" -ForegroundColor Green -BackgroundColor DarkGreen
    Write-Host "The file is now compiling correctly!" -ForegroundColor Green
} else {
    $errorCount = ([regex]::Matches($output, " error ")).Count
    Write-Host "`nBuild failed with $errorCount errors" -ForegroundColor Red
    
    # Show first few errors
    $errors = $output -split "`n" | Where-Object { $_ -match "error " } | Select-Object -First 5
    foreach ($err in $errors) {
        Write-Host $err -ForegroundColor Yellow
    }
}

cd ..