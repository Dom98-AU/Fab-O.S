Write-Host "Quick compilation test..." -ForegroundColor Cyan
cd SteelEstimation.Web

# Just check for the most critical errors
$result = dotnet build --no-restore 2>&1 | Select-String -Pattern "RZ1006|RZ1025|RZ1034|CS0841" | Select -First 10

if ($result) {
    Write-Host "Critical errors found:" -ForegroundColor Red
    $result | ForEach-Object { Write-Host $_ }
} else {
    Write-Host "No critical Razor structure errors found!" -ForegroundColor Green
}

cd ..