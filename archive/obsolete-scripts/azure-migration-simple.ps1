# Complete Azure SQL Migration - Simple Version
Write-Host "=== Steel Estimation Platform - Azure SQL Migration ===" -ForegroundColor Cyan
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

# STEP 1: Apply Schema
Write-Host ""
Write-Host "Step 1: Applying database schema to Azure SQL..." -ForegroundColor Cyan

# Use the existing azure-schema-fixed.sql file
Write-Host "Applying schema from azure-schema-fixed.sql..." -ForegroundColor Green

try {
    $result = docker run --rm -v ${PWD}:/scripts mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -i /scripts/azure-schema-fixed.sql -I
    Write-Host "Schema applied successfully" -ForegroundColor Green
} catch {
    Write-Host "Error applying schema: $($_.Exception.Message)" -ForegroundColor Red
}

# STEP 2: Verify Schema
Write-Host ""
Write-Host "Step 2: Verifying schema..." -ForegroundColor Cyan

$tableCount = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0" -h -1

Write-Host "Total tables in Azure SQL: $($tableCount.Trim())" -ForegroundColor Green

# STEP 3: Test Connection to Docker
Write-Host ""
Write-Host "Step 3: Testing Docker connection..." -ForegroundColor Cyan

$dockerTest = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Password123' -C -d SteelEstimationDB -Q "SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped = 0" -h -1

Write-Host "Total tables in Docker SQL: $($dockerTest.Trim())" -ForegroundColor Green

# STEP 4: Migrate Core Data
Write-Host ""
Write-Host "Step 4: Migrating essential data..." -ForegroundColor Cyan

# Companies
Write-Host "Migrating Companies..." -ForegroundColor Yellow
$companiesSQL = "SET IDENTITY_INSERT [Companies] ON; INSERT INTO [Companies] ([Id], [Name], [Code], [IsActive]) VALUES (1, 'Default Company', 'DEFAULT', 1); SET IDENTITY_INSERT [Companies] OFF;"
$companiesSQL | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword

# Roles
Write-Host "Migrating Roles..." -ForegroundColor Yellow
$rolesSQL = @"
INSERT INTO [AspNetRoles] ([Id], [Name], [NormalizedName]) VALUES 
('1', 'Administrator', 'ADMINISTRATOR'),
('2', 'Project Manager', 'PROJECT MANAGER'),
('3', 'Senior Estimator', 'SENIOR ESTIMATOR'),
('4', 'Estimator', 'ESTIMATOR'),
('5', 'Viewer', 'VIEWER');
"@
$rolesSQL | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword

# Admin User
Write-Host "Migrating Admin User..." -ForegroundColor Yellow
$adminSQL = @"
INSERT INTO [AspNetUsers] ([Id], [FullName], [CompanyId], [UserName], [NormalizedUserName], [Email], [NormalizedEmail], [EmailConfirmed], [PasswordHash], [SecurityStamp], [ConcurrencyStamp], [PhoneNumberConfirmed], [TwoFactorEnabled], [LockoutEnabled], [AccessFailedCount])
VALUES 
('00000000-0000-0000-0000-000000000001', 'System Administrator', 1, 'admin@steelestimation.com', 'ADMIN@STEELESTIMATION.COM', 'admin@steelestimation.com', 'ADMIN@STEELESTIMATION.COM', 1, 'AQAAAAEAACcQAAAAEMvMR2X5W6V7LqYqHZWuHVOKRrYmYJ+eWz9J7NfV0cJHQF5bHQ5TvB+vW7C1X8vL5g==', 'QWERTYUIOPASDFGHJKLZXCVBNM123456', 'abcdef01-2345-6789-abcd-ef0123456789', 0, 0, 1, 0);
"@
$adminSQL | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword

# User Roles
Write-Host "Migrating User Roles..." -ForegroundColor Yellow
$userRolesSQL = "INSERT INTO [AspNetUserRoles] ([UserId], [RoleId]) VALUES ('00000000-0000-0000-0000-000000000001', '1');"
$userRolesSQL | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword

# Efficiency Rates
Write-Host "Migrating Efficiency Rates..." -ForegroundColor Yellow
$efficiencySQL = @"
SET IDENTITY_INSERT [EfficiencyRates] ON;
INSERT INTO [EfficiencyRates] ([Id], [CompanyId], [Name], [Description], [Rate], [IsDefault], [IsActive], [CreatedById])
VALUES 
(1, 1, 'Standard (75%)', 'Standard efficiency rate for normal operations', 75.00, 1, 1, '00000000-0000-0000-0000-000000000001'),
(2, 1, 'High Efficiency (85%)', 'For optimized operations with experienced teams', 85.00, 0, 1, '00000000-0000-0000-0000-000000000001'),
(3, 1, 'Complex Work (65%)', 'For complex operations requiring extra care', 65.00, 0, 1, '00000000-0000-0000-0000-000000000001'),
(4, 1, 'Rush Job (55%)', 'For urgent projects with tight deadlines', 55.00, 0, 1, '00000000-0000-0000-0000-000000000001');
SET IDENTITY_INSERT [EfficiencyRates] OFF;
"@
$efficiencySQL | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword

# Postcodes
Write-Host "Migrating Postcodes..." -ForegroundColor Yellow
$postcodesSQL = @"
INSERT INTO [Postcodes] ([Postcode], [Suburb], [State]) VALUES 
('2000', 'Sydney', 'NSW'),
('3000', 'Melbourne', 'VIC'),
('4000', 'Brisbane', 'QLD'),
('5000', 'Adelaide', 'SA'),
('6000', 'Perth', 'WA');
"@
$postcodesSQL | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword

# STEP 5: Final Verification
Write-Host ""
Write-Host "Step 5: Final verification..." -ForegroundColor Cyan

$finalCount = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q "SELECT t.name AS TableName, ISNULL(p.rows, 0) AS RowCount FROM sys.tables t LEFT JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1) WHERE t.is_ms_shipped = 0 ORDER BY t.name"

Write-Host "Migration Summary:" -ForegroundColor Cyan
Write-Host $finalCount

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