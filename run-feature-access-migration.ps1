# Run Feature Access Tables Migration
Write-Host "Running Feature Access Tables migration..." -ForegroundColor Green

$scriptPath = ".\SteelEstimation.Infrastructure\Migrations\SQL\AddFeatureAccessTables.sql"

# Run the migration
sqlcmd -S localhost -d SteelEstimationDb -E -i $scriptPath

if ($LASTEXITCODE -eq 0) {
    Write-Host "Feature Access tables created successfully!" -ForegroundColor Green
} else {
    Write-Host "Error running migration. Please check the output above." -ForegroundColor Red
}

Read-Host "Press Enter to continue..."