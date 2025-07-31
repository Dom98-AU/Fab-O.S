# Azure Sandbox Database Setup Script for Steel Estimation Platform
# This script creates a separate sandbox database for development/testing

# Variables
$resourceGroupName = "NWIApps"
$sqlServerName = "nwiapps"
$sandboxDatabaseName = "sqldb-steel-estimation-sandbox"
$productionDatabaseName = "sqldb-steel-estimation-prod"

# Login to Azure if not already logged in
$context = Get-AzContext
if (-not $context) {
    Write-Host "Logging into Azure..." -ForegroundColor Yellow
    Connect-AzAccount
}

Write-Host "Creating Sandbox Database..." -ForegroundColor Yellow

try {
    # Check if database already exists
    $existingDb = Get-AzSqlDatabase -ResourceGroupName $resourceGroupName `
                                   -ServerName $sqlServerName `
                                   -DatabaseName $sandboxDatabaseName `
                                   -ErrorAction SilentlyContinue

    if ($existingDb) {
        Write-Host "Sandbox database already exists!" -ForegroundColor Yellow
        $response = Read-Host "Do you want to delete and recreate it? (y/n)"
        if ($response -eq 'y') {
            Write-Host "Removing existing database..." -ForegroundColor Red
            Remove-AzSqlDatabase -ResourceGroupName $resourceGroupName `
                                -ServerName $sqlServerName `
                                -DatabaseName $sandboxDatabaseName `
                                -Force
        } else {
            Write-Host "Using existing database." -ForegroundColor Green
            exit 0
        }
    }

    # Create new sandbox database with Basic tier (cheaper for dev)
    Write-Host "Creating new sandbox database..." -ForegroundColor Yellow
    $database = New-AzSqlDatabase -ResourceGroupName $resourceGroupName `
                                 -ServerName $sqlServerName `
                                 -DatabaseName $sandboxDatabaseName `
                                 -Edition "Basic" `
                                 -ServiceObjectiveName "Basic"

    Write-Host "Sandbox database created successfully!" -ForegroundColor Green

    # Get connection string
    $connectionString = "Server=$sqlServerName.database.windows.net;Database=$sandboxDatabaseName;Authentication=Active Directory Managed Identity;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Sandbox Database Created Successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Database Name: $sandboxDatabaseName" -ForegroundColor White
    Write-Host "Server: $sqlServerName.database.windows.net" -ForegroundColor White
    Write-Host "Edition: Basic (Cost-optimized for development)" -ForegroundColor White
    Write-Host "`nConnection String (Managed Identity):" -ForegroundColor Yellow
    Write-Host $connectionString -ForegroundColor Gray
    Write-Host "`nConnection String (SQL Auth - replace username/password):" -ForegroundColor Yellow
    Write-Host "Server=$sqlServerName.database.windows.net;Database=$sandboxDatabaseName;User Id=YOUR_USERNAME;Password=YOUR_PASSWORD;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor Cyan
    
    # Option to copy schema from production
    $copySchema = Read-Host "`nDo you want to copy the schema from production database? (y/n)"
    if ($copySchema -eq 'y') {
        Write-Host "Note: This will copy schema only, not data." -ForegroundColor Yellow
        Write-Host "Please run the migration scripts or use Entity Framework migrations to set up the schema." -ForegroundColor Yellow
    }

} catch {
    Write-Error "Failed to create sandbox database: $_"
    exit 1
}

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Configure the staging slot to use this database" -ForegroundColor White
Write-Host "2. Run Entity Framework migrations on the sandbox database" -ForegroundColor White
Write-Host "3. Update appsettings.Staging.json with the connection string" -ForegroundColor White