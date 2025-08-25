#!/usr/bin/env pwsh

Write-Host "Running WorkCenter Dynamic Columns Migration..." -ForegroundColor Green

# Get connection string from appsettings
$settingsPath = "SteelEstimation.Web/appsettings.Development.json"
$settings = Get-Content $settingsPath | ConvertFrom-Json
$connectionString = $settings.ConnectionStrings.DefaultConnection

if (-not $connectionString) {
    Write-Host "Error: Could not find connection string in appsettings.Development.json" -ForegroundColor Red
    exit 1
}

# Migration file
$migrationFile = "SteelEstimation.Infrastructure/Migrations/AddWorkCenterDynamicColumns.sql"

if (-not (Test-Path $migrationFile)) {
    Write-Host "Error: Migration file not found at $migrationFile" -ForegroundColor Red
    exit 1
}

Write-Host "Reading migration script..." -ForegroundColor Yellow
$migrationScript = Get-Content $migrationFile -Raw

# Parse connection string
$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder($connectionString)
$server = $builder.DataSource
$database = $builder.InitialCatalog
$userId = $builder.UserID
$password = $builder.Password

Write-Host "Connecting to database: $database on server: $server" -ForegroundColor Yellow

# Execute migration using sqlcmd
$tempFile = [System.IO.Path]::GetTempFileName() + ".sql"
$migrationScript | Out-File -FilePath $tempFile -Encoding UTF8

try {
    Write-Host "Executing migration..." -ForegroundColor Yellow
    
    # Use sqlcmd to run the migration
    $sqlcmdArgs = @(
        "-S", $server,
        "-d", $database,
        "-U", $userId,
        "-P", $password,
        "-i", $tempFile,
        "-b"
    )
    
    $result = & sqlcmd @sqlcmdArgs 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Migration completed successfully!" -ForegroundColor Green
        Write-Host $result
    } else {
        Write-Host "Migration failed!" -ForegroundColor Red
        Write-Host $result
        exit 1
    }
} finally {
    # Clean up temp file
    if (Test-Path $tempFile) {
        Remove-Item $tempFile
    }
}

Write-Host "`nMigration Summary:" -ForegroundColor Cyan
Write-Host "- Added ProcessingItemWorkCenterTimes table for dynamic time entries" -ForegroundColor White
Write-Host "- Added WorkCenterDependencies table for operation dependencies" -ForegroundColor White
Write-Host "- Enhanced WorkCenter with comprehensive cost structure fields" -ForegroundColor White
Write-Host "- Renamed Package.RoutingTemplateId to RoutingId" -ForegroundColor White
Write-Host "- Updated ApplicationDbContext with new entities" -ForegroundColor White

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Run .\rebuild.ps1 to rebuild the Docker container" -ForegroundColor White
Write-Host "2. Test the routing selection in Package creation modal" -ForegroundColor White
Write-Host "3. Verify dynamic worksheet columns work with selected routing" -ForegroundColor White