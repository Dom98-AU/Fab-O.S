# Run Worksheet Template ID Migration
# This script adds the WorksheetTemplateId column to PackageWorksheets table

$ErrorActionPreference = "Stop"

Write-Host "Running Worksheet Template ID Migration..." -ForegroundColor Green

# Get the connection string
$connectionString = "Server=localhost;Database=SteelEstimationDb;Trusted_Connection=True;TrustServerCertificate=True;"

# Path to migration file
$migrationPath = Join-Path $PSScriptRoot "SteelEstimation.Infrastructure\Migrations\AddWorksheetTemplateIdToPackageWorksheets.sql"

if (-not (Test-Path $migrationPath)) {
    Write-Error "Migration file not found at: $migrationPath"
    exit 1
}

try {
    # Read the migration SQL
    $migrationSql = Get-Content $migrationPath -Raw
    
    # Execute the migration using .NET SqlConnection
    Write-Host "Applying migration to database..." -ForegroundColor Yellow
    
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    $command = $connection.CreateCommand()
    $command.CommandText = $migrationSql
    $command.ExecuteNonQuery()
    
    $connection.Close()
    
    Write-Host "Migration completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Changes applied:" -ForegroundColor Cyan
    Write-Host "- Added WorksheetTemplateId column to PackageWorksheets table" -ForegroundColor White
    Write-Host "- Created foreign key relationship to WorksheetTemplates" -ForegroundColor White
    Write-Host "- Added index for performance optimization" -ForegroundColor White
    Write-Host "- Updated existing worksheets to use default template" -ForegroundColor White
    Write-Host ""
    Write-Host "You can now refresh the application to see the changes." -ForegroundColor Yellow
}
catch {
    Write-Error "Failed to apply migration: $_"
    exit 1
}