# PowerShell script to generate Entity Framework migrations
Write-Host "Generating Entity Framework Migrations..." -ForegroundColor Green

# Ensure we're in the correct directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

# Add EF Core tools if not installed
Write-Host "Checking for EF Core tools..." -ForegroundColor Yellow
$efInstalled = dotnet tool list -g | Select-String "dotnet-ef"
if (-not $efInstalled) {
    Write-Host "Installing EF Core tools globally..." -ForegroundColor Yellow
    dotnet tool install --global dotnet-ef
}

# Generate the initial migration
Write-Host "`nGenerating InitialCreate migration..." -ForegroundColor Green
dotnet ef migrations add InitialCreate `
    --project SteelEstimation.Infrastructure `
    --startup-project SteelEstimation.Web `
    --output-dir Migrations `
    --context ApplicationDbContext

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nMigration generated successfully!" -ForegroundColor Green
    Write-Host "Migration files created in: SteelEstimation.Infrastructure/Migrations" -ForegroundColor Cyan
    
    # Generate SQL script for manual execution if needed
    Write-Host "`nGenerating SQL script from migration..." -ForegroundColor Yellow
    dotnet ef migrations script `
        --project SteelEstimation.Infrastructure `
        --startup-project SteelEstimation.Web `
        --context ApplicationDbContext `
        --output migration-script.sql `
        --idempotent
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SQL script generated: migration-script.sql" -ForegroundColor Green
        Write-Host "You can run this script manually in Azure SQL if needed." -ForegroundColor Cyan
    }
} else {
    Write-Host "`nError generating migration!" -ForegroundColor Red
    Write-Host "Please ensure all projects build successfully and try again." -ForegroundColor Yellow
}

Write-Host "`nPress any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")