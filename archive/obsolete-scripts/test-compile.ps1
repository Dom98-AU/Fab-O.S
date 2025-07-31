Write-Host "Testing compilation..." -ForegroundColor Cyan
cd SteelEstimation.Web
$output = dotnet build --no-restore 2>&1 | Out-String
$errors = $output | Select-String -Pattern "error|Error|CS|RZ" 

if ($errors) {
    Write-Host "Compilation FAILED - Showing first 20 errors:" -ForegroundColor Red
    $errors | Select -First 20 | ForEach-Object { Write-Host $_ }
} else {
    Write-Host "Compilation SUCCESSFUL!" -ForegroundColor Green
}