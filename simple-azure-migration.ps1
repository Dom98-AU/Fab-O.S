# Simple Azure SQL Migration from Docker
param(
    [string]$Username = "admin@nwi@nwiapps",
    [string]$Password = "Natweigh88"
)

Write-Host "=== Simple Azure SQL Migration ===" -ForegroundColor Cyan

# Use the backup/restore approach but with BACPAC format
Write-Host "`n[1/4] Creating backup from Docker SQL..." -ForegroundColor Green

# First, let's copy the existing database structure using a different method
Write-Host "Extracting database structure..." -ForegroundColor Yellow

# Create the database in Azure if it doesn't exist
Write-Host "Ensuring database exists in Azure..." -ForegroundColor Gray
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S "nwiapps.database.windows.net" `
    -d "master" `
    -U $Username `
    -P $Password `
    -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'sqldb-steel-estimation-sandbox') CREATE DATABASE [sqldb-steel-estimation-sandbox]"

# Generate migration script using bcp
Write-Host "`n[2/4] Generating migration scripts..." -ForegroundColor Green

# Create a simple schema and data export
$migrationScript = @"
-- Azure SQL Migration Script
-- This script recreates the Steel Estimation database

USE [sqldb-steel-estimation-sandbox];
GO

-- Companies table (base table)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Companies')
BEGIN
    CREATE TABLE [dbo].[Companies] (
        [Id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [Name] NVARCHAR(200) NOT NULL,
        [ABN] NVARCHAR(20) NULL,
        [Address] NVARCHAR(500) NULL,
        [Phone] NVARCHAR(20) NULL,
        [Email] NVARCHAR(100) NULL,
        [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedDate] DATETIME2 NULL,
        [IsActive] BIT NOT NULL DEFAULT 1
    );
END
GO

-- Roles table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Roles')
BEGIN
    CREATE TABLE [dbo].[Roles] (
        [Id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [Name] NVARCHAR(100) NOT NULL,
        [Description] NVARCHAR(500) NULL,
        [IsActive] BIT NOT NULL DEFAULT 1
    );
END
GO

-- Users table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Users')
BEGIN
    CREATE TABLE [dbo].[Users] (
        [Id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [CompanyId] INT NOT NULL,
        [Email] NVARCHAR(256) NOT NULL,
        [UserName] NVARCHAR(256) NOT NULL,
        [PasswordHash] NVARCHAR(MAX) NULL,
        [FirstName] NVARCHAR(100) NULL,
        [LastName] NVARCHAR(100) NULL,
        [PhoneNumber] NVARCHAR(20) NULL,
        [IsActive] BIT NOT NULL DEFAULT 1,
        [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedDate] DATETIME2 NULL,
        [LastLoginDate] DATETIME2 NULL,
        CONSTRAINT [FK_Users_Companies] FOREIGN KEY ([CompanyId]) REFERENCES [Companies]([Id])
    );
END
GO

-- Continue with other tables...
"@

# For now, let's use the docker initialization script as our source
Write-Host "Using Docker initialization scripts as source..." -ForegroundColor Yellow

# Copy the initialization script from Docker
docker cp steel-estimation-sql:/docker-entrypoint-initdb.d/init.sql ./docker-init.sql 2>$null

if (Test-Path "./docker-init.sql") {
    Write-Host "Found Docker initialization script" -ForegroundColor Green
    $initScript = Get-Content "./docker-init.sql" -Raw
    
    # Remove any USE statements and database creation
    $initScript = $initScript -replace "CREATE DATABASE.*?GO", ""
    $initScript = $initScript -replace "USE \[.*?\].*?GO", "USE [sqldb-steel-estimation-sandbox]`nGO"
    
    # Save the modified script
    $initScript | Out-File -FilePath "./azure-migration.sql" -Encoding UTF8
} else {
    # Get the complete schema from the backup
    Write-Host "Extracting schema from backup..." -ForegroundColor Yellow
    
    # Create backup
    docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd `
        -S localhost -U sa -P 'YourStrong@Password123' -C `
        -Q "BACKUP DATABASE SteelEstimationDB TO DISK = '/var/opt/mssql/backup/temp.bak' WITH FORMAT, INIT"
    
    # Use the simpler approach - get the schema from your local files
    Write-Host "Using project schema files..." -ForegroundColor Yellow
    
    # Look for migration files in the project
    $schemaFiles = Get-ChildItem -Path "." -Filter "*.sql" -Recurse | Where-Object { $_.Name -like "*schema*" -or $_.Name -like "*create*" }
    
    if ($schemaFiles) {
        Write-Host "Found schema files: $($schemaFiles.Count)" -ForegroundColor Green
        # Combine them into one migration script
        $combinedSchema = "USE [sqldb-steel-estimation-sandbox]`nGO`n`n"
        foreach ($file in $schemaFiles) {
            $content = Get-Content $file.FullName -Raw
            $combinedSchema += "`n-- From file: $($file.Name)`n"
            $combinedSchema += $content
            $combinedSchema += "`nGO`n"
        }
        $combinedSchema | Out-File -FilePath "./azure-migration.sql" -Encoding UTF8
    } else {
        # Use the basic migration script
        $migrationScript | Out-File -FilePath "./azure-migration.sql" -Encoding UTF8
    }
}

# Step 3: Apply to Azure
Write-Host "`n[3/4] Applying to Azure SQL..." -ForegroundColor Green

if (Test-Path "./azure-migration.sql") {
    docker run --rm -v ${PWD}:/scripts mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
        -S "nwiapps.database.windows.net" `
        -d "sqldb-steel-estimation-sandbox" `
        -U $Username `
        -P $Password `
        -i /scripts/azure-migration.sql
        
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Schema applied successfully!" -ForegroundColor Green
        
        # Now migrate data
        Write-Host "`n[4/4] Migrating data..." -ForegroundColor Green
        
        # Export data
        & ".\export-for-docker.ps1" -ServerInstance "localhost" -DatabaseName "SteelEstimationDB" -OutputFile "./azure-data.sql" -DockerMode $true
        
        # Import to Azure
        docker run --rm -v ${PWD}:/scripts mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
            -S "nwiapps.database.windows.net" `
            -d "sqldb-steel-estimation-sandbox" `
            -U $Username `
            -P $Password `
            -i /scripts/azure-data.sql
    }
}

# Verify
Write-Host "`nVerifying migration..." -ForegroundColor Green
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S "nwiapps.database.windows.net" `
    -d "sqldb-steel-estimation-sandbox" `
    -U $Username `
    -P $Password `
    -Q "SELECT name as TableName FROM sys.tables WHERE is_ms_shipped = 0 ORDER BY name"

Write-Host "`nDone!" -ForegroundColor Green