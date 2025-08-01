# Run Product Licensing Migration for Fab.OS
# This script applies the ProductLicensing migration to enable module-based architecture

param(
    [string]$Environment = "Development"
)

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "======================================" -ForegroundColor Cyan
Write-Host " Fab.OS Product Licensing Migration" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Load environment-specific configuration
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path $scriptPath "SteelEstimation.Web\appsettings.$Environment.json"

# If environment-specific file doesn't exist, fall back to base appsettings.json
if (-not (Test-Path $envFile)) {
    Write-Host "Environment-specific file not found: $envFile" -ForegroundColor Yellow
    $envFile = Join-Path $scriptPath "SteelEstimation.Web\appsettings.json"
    
    if (-not (Test-Path $envFile)) {
        Write-Host "Configuration file not found: $envFile" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Using base configuration file instead" -ForegroundColor Yellow
}

Write-Host "Loading configuration from: $envFile" -ForegroundColor Yellow
$config = Get-Content $envFile | ConvertFrom-Json

# Get connection string
$connectionString = $config.ConnectionStrings.DefaultConnection
if (-not $connectionString) {
    Write-Host "Connection string not found in configuration" -ForegroundColor Red
    exit 1
}

# Migration file path
$migrationFile = Join-Path $scriptPath "SQL_Migrations\AddProductLicensing.sql"

if (-not (Test-Path $migrationFile)) {
    Write-Host "Migration file not found: $migrationFile" -ForegroundColor Red
    exit 1
}

Write-Host "Using connection string: " -NoNewline
Write-Host $connectionString.Replace("Password=", "Password=***") -ForegroundColor DarkGray
Write-Host ""

# Check if migration has already been applied
Write-Host "Checking if migration has already been applied..." -ForegroundColor Yellow

$checkQuery = @"
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'ProductLicenses')
    SELECT 'EXISTS'
ELSE
    SELECT 'NOT_EXISTS'
"@

try {
    $result = Invoke-Sqlcmd -ConnectionString $connectionString -Query $checkQuery -ErrorAction Stop
    
    if ($result[0] -eq 'EXISTS') {
        Write-Host "Product licensing tables already exist." -ForegroundColor Green
        
        # Check if we have product licenses
        $licenseCheck = @"
SELECT COUNT(*) as Count FROM ProductLicenses
"@
        $licenseCount = Invoke-Sqlcmd -ConnectionString $connectionString -Query $licenseCheck -ErrorAction Stop
        
        Write-Host "Found $($licenseCount.Count) product licenses in database" -ForegroundColor Cyan
        
        if ($licenseCount.Count -gt 0) {
            Write-Host "Migration appears to have been run successfully already." -ForegroundColor Green
            
            # Show existing licenses
            $showLicenses = @"
SELECT 
    pl.ProductName,
    c.Name as CompanyName,
    pl.LicenseType,
    pl.MaxConcurrentUsers,
    pl.IsActive,
    CONVERT(varchar, pl.ValidUntil, 101) as ValidUntil
FROM ProductLicenses pl
INNER JOIN Companies c ON pl.CompanyId = c.Id
ORDER BY pl.ProductName, c.Name
"@
            Write-Host ""
            Write-Host "Existing Product Licenses:" -ForegroundColor Yellow
            Invoke-Sqlcmd -ConnectionString $connectionString -Query $showLicenses | Format-Table -AutoSize
            
            exit 0
        }
    }
    
    # Run migration
    Write-Host "Running product licensing migration..." -ForegroundColor Yellow
    Write-Host "Migration file: $migrationFile" -ForegroundColor DarkGray
    
    $migrationContent = Get-Content $migrationFile -Raw
    Invoke-Sqlcmd -ConnectionString $connectionString -Query $migrationContent -ErrorAction Stop
    
    Write-Host "Migration completed successfully!" -ForegroundColor Green
    
    # Verify migration
    Write-Host ""
    Write-Host "Verifying migration results..." -ForegroundColor Yellow
    
    $verifyQuery = @"
SELECT 
    'Product Licenses' as [Table],
    COUNT(*) as [Count]
FROM ProductLicenses
UNION ALL
SELECT 
    'Product Roles' as [Table],
    COUNT(*) as [Count]
FROM ProductRoles
UNION ALL
SELECT 
    'User Product Access' as [Table],
    COUNT(*) as [Count]
FROM UserProductAccess
"@
    
    Invoke-Sqlcmd -ConnectionString $connectionString -Query $verifyQuery | Format-Table -AutoSize
    
    # Show created licenses
    $showNewLicenses = @"
SELECT TOP 10
    pl.ProductName,
    c.Name as CompanyName,
    pl.LicenseType,
    pl.MaxConcurrentUsers,
    CONVERT(varchar, pl.ValidUntil, 101) as ValidUntil
FROM ProductLicenses pl
INNER JOIN Companies c ON pl.CompanyId = c.Id
ORDER BY pl.Id DESC
"@
    Write-Host ""
    Write-Host "Sample of created licenses:" -ForegroundColor Yellow
    Invoke-Sqlcmd -ConnectionString $connectionString -Query $showNewLicenses | Format-Table -AutoSize
    
    Write-Host ""
    Write-Host "======================================" -ForegroundColor Green
    Write-Host " Migration completed successfully!" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Restart the application to load new configuration" -ForegroundColor White
    Write-Host "2. Users will need to log out and back in to get product claims" -ForegroundColor White
    Write-Host "3. The module switcher will appear in the UI" -ForegroundColor White
}
catch {
    Write-Host "Error running migration: $_" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}