# Run Database Migrations
# This script applies SQL migrations to the Azure SQL Database

$ErrorActionPreference = "Stop"

Write-Host "Running Database Migration..." -ForegroundColor Green

# Azure SQL connection details
$serverName = "nwiapps.database.windows.net"
$databaseName = "sqldb-steel-estimation-sandbox"
$username = "admin@nwi@nwiapps"
$password = "Natweigh88"

# Function to run a SQL migration file
function Run-SqlMigration {
    param(
        [string]$MigrationFile,
        [string]$Description
    )
    
    if (Test-Path $MigrationFile) {
        Write-Host "Applying $Description..." -ForegroundColor Yellow
        try {
            # Read the migration SQL
            $migrationSql = Get-Content $MigrationFile -Raw
            
            # Execute using sqlcmd (more reliable for Azure SQL)
            $result = sqlcmd -S $serverName -d $databaseName -U $username -P $password -i $MigrationFile -I 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] $Description completed successfully!" -ForegroundColor Green
                return $true
            } else {
                Write-Host "[FAIL] $Description failed: $result" -ForegroundColor Red
                return $false
            }
        }
        catch {
            Write-Host "[ERROR] Error applying $Description : $_" -ForegroundColor Red
            return $false
        }
    }
    else {
        Write-Host "[WARNING] Migration file not found: $MigrationFile" -ForegroundColor Yellow
        return $false
    }
}

# Check for specific migration file passed as parameter
if ($args.Count -gt 0) {
    $specificMigration = $args[0]
    if (Test-Path $specificMigration) {
        Run-SqlMigration -MigrationFile $specificMigration -Description "Custom migration"
    }
    else {
        Write-Error "Migration file not found: $specificMigration"
        exit 1
    }
}
else {
    # Run all pending migrations in order
    Write-Host "Checking for pending migrations..." -ForegroundColor Cyan
    
    $migrations = @(
        @{
            File = "SteelEstimation.Infrastructure\Migrations\AddTimeTrackingAndEfficiency.sql"
            Description = "Time Tracking and Efficiency"
        },
        @{
            File = "SteelEstimation.Infrastructure\Migrations\AddEfficiencyRates.sql"
            Description = "Efficiency Rates"
        },
        @{
            File = "SteelEstimation.Infrastructure\Migrations\SQL\AddPackBundles.sql"
            Description = "Pack Bundles"
        },
        @{
            File = "SQL_Migrations\AddProductLicensing.sql"
            Description = "Product Licensing (Fab.OS)"
        },
        @{
            File = "SQL_Migrations\AddMultipleAuthProviders.sql"
            Description = "Multiple Authentication Providers"
        }
    )
    
    $successCount = 0
    $failCount = 0
    
    foreach ($migration in $migrations) {
        $migrationPath = Join-Path $PSScriptRoot $migration.File
        if (Run-SqlMigration -MigrationFile $migrationPath -Description $migration.Description) {
            $successCount++
        }
        else {
            $failCount++
        }
    }
    
    Write-Host ""
    Write-Host "Migration Summary:" -ForegroundColor Cyan
    Write-Host "  Successful: $successCount" -ForegroundColor Green
    Write-Host "  Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Gray" })
    
    if ($failCount -eq 0) {
        Write-Host ""
        Write-Host "All migrations completed successfully!" -ForegroundColor Green
        Write-Host "You can now restart the application." -ForegroundColor Yellow
    }
    else {
        Write-Host ""
        Write-Host "Some migrations failed. Please check the errors above." -ForegroundColor Red
        exit 1
    }
}