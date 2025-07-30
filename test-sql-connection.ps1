# Simple SQL Server connection test
Write-Host "Testing SQL Server connections..." -ForegroundColor Cyan

# Test localhost
Write-Host "`nTesting localhost..." -ForegroundColor Yellow
try {
    Invoke-Sqlcmd -ServerInstance "localhost" -Database "SteelEstimationDb_CloudDev" -Query "SELECT DB_NAME() as DatabaseName" -ErrorAction Stop
    Write-Host "SUCCESS: Can connect to localhost with database SteelEstimationDb_CloudDev" -ForegroundColor Green
    Write-Host "`nUse this command to export:" -ForegroundColor Cyan
    Write-Host '.\export-for-docker.ps1 -ServerInstance "localhost" -DatabaseName "SteelEstimationDb_CloudDev"' -ForegroundColor Yellow
} catch {
    Write-Host "Failed to connect to localhost" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Gray
}

# Test .\SQLEXPRESS
Write-Host "`n`nTesting .\SQLEXPRESS..." -ForegroundColor Yellow
try {
    Invoke-Sqlcmd -ServerInstance ".\SQLEXPRESS" -Database "SteelEstimationDb_CloudDev" -Query "SELECT DB_NAME() as DatabaseName" -ErrorAction Stop
    Write-Host "SUCCESS: Can connect to .\SQLEXPRESS with database SteelEstimationDb_CloudDev" -ForegroundColor Green
    Write-Host "`nUse this command to export:" -ForegroundColor Cyan
    Write-Host '.\export-for-docker.ps1 -ServerInstance ".\SQLEXPRESS" -DatabaseName "SteelEstimationDb_CloudDev"' -ForegroundColor Yellow
} catch {
    Write-Host "Failed to connect to .\SQLEXPRESS" -ForegroundColor Red
}

# Show connection string
Write-Host "`n`nYour appsettings.Development.json connection string:" -ForegroundColor Cyan
Write-Host "Server=localhost;Database=SteelEstimationDb_CloudDev;Trusted_Connection=True" -ForegroundColor Yellow