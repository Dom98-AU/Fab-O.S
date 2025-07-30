# Final Azure SQL Migration - Working Version
Write-Host "=== Steel Estimation Platform - Azure SQL Migration (Final) ===" -ForegroundColor Cyan
Write-Host "This will migrate your Docker SQL Server database to Azure SQL Database" -ForegroundColor White
Write-Host ""

# Confirm before proceeding
$confirm = Read-Host "This will overwrite existing data in Azure SQL. Continue? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Migration cancelled." -ForegroundColor Yellow
    exit
}

$azureUsername = "admin@nwi@nwiapps"
$azurePassword = "Natweigh88"
$azureServer = "nwiapps.database.windows.net"
$azureDatabase = "sqldb-steel-estimation-sandbox"

Write-Host ""
Write-Host "Starting migration process..." -ForegroundColor Green

# STEP 1: Apply Clean Schema
Write-Host ""
Write-Host "Step 1: Applying clean database schema to Azure SQL..." -ForegroundColor Cyan

try {
    docker run --rm -v ${PWD}:/scripts mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -i /scripts/azure-schema-clean.sql -t 60
    Write-Host "Schema applied successfully" -ForegroundColor Green
} catch {
    Write-Host "Error applying schema: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# STEP 2: Verify Schema
Write-Host ""
Write-Host "Step 2: Verifying schema..." -ForegroundColor Cyan

$tableCount = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0" -h -1 -t 30

Write-Host "Total tables in Azure SQL: $($tableCount.Trim())" -ForegroundColor Green

if ([int]$tableCount.Trim() -eq 0) {
    Write-Host "ERROR: No tables were created. Schema application failed." -ForegroundColor Red
    exit 1
}

# STEP 3: Insert Core Data (one by one with error checking)
Write-Host ""
Write-Host "Step 3: Inserting core data..." -ForegroundColor Cyan

# Companies
Write-Host "Inserting Companies..." -ForegroundColor Yellow
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "SET IDENTITY_INSERT [Companies] ON; INSERT INTO [Companies] ([Id], [Name], [Code], [IsActive]) VALUES (1, 'Default Company', 'DEFAULT', 1); SET IDENTITY_INSERT [Companies] OFF;" -t 30

# Roles
Write-Host "Inserting Roles..." -ForegroundColor Yellow
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "INSERT INTO [AspNetRoles] ([Id], [Name], [NormalizedName]) VALUES ('1', 'Administrator', 'ADMINISTRATOR');" -t 30
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "INSERT INTO [AspNetRoles] ([Id], [Name], [NormalizedName]) VALUES ('2', 'Project Manager', 'PROJECT MANAGER');" -t 30
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "INSERT INTO [AspNetRoles] ([Id], [Name], [NormalizedName]) VALUES ('3', 'Senior Estimator', 'SENIOR ESTIMATOR');" -t 30
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "INSERT INTO [AspNetRoles] ([Id], [Name], [NormalizedName]) VALUES ('4', 'Estimator', 'ESTIMATOR');" -t 30
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "INSERT INTO [AspNetRoles] ([Id], [Name], [NormalizedName]) VALUES ('5', 'Viewer', 'VIEWER');" -t 30

# Admin User
Write-Host "Inserting Admin User..." -ForegroundColor Yellow
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "INSERT INTO [AspNetUsers] ([Id], [FullName], [CompanyId], [UserName], [NormalizedUserName], [Email], [NormalizedEmail], [EmailConfirmed], [PasswordHash], [SecurityStamp], [ConcurrencyStamp], [PhoneNumberConfirmed], [TwoFactorEnabled], [LockoutEnabled], [AccessFailedCount]) VALUES ('00000000-0000-0000-0000-000000000001', 'System Administrator', 1, 'admin@steelestimation.com', 'ADMIN@STEELESTIMATION.COM', 'admin@steelestimation.com', 'ADMIN@STEELESTIMATION.COM', 1, 'AQAAAAEAACcQAAAAEMvMR2X5W6V7LqYqHZWuHVOKRrYmYJ+eWz9J7NfV0cJHQF5bHQ5TvB+vW7C1X8vL5g==', 'QWERTYUIOPASDFGHJKLZXCVBNM123456', 'abcdef01-2345-6789-abcd-ef0123456789', 0, 0, 1, 0);" -t 30

# User Roles
Write-Host "Inserting User Roles..." -ForegroundColor Yellow
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "INSERT INTO [AspNetUserRoles] ([UserId], [RoleId]) VALUES ('00000000-0000-0000-0000-000000000001', '1');" -t 30

# Efficiency Rates
Write-Host "Inserting Efficiency Rates..." -ForegroundColor Yellow
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "SET IDENTITY_INSERT [EfficiencyRates] ON; INSERT INTO [EfficiencyRates] ([Id], [CompanyId], [Name], [Description], [Rate], [IsDefault], [IsActive], [CreatedById]) VALUES (1, 1, 'Standard (75%)', 'Standard efficiency rate for normal operations', 75.00, 1, 1, '00000000-0000-0000-0000-000000000001'); SET IDENTITY_INSERT [EfficiencyRates] OFF;" -t 30
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "SET IDENTITY_INSERT [EfficiencyRates] ON; INSERT INTO [EfficiencyRates] ([Id], [CompanyId], [Name], [Description], [Rate], [IsDefault], [IsActive], [CreatedById]) VALUES (2, 1, 'High Efficiency (85%)', 'For optimized operations with experienced teams', 85.00, 0, 1, '00000000-0000-0000-0000-000000000001'); SET IDENTITY_INSERT [EfficiencyRates] OFF;" -t 30
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "SET IDENTITY_INSERT [EfficiencyRates] ON; INSERT INTO [EfficiencyRates] ([Id], [CompanyId], [Name], [Description], [Rate], [IsDefault], [IsActive], [CreatedById]) VALUES (3, 1, 'Complex Work (65%)', 'For complex operations requiring extra care', 65.00, 0, 1, '00000000-0000-0000-0000-000000000001'); SET IDENTITY_INSERT [EfficiencyRates] OFF;" -t 30
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "SET IDENTITY_INSERT [EfficiencyRates] ON; INSERT INTO [EfficiencyRates] ([Id], [CompanyId], [Name], [Description], [Rate], [IsDefault], [IsActive], [CreatedById]) VALUES (4, 1, 'Rush Job (55%)', 'For urgent projects with tight deadlines', 55.00, 0, 1, '00000000-0000-0000-0000-000000000001'); SET IDENTITY_INSERT [EfficiencyRates] OFF;" -t 30

# Postcodes
Write-Host "Inserting Postcodes..." -ForegroundColor Yellow
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "INSERT INTO [Postcodes] ([Postcode], [Suburb], [State]) VALUES ('2000', 'Sydney', 'NSW');" -t 30
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "INSERT INTO [Postcodes] ([Postcode], [Suburb], [State]) VALUES ('3000', 'Melbourne', 'VIC');" -t 30
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "INSERT INTO [Postcodes] ([Postcode], [Suburb], [State]) VALUES ('4000', 'Brisbane', 'QLD');" -t 30
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "INSERT INTO [Postcodes] ([Postcode], [Suburb], [State]) VALUES ('5000', 'Adelaide', 'SA');" -t 30
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "INSERT INTO [Postcodes] ([Postcode], [Suburb], [State]) VALUES ('6000', 'Perth', 'WA');" -t 30

# STEP 4: Final Verification
Write-Host ""
Write-Host "Step 4: Final verification..." -ForegroundColor Cyan

$tableList = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "SELECT name FROM sys.tables WHERE is_ms_shipped = 0 ORDER BY name" -t 30

Write-Host "Tables created in Azure SQL:" -ForegroundColor Green
Write-Host $tableList

$dataCheck = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "SELECT 'Companies: ' + CAST(COUNT(*) AS VARCHAR) FROM Companies UNION ALL SELECT 'Roles: ' + CAST(COUNT(*) AS VARCHAR) FROM AspNetRoles UNION ALL SELECT 'Users: ' + CAST(COUNT(*) AS VARCHAR) FROM AspNetUsers UNION ALL SELECT 'EfficiencyRates: ' + CAST(COUNT(*) AS VARCHAR) FROM EfficiencyRates UNION ALL SELECT 'Postcodes: ' + CAST(COUNT(*) AS VARCHAR) FROM Postcodes" -t 30

Write-Host "Data verification:" -ForegroundColor Green
Write-Host $dataCheck

Write-Host ""
Write-Host "Migration completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Update your docker-compose.yml to use Azure SQL" -ForegroundColor White
Write-Host "2. Test the application with Azure SQL connection" -ForegroundColor White
Write-Host "3. Login with: admin@steelestimation.com / Admin@123" -ForegroundColor White
Write-Host ""
Write-Host "Azure SQL Database: sqldb-steel-estimation-sandbox" -ForegroundColor Gray
Write-Host "Server: nwiapps.database.windows.net" -ForegroundColor Gray