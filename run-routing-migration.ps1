#!/usr/bin/env pwsh
# ===============================================
# Routing Templates Migration Script
# ===============================================
# This script runs the database migration for routing templates
# Prerequisites: Azure SQL connection must be configured
# ===============================================

param(
    [switch]$Force,
    [switch]$Rollback
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Routing Templates Migration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Load configuration
$configFile = "./appsettings.Development.json"
if (-not (Test-Path $configFile)) {
    Write-Host "Configuration file not found: $configFile" -ForegroundColor Red
    exit 1
}

$config = Get-Content $configFile | ConvertFrom-Json
$connectionString = $config.ConnectionStrings.DefaultConnection

if ([string]::IsNullOrEmpty($connectionString)) {
    Write-Host "Connection string not found in configuration" -ForegroundColor Red
    exit 1
}

# Parse connection string
$connBuilder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder($connectionString)
$server = $connBuilder.DataSource
$database = $connBuilder.InitialCatalog
$userId = $connBuilder.UserID
$password = $connBuilder.Password

Write-Host "Server: $server" -ForegroundColor Yellow
Write-Host "Database: $database" -ForegroundColor Yellow
Write-Host ""

# Migration file path
$migrationFile = "./SteelEstimation.Infrastructure/Migrations/AddRoutingTemplates.sql"

if (-not (Test-Path $migrationFile)) {
    Write-Host "Migration file not found: $migrationFile" -ForegroundColor Red
    exit 1
}

# Check if migration has already been run
Write-Host "Checking if migration has already been run..." -ForegroundColor Yellow

$checkQuery = @"
SELECT COUNT(*) as TableCount
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME IN ('RoutingTemplates', 'RoutingOperations')
"@

try {
    $result = sqlcmd -S $server -d $database -U $userId -P $password -Q $checkQuery -h -1 -W 2>$null
    $tableCount = [int]$result.Trim()
    
    if ($tableCount -eq 2 -and -not $Force) {
        Write-Host "Routing tables already exist. Migration may have already been run." -ForegroundColor Yellow
        Write-Host "Use -Force parameter to run anyway." -ForegroundColor Yellow
        
        $response = Read-Host "Do you want to continue anyway? (y/n)"
        if ($response -ne 'y') {
            Write-Host "Migration cancelled." -ForegroundColor Yellow
            exit 0
        }
    }
} catch {
    Write-Host "Warning: Could not check existing tables. Continuing..." -ForegroundColor Yellow
}

# Run migration
Write-Host "Running routing templates migration..." -ForegroundColor Green

try {
    # Execute the migration script
    $output = sqlcmd -S $server -d $database -U $userId -P $password -i $migrationFile -I 2>&1
    
    # Check for errors in output
    if ($output -match "error|failed" -and $output -notmatch "already exists") {
        Write-Host "Migration encountered errors:" -ForegroundColor Red
        Write-Host $output
        exit 1
    }
    
    Write-Host $output
    
    # Verify the migration
    Write-Host ""
    Write-Host "Verifying migration..." -ForegroundColor Yellow
    
    $verifyQuery = @"
SELECT 
    'RoutingTemplates' as TableName,
    COUNT(*) as RecordCount
FROM RoutingTemplates
UNION ALL
SELECT 
    'RoutingOperations' as TableName,
    COUNT(*) as RecordCount
FROM RoutingOperations
UNION ALL
SELECT 
    'Sample Templates' as TableName,
    COUNT(*) as RecordCount
FROM RoutingTemplates
WHERE ApprovalStatus = 'Approved'
"@
    
    $verifyResult = sqlcmd -S $server -d $database -U $userId -P $password -Q $verifyQuery -s "|" -W
    
    Write-Host ""
    Write-Host "Migration Results:" -ForegroundColor Green
    Write-Host $verifyResult
    
    # Check for columns in Packages table
    $checkPackagesQuery = @"
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Packages' 
AND COLUMN_NAME = 'RoutingTemplateId'
"@
    
    $packageColumn = sqlcmd -S $server -d $database -U $userId -P $password -Q $checkPackagesQuery -h -1 -W 2>$null
    
    if ($packageColumn -eq "RoutingTemplateId") {
        Write-Host "✓ RoutingTemplateId column added to Packages table" -ForegroundColor Green
    }
    
    # Check for columns in ProcessingItems table
    $checkProcessingQuery = @"
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'ProcessingItems' 
AND COLUMN_NAME = 'RoutingOperationId'
"@
    
    $processingColumn = sqlcmd -S $server -d $database -U $userId -P $password -Q $checkProcessingQuery -h -1 -W 2>$null
    
    if ($processingColumn -eq "RoutingOperationId") {
        Write-Host "✓ RoutingOperationId column added to ProcessingItems table" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " Migration Completed Successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Restart the application to use new features" -ForegroundColor White
    Write-Host "2. Navigate to Settings > Business Configuration > Routing Templates" -ForegroundColor White
    Write-Host "3. Create or modify routing templates for your workflows" -ForegroundColor White
    
} catch {
    Write-Host "Error running migration: $_" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Optional: Create rollback script
if ($Rollback) {
    Write-Host ""
    Write-Host "Creating rollback script..." -ForegroundColor Yellow
    
    $rollbackScript = @"
-- Rollback script for Routing Templates migration
-- WARNING: This will delete all routing data!

-- Drop foreign key constraints first
IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_ProcessingItems_RoutingOperations')
    ALTER TABLE ProcessingItems DROP CONSTRAINT FK_ProcessingItems_RoutingOperations;

IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Packages_RoutingTemplates')
    ALTER TABLE Packages DROP CONSTRAINT FK_Packages_RoutingTemplates;

-- Drop columns
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[ProcessingItems]') AND name = 'RoutingOperationId')
    ALTER TABLE ProcessingItems DROP COLUMN RoutingOperationId;

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Packages]') AND name = 'RoutingTemplateId')
    ALTER TABLE Packages DROP COLUMN RoutingTemplateId;

-- Drop tables
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'RoutingOperations')
    DROP TABLE RoutingOperations;

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'RoutingTemplates')
    DROP TABLE RoutingTemplates;

PRINT 'Routing Templates migration rolled back successfully.';
"@
    
    $rollbackScript | Out-File -FilePath "./Rollback_RoutingTemplates.sql" -Encoding UTF8
    Write-Host "Rollback script created: ./Rollback_RoutingTemplates.sql" -ForegroundColor Green
}