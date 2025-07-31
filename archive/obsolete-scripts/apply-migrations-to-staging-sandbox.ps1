# PowerShell script to apply EF migrations to the STAGING SANDBOX database
# Target: sqldb-steel-estimation-sandbox
# App Service: app-steel-estimation-prod/staging

param(
    [Parameter(Mandatory=$false)]
    [switch]$UseLocalConnection,
    
    [Parameter(Mandatory=$false)]
    [switch]$GenerateScriptOnly,
    
    [Parameter(Mandatory=$false)]
    [string]$SqlUsername = "sqladmin",
    
    [Parameter(Mandatory=$false)]
    [SecureString]$SqlPassword
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "EF Migrations for Staging Sandbox" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Target Database: sqldb-steel-estimation-sandbox" -ForegroundColor Yellow
Write-Host "Target Server: nwiapps.database.windows.net" -ForegroundColor Yellow
Write-Host "App Service: app-steel-estimation-prod/staging" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

# Ensure we're in the correct directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

# Set environment to staging
$env:ASPNETCORE_ENVIRONMENT = "Staging"
Write-Host "`nEnvironment set to: Staging" -ForegroundColor Cyan

# Option 1: Generate SQL script only (for manual execution)
if ($GenerateScriptOnly) {
    Write-Host "`nGenerating SQL migration script..." -ForegroundColor Yellow
    
    dotnet ef migrations script `
        --project SteelEstimation.Infrastructure `
        --startup-project SteelEstimation.Web `
        --context ApplicationDbContext `
        --output staging-sandbox-migrations.sql `
        --idempotent
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nSQL script generated successfully!" -ForegroundColor Green
        Write-Host "File: staging-sandbox-migrations.sql" -ForegroundColor Cyan
        Write-Host "`nYou can now:" -ForegroundColor Yellow
        Write-Host "1. Open Azure Portal" -ForegroundColor White
        Write-Host "2. Navigate to sqldb-steel-estimation-sandbox" -ForegroundColor White
        Write-Host "3. Use Query Editor to run the script" -ForegroundColor White
        Write-Host "4. Or use SQL Server Management Studio" -ForegroundColor White
    } else {
        Write-Host "`nError generating SQL script!" -ForegroundColor Red
    }
    exit
}

# Option 2: Apply migrations directly
Write-Host "`nChecking for pending migrations..." -ForegroundColor Yellow

# List all migrations
$migrations = dotnet ef migrations list `
    --project SteelEstimation.Infrastructure `
    --startup-project SteelEstimation.Web `
    --context ApplicationDbContext

Write-Host "`nMigrations status:" -ForegroundColor Cyan
$migrations | ForEach-Object { 
    if ($_ -match "(pending)") {
        Write-Host "  $_ " -ForegroundColor Yellow
    } else {
        Write-Host "  $_ " -ForegroundColor Green
    }
}

# Check if there are pending migrations
$pendingMigrations = $migrations | Select-String "(pending)"

if (-not $pendingMigrations) {
    Write-Host "`nNo pending migrations. Database is up to date!" -ForegroundColor Green
    exit
}

Write-Host "`nPending migrations found. Proceeding with update..." -ForegroundColor Yellow

# Build connection string
if ($UseLocalConnection) {
    # For local development/testing against staging database
    if (-not $SqlPassword) {
        $SqlPassword = Read-Host "Enter SQL Password for $SqlUsername" -AsSecureString
    }
    $PlainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SqlPassword))
    
    $connectionString = "Server=nwiapps.database.windows.net;Database=sqldb-steel-estimation-sandbox;User Id=$SqlUsername;Password=$PlainPassword;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    
    Write-Host "`nUsing SQL Authentication for local connection" -ForegroundColor Yellow
    Write-Host "This allows you to run migrations from your local machine" -ForegroundColor Cyan
    
    # Apply migrations with explicit connection string
    dotnet ef database update `
        --project SteelEstimation.Infrastructure `
        --startup-project SteelEstimation.Web `
        --context ApplicationDbContext `
        --connection $connectionString
        
} else {
    Write-Host "`nUsing Managed Identity from App Service" -ForegroundColor Yellow
    Write-Host "Note: This only works when running from the deployed app service" -ForegroundColor Cyan
    
    # Confirm this is what the user wants
    $confirm = Read-Host "`nThis will use the connection string from appsettings.Staging.json. Continue? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "Cancelled. Use -UseLocalConnection to run from your machine." -ForegroundColor Yellow
        exit
    }
    
    # Apply migrations using configuration
    dotnet ef database update `
        --project SteelEstimation.Infrastructure `
        --startup-project SteelEstimation.Web `
        --context ApplicationDbContext
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Migrations applied successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Database: sqldb-steel-estimation-sandbox" -ForegroundColor Cyan
    Write-Host "All tables and seed data have been created." -ForegroundColor Green
    
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Test database connection at: https://app-steel-estimation-prod-staging.azurewebsites.net/dbtest" -ForegroundColor White
    Write-Host "2. Test authentication at: https://app-steel-estimation-prod-staging.azurewebsites.net/authtest" -ForegroundColor White
    Write-Host "3. Login with: admin@steelestimation.com / Admin@123" -ForegroundColor White
} else {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Error applying migrations!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Cyan
    
    Write-Host "`nTroubleshooting options:" -ForegroundColor Yellow
    Write-Host "1. Generate SQL script only:" -ForegroundColor White
    Write-Host "   .\apply-migrations-to-staging-sandbox.ps1 -GenerateScriptOnly" -ForegroundColor Cyan
    Write-Host "`n2. Use SQL Authentication from local machine:" -ForegroundColor White
    Write-Host "   .\apply-migrations-to-staging-sandbox.ps1 -UseLocalConnection" -ForegroundColor Cyan
    Write-Host "`n3. Check if Managed Identity has proper permissions:" -ForegroundColor White
    Write-Host "   - app-steel-estimation-prod/slots/staging needs db_ddladmin role" -ForegroundColor Cyan
    Write-Host "`n4. Run the grant script manually in Azure Portal:" -ForegroundColor White
    Write-Host "   - Use grant-staging-access.sql" -ForegroundColor Cyan
}

Write-Host "`nPress any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")