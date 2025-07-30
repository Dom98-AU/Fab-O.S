Write-Host "Checking remaining errors..." -ForegroundColor Cyan
cd SteelEstimation.Web

$output = dotnet build --no-restore 2>&1 | Out-String
$errors = $output -split "`n" | Where-Object { $_ -match "error " }

Write-Host "`nRemaining errors:" -ForegroundColor Yellow
foreach ($err in $errors) {
    Write-Host $err -ForegroundColor Red
}

cd ..