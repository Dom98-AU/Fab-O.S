# PowerShell script to run Customer Management migration
# Run this script as Administrator

param(
    [string]$ServerInstance = "localhost",
    [string]$Database = "SteelEstimationDb",
    [switch]$Rollback = $false
)

Write-Host "Steel Estimation Platform - Customer Management Migration" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "This script must be run as Administrator. Exiting..." -ForegroundColor Red
    exit 1
}

# Determine which script to run
if ($Rollback) {
    $scriptFile = "CustomerManagement_Rollback.sql"
    Write-Host "Running ROLLBACK script..." -ForegroundColor Yellow
    Write-Host "WARNING: This will DELETE all customer, contact, and address data!" -ForegroundColor Red
    $confirm = Read-Host "Are you sure you want to continue? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "Rollback cancelled." -ForegroundColor Green
        exit 0
    }
} else {
    $scriptFile = "CustomerManagement_Complete.sql"
    Write-Host "Running migration script..." -ForegroundColor Green
}

$scriptPath = Join-Path $PSScriptRoot $scriptFile

# Check if script file exists
if (-not (Test-Path $scriptPath)) {
    Write-Host "Migration script not found: $scriptPath" -ForegroundColor Red
    exit 1
}

try {
    Write-Host "Connecting to SQL Server..." -ForegroundColor Yellow
    Write-Host "Server: $ServerInstance" -ForegroundColor Gray
    Write-Host "Database: $Database" -ForegroundColor Gray
    
    # Execute the migration script
    Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -InputFile $scriptPath -Verbose
    
    Write-Host "`nMigration completed successfully!" -ForegroundColor Green
    
    if (-not $Rollback) {
        Write-Host "`nNext steps:" -ForegroundColor Cyan
        Write-Host "1. Update existing customers with valid ABNs" -ForegroundColor White
        Write-Host "2. Register for ABR Web Services at https://abr.business.gov.au/Tools/WebServices" -ForegroundColor White
        Write-Host "3. Update appsettings.json with your ABR GUID" -ForegroundColor White
        Write-Host "4. Test the customer management features" -ForegroundColor White
    }
}
catch {
    Write-Host "`nError executing migration:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")