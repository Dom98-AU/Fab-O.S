Write-Host "Quick Build Test..." -ForegroundColor Cyan
cd SteelEstimation.Web
dotnet build --no-incremental 2>&1 | Select-String "error CS" | Measure-Object | ForEach-Object {
    if ($_.Count -eq 0) {
        Write-Host "Build succeeded! No compilation errors." -ForegroundColor Green
    } else {
        Write-Host "Build failed with $($_.Count) errors." -ForegroundColor Red
    }
}
cd ..