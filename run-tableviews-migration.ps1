Write-Host "Running TableViews migration..." -ForegroundColor Green
Invoke-Sqlcmd -ServerInstance localhost -Database SteelEstimationDb_CloudDev -InputFile "Migrations\AddTableViews.sql"
Write-Host ""
Write-Host "Migration completed!" -ForegroundColor Green
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")