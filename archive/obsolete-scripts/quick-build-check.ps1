cd SteelEstimation.Web
$output = dotnet build 2>&1 | Out-String
if ($LASTEXITCODE -eq 0) {
    Write-Host "`n*** BUILD SUCCEEDED! ***`n" -ForegroundColor Green -BackgroundColor DarkGreen
    Write-Host "The basic structure is now working!" -ForegroundColor Green
    Write-Host "Ready to add back all the features." -ForegroundColor Cyan
    exit 0
} else {
    $errorCount = ([regex]::Matches($output, " error ")).Count
    Write-Host "Build failed with $errorCount errors" -ForegroundColor Red
    exit 1
}