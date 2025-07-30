# Run Multi-Tenant Migration Script
# This script applies the multi-tenant database changes

param(
    [string]$ServerInstance = "(localdb)\MSSQLLocalDB",
    [string]$Database = "SteelEstimationDb"
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Multi-Tenant Migration Script" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "WARNING: Not running as administrator. Some operations may fail." -ForegroundColor Yellow
    Write-Host ""
}

# Test database connection
Write-Host "Testing database connection..." -ForegroundColor Yellow
try {
    $testQuery = "SELECT 1"
    Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Query $testQuery -ErrorAction Stop | Out-Null
    Write-Host "✓ Database connection successful" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to connect to database" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Navigate to migration directory
$migrationPath = Join-Path $PSScriptRoot "SteelEstimation.Infrastructure\Migrations"
if (-not (Test-Path $migrationPath)) {
    Write-Host "✗ Migration directory not found: $migrationPath" -ForegroundColor Red
    exit 1
}

Push-Location $migrationPath

try {
    # Run the simple migration script
    $migrationFile = "RunMultiTenantMigration_Simple.sql"
    
    if (-not (Test-Path $migrationFile)) {
        Write-Host "✗ Migration file not found: $migrationFile" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "Running multi-tenant migration..." -ForegroundColor Yellow
    Write-Host "Server: $ServerInstance" -ForegroundColor Gray
    Write-Host "Database: $Database" -ForegroundColor Gray
    Write-Host ""
    
    # Execute the migration
    $output = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -InputFile $migrationFile -Verbose 4>&1
    
    # Display output
    foreach ($line in $output) {
        if ($line -is [System.Management.Automation.VerboseRecord]) {
            Write-Host $line.Message -ForegroundColor Gray
        } else {
            Write-Host $line
        }
    }
    
    Write-Host ""
    Write-Host "✓ Migration completed successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Show summary
    Write-Host "Verifying migration results..." -ForegroundColor Yellow
    $summaryQuery = @"
SELECT 
    'Companies' as TableName, COUNT(*) as RecordCount FROM Companies
UNION ALL
SELECT 'Users with Company', COUNT(*) FROM Users WHERE CompanyId IS NOT NULL
UNION ALL
SELECT 'Material Types', COUNT(*) FROM CompanyMaterialTypes
UNION ALL
SELECT 'MBE ID Mappings', COUNT(*) FROM CompanyMbeIdMappings
UNION ALL
SELECT 'Material Patterns', COUNT(*) FROM CompanyMaterialPatterns
"@
    
    $results = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Query $summaryQuery
    
    Write-Host ""
    Write-Host "Migration Summary:" -ForegroundColor Cyan
    Write-Host "-----------------" -ForegroundColor Cyan
    foreach ($row in $results) {
        Write-Host "$($row.TableName): $($row.RecordCount)" -ForegroundColor Green
    }
    
    # Check admin user
    $adminQuery = @"
SELECT u.Username, u.Email, c.Name as CompanyName
FROM Users u
INNER JOIN Companies c ON u.CompanyId = c.Id
WHERE u.Email = 'admin@steelestimation.com'
"@
    
    $adminResult = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $Database -Query $adminQuery
    
    if ($adminResult) {
        Write-Host ""
        Write-Host "Admin User Status:" -ForegroundColor Cyan
        Write-Host "-----------------" -ForegroundColor Cyan
        Write-Host "Username: $($adminResult.Username)" -ForegroundColor Green
        Write-Host "Email: $($adminResult.Email)" -ForegroundColor Green
        Write-Host "Company: $($adminResult.CompanyName)" -ForegroundColor Green
    }
    
} catch {
    Write-Host "✗ Migration failed!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Migration Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run the application using: .\run-local.ps1" -ForegroundColor White
Write-Host "2. Login as admin@steelestimation.com" -ForegroundColor White
Write-Host "3. Navigate to Admin > Material Settings" -ForegroundColor White
Write-Host "4. Configure material types and mappings for your company" -ForegroundColor White
Write-Host ""