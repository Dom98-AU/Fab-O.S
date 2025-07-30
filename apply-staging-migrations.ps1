# PowerShell script to apply EF migrations to staging database
param(
    [Parameter(Mandatory=$false)]
    [switch]$UseSqlAuth,
    
    [Parameter(Mandatory=$false)]
    [string]$SqlUsername = "sqladmin",
    
    [Parameter(Mandatory=$false)]
    [SecureString]$SqlPassword
)

Write-Host "Applying Entity Framework Migrations to Staging Database..." -ForegroundColor Green

# Ensure we're in the correct directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

# Set environment to staging
$env:ASPNETCORE_ENVIRONMENT = "Staging"
Write-Host "Environment set to: Staging" -ForegroundColor Cyan

# Build connection string based on authentication method
if ($UseSqlAuth) {
    if (-not $SqlPassword) {
        $SqlPassword = Read-Host "Enter SQL Password" -AsSecureString
    }
    $PlainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SqlPassword))
    
    $connectionString = "Server=nwiapps.database.windows.net;Database=sqldb-steel-estimation-sandbox;User Id=$SqlUsername;Password=$PlainPassword;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    Write-Host "Using SQL Authentication" -ForegroundColor Yellow
} else {
    # Use Managed Identity (default from appsettings.Staging.json)
    Write-Host "Using Managed Identity Authentication" -ForegroundColor Yellow
}

# Check if migrations are pending
Write-Host "`nChecking for pending migrations..." -ForegroundColor Yellow
$pendingMigrations = dotnet ef migrations list `
    --project SteelEstimation.Infrastructure `
    --startup-project SteelEstimation.Web `
    --context ApplicationDbContext | Select-String "(pending)"

if ($pendingMigrations) {
    Write-Host "`nPending migrations found:" -ForegroundColor Yellow
    $pendingMigrations | ForEach-Object { Write-Host "  $_" -ForegroundColor Cyan }
    
    # Apply migrations
    Write-Host "`nApplying migrations to staging database..." -ForegroundColor Green
    
    if ($connectionString) {
        # Use explicit connection string for SQL Auth
        dotnet ef database update `
            --project SteelEstimation.Infrastructure `
            --startup-project SteelEstimation.Web `
            --context ApplicationDbContext `
            --connection $connectionString
    } else {
        # Use connection string from configuration
        dotnet ef database update `
            --project SteelEstimation.Infrastructure `
            --startup-project SteelEstimation.Web `
            --context ApplicationDbContext
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nMigrations applied successfully!" -ForegroundColor Green
    } else {
        Write-Host "`nError applying migrations!" -ForegroundColor Red
        Write-Host "If you're getting authentication errors, try using SQL authentication:" -ForegroundColor Yellow
        Write-Host "  .\apply-staging-migrations.ps1 -UseSqlAuth" -ForegroundColor Cyan
    }
} else {
    Write-Host "`nNo pending migrations found. Database is up to date." -ForegroundColor Green
}

# Optional: Generate updated SQL script
$generateScript = Read-Host "`nGenerate SQL script for manual review? (y/n)"
if ($generateScript -eq 'y') {
    Write-Host "`nGenerating SQL script..." -ForegroundColor Yellow
    dotnet ef migrations script `
        --project SteelEstimation.Infrastructure `
        --startup-project SteelEstimation.Web `
        --context ApplicationDbContext `
        --output staging-migration-script.sql `
        --idempotent
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SQL script generated: staging-migration-script.sql" -ForegroundColor Green
    }
}

Write-Host "`nPress any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")