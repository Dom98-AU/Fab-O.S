# Add missing tables to Azure SQL Database
param(
    [string]$Username = "admin@nwi@nwiapps",
    [string]$Password = "Natweigh88"
)

Write-Host "Adding missing tables to Azure SQL Database..." -ForegroundColor Cyan

# First, let's see what tables we need to add
Write-Host "`nChecking which tables are missing..." -ForegroundColor Yellow

$checkScript = @"
-- Check for missing core tables
SELECT 'Companies' as MissingTable WHERE NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Companies')
UNION ALL
SELECT 'Customers' WHERE NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Customers')
UNION ALL
SELECT 'Packages' WHERE NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Packages')
UNION ALL
SELECT 'PackageWorksheets' WHERE NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'PackageWorksheets')
UNION ALL
SELECT 'Estimations' WHERE NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Estimations')
UNION ALL
SELECT 'DeliveryBundles' WHERE NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DeliveryBundles')
UNION ALL
SELECT 'PackBundles' WHERE NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'PackBundles')
UNION ALL
SELECT 'EstimationTimeLogs' WHERE NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'EstimationTimeLogs')
UNION ALL
SELECT 'EfficiencyRates' WHERE NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'EfficiencyRates')
UNION ALL
SELECT 'WeldingItemConnections' WHERE NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'WeldingItemConnections')
UNION ALL
SELECT 'WeldingConnections' WHERE NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'WeldingConnections')
UNION ALL
SELECT 'Postcodes' WHERE NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Postcodes')
"@

docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S "nwiapps.database.windows.net" `
    -d "sqldb-steel-estimation-sandbox" `
    -U $Username `
    -P $Password `
    -Q $checkScript

# Get the schema from your Docker SQL for missing tables
Write-Host "`nExtracting schema for missing tables from Docker..." -ForegroundColor Yellow

# Export schema for tables that don't exist in Azure
$schemaFile = ".\add-missing-tables.sql"

# Start with Companies table (required by many others)
$companiesSchema = @"
-- Add Companies table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Companies')
BEGIN
    CREATE TABLE [dbo].[Companies] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [Name] NVARCHAR(200) NOT NULL,
        [ABN] NVARCHAR(20) NULL,
        [Address] NVARCHAR(500) NULL,
        [Phone] NVARCHAR(20) NULL,
        [Email] NVARCHAR(100) NULL,
        [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedDate] DATETIME2 NULL,
        [IsActive] BIT NOT NULL DEFAULT 1,
        CONSTRAINT [PK_Companies] PRIMARY KEY ([Id])
    );
    
    -- Insert default company
    INSERT INTO Companies (Name, CreatedDate, IsActive) 
    VALUES ('Default Company', GETUTCDATE(), 1);
END
GO

-- Update existing users to have CompanyId
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'CompanyId')
BEGIN
    UPDATE Users SET CompanyId = 1 WHERE CompanyId IS NULL;
END
ELSE
BEGIN
    ALTER TABLE Users ADD CompanyId INT NULL;
    UPDATE Users SET CompanyId = 1;
    ALTER TABLE Users ALTER COLUMN CompanyId INT NOT NULL;
    ALTER TABLE Users ADD CONSTRAINT FK_Users_Companies FOREIGN KEY (CompanyId) REFERENCES Companies(Id);
END
GO
"@

Out-File -FilePath $schemaFile -InputObject $companiesSchema -Encoding UTF8

# Add other missing tables by getting schema from Docker
Write-Host "Getting schema from Docker SQL Server..." -ForegroundColor Gray

# Get full schema from Docker and filter for missing tables
$dockerSchema = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P 'YourStrong@Password123' -C `
    -d SteelEstimationDB `
    -i /docker-entrypoint-initdb.d/schema-export.sql

# For now, let's add the most critical tables manually
$additionalSchema = @"

-- Customers table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Customers')
BEGIN
    CREATE TABLE [dbo].[Customers] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [CompanyId] INT NOT NULL,
        [Name] NVARCHAR(200) NOT NULL,
        [ABN] NVARCHAR(20) NULL,
        [Address] NVARCHAR(500) NULL,
        [Phone] NVARCHAR(20) NULL,
        [Email] NVARCHAR(100) NULL,
        [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedDate] DATETIME2 NULL,
        [IsActive] BIT NOT NULL DEFAULT 1,
        CONSTRAINT [PK_Customers] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Customers_Companies] FOREIGN KEY ([CompanyId]) REFERENCES [Companies]([Id])
    );
END
GO

-- Update Projects to add CustomerId if missing
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Projects') AND name = 'CustomerId')
BEGIN
    ALTER TABLE Projects ADD CustomerId INT NULL;
END
GO

-- EfficiencyRates table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'EfficiencyRates')
BEGIN
    CREATE TABLE [dbo].[EfficiencyRates] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [CompanyId] INT NOT NULL,
        [Name] NVARCHAR(100) NOT NULL,
        [Rate] DECIMAL(5,2) NOT NULL,
        [IsDefault] BIT NOT NULL DEFAULT 0,
        [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT [PK_EfficiencyRates] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_EfficiencyRates_Companies] FOREIGN KEY ([CompanyId]) REFERENCES [Companies]([Id])
    );
    
    -- Insert default rates
    INSERT INTO EfficiencyRates (CompanyId, Name, Rate, IsDefault) VALUES
    (1, '100%', 100.00, 1),
    (1, '90%', 90.00, 0),
    (1, '80%', 80.00, 0),
    (1, '70%', 70.00, 0),
    (1, '60%', 60.00, 0);
END
GO

-- Postcodes table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Postcodes')
BEGIN
    CREATE TABLE [dbo].[Postcodes] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [Postcode] NVARCHAR(10) NOT NULL,
        [Suburb] NVARCHAR(100) NOT NULL,
        [State] NVARCHAR(50) NOT NULL,
        [Latitude] DECIMAL(10,8) NULL,
        [Longitude] DECIMAL(11,8) NULL,
        CONSTRAINT [PK_Postcodes] PRIMARY KEY ([Id])
    );
    CREATE INDEX IX_Postcodes_Postcode ON Postcodes(Postcode);
END
GO

-- DeliveryBundles table  
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DeliveryBundles')
BEGIN
    CREATE TABLE [dbo].[DeliveryBundles] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ProjectId] INT NOT NULL,
        [BundleName] NVARCHAR(200) NOT NULL,
        [DeliveryAddress] NVARCHAR(500) NULL,
        [DeliveryDate] DATETIME2 NULL,
        [SortOrder] INT NOT NULL DEFAULT 0,
        [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedDate] DATETIME2 NULL,
        CONSTRAINT [PK_DeliveryBundles] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_DeliveryBundles_Projects] FOREIGN KEY ([ProjectId]) REFERENCES [Projects]([Id]) ON DELETE CASCADE
    );
END
GO

-- PackBundles table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PackBundles')
BEGIN
    CREATE TABLE [dbo].[PackBundles] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ProjectId] INT NOT NULL,
        [BundleName] NVARCHAR(200) NOT NULL,
        [Description] NVARCHAR(500) NULL,
        [SortOrder] INT NOT NULL DEFAULT 0,
        [CreatedDate] DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        [UpdatedDate] DATETIME2 NULL,
        CONSTRAINT [PK_PackBundles] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_PackBundles_Projects] FOREIGN KEY ([ProjectId]) REFERENCES [Projects]([Id]) ON DELETE CASCADE
    );
END
GO

-- Update ProcessingItems for bundles
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('ProcessingItems') AND name = 'DeliveryBundleId')
BEGIN
    ALTER TABLE ProcessingItems ADD DeliveryBundleId INT NULL;
    ALTER TABLE ProcessingItems ADD CONSTRAINT FK_ProcessingItems_DeliveryBundles 
        FOREIGN KEY (DeliveryBundleId) REFERENCES DeliveryBundles(Id);
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('ProcessingItems') AND name = 'PackBundleId')
BEGIN
    ALTER TABLE ProcessingItems ADD PackBundleId INT NULL;
    ALTER TABLE ProcessingItems ADD IsParentInPackBundle BIT NOT NULL DEFAULT 0;
    ALTER TABLE ProcessingItems ADD CONSTRAINT FK_ProcessingItems_PackBundles 
        FOREIGN KEY (PackBundleId) REFERENCES PackBundles(Id);
END
GO
"@

Add-Content -Path $schemaFile -Value $additionalSchema

# Apply the schema changes
Write-Host "`nApplying schema changes to Azure SQL..." -ForegroundColor Green
docker run --rm -v ${PWD}:/scripts mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S "nwiapps.database.windows.net" `
    -d "sqldb-steel-estimation-sandbox" `
    -U $Username `
    -P $Password `
    -i /scripts/add-missing-tables.sql

# Verify the changes
Write-Host "`nVerifying tables..." -ForegroundColor Green
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S "nwiapps.database.windows.net" `
    -d "sqldb-steel-estimation-sandbox" `
    -U $Username `
    -P $Password `
    -Q "SELECT name as TableName FROM sys.tables WHERE is_ms_shipped = 0 ORDER BY name"

Write-Host "`nTable counts:" -ForegroundColor Green
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S "nwiapps.database.windows.net" `
    -d "sqldb-steel-estimation-sandbox" `
    -U $Username `
    -P $Password `
    -Q "SELECT COUNT(*) as TotalTables FROM sys.tables WHERE is_ms_shipped = 0"

Write-Host "`nDone! Missing tables have been added." -ForegroundColor Green
Write-Host "Next step: Import data from your Docker SQL Server" -ForegroundColor Yellow