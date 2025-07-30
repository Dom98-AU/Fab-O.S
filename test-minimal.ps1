Write-Host "Testing minimal compilation..." -ForegroundColor Cyan
cd SteelEstimation.Web

$result = dotnet build --no-restore 2>&1

# Check for success
if ($LASTEXITCODE -eq 0) {
    Write-Host "`nBUILD SUCCEEDED!" -ForegroundColor Green
} else {
    Write-Host "`nBuild failed. First 5 errors:" -ForegroundColor Red
    $result | Select-String -Pattern "error " | Select -First 5 | ForEach-Object {
        Write-Host $_ -ForegroundColor Yellow
    }
}

cd ..