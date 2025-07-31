cd SteelEstimation.Web
$result = dotnet build 2>&1 | Out-String
if ($LASTEXITCODE -eq 0) {
    Write-Host "BUILD SUCCEEDED!" -ForegroundColor Green -BackgroundColor DarkGreen
    Write-Host "The file is now compiling correctly!" -ForegroundColor Green
} else {
    Write-Host "Build still failing" -ForegroundColor Red
    $errorCount = ([regex]::Matches($result, " error ")).Count
    Write-Host "Error count: $errorCount" -ForegroundColor Yellow
}
cd ..