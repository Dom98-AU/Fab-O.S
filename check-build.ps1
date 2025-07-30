Write-Host "Checking build status..." -ForegroundColor Cyan
cd SteelEstimation.Web

$output = dotnet build 2>&1 | Out-String

if ($output -match "Build succeeded") {
    Write-Host "`nBUILD SUCCEEDED!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nBuild failed." -ForegroundColor Red
    
    # Show only unique errors
    $errors = $output -split "`n" | Where-Object { $_ -match "error " } | Select-Object -Unique | Select-Object -First 10
    
    Write-Host "`nUnique errors:" -ForegroundColor Yellow
    foreach ($err in $errors) {
        Write-Host $err -ForegroundColor Gray
    }
    
    exit 1
}