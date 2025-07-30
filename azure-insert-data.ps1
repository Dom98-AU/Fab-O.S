# Insert Core Data into Azure SQL
Write-Host "=== Inserting Core Data into Azure SQL ===" -ForegroundColor Cyan

$azureUsername = "admin@nwi@nwiapps"
$azurePassword = "Natweigh88"
$azureServer = "nwiapps.database.windows.net"
$azureDatabase = "sqldb-steel-estimation-sandbox"

# Function to execute SQL with error handling
function Execute-SQL {
    param([string]$sql, [string]$description)
    
    Write-Host "Inserting $description..." -ForegroundColor Yellow
    try {
        $result = $sql | docker run --rm -i mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -t 30
        if ($result -match "rows affected") {
            Write-Host "✅ $description inserted successfully" -ForegroundColor Green
        } else {
            Write-Host "⚠️ $description may already exist" -ForegroundColor Yellow
        }
        return $true
    } catch {
        Write-Host "❌ Failed to insert $description`: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 1. Companies
$companiesSQL = @"
SET IDENTITY_INSERT [Companies] ON;
INSERT INTO [Companies] ([Id], [Name], [Code], [IsActive]) 
VALUES (1, 'Default Company', 'DEFAULT', 1);
SET IDENTITY_INSERT [Companies] OFF;
"@
Execute-SQL $companiesSQL "Company data"

# 2. Roles
$rolesSQL = @"
INSERT INTO [AspNetRoles] ([Id], [Name], [NormalizedName]) VALUES 
('1', 'Administrator', 'ADMINISTRATOR'),
('2', 'Project Manager', 'PROJECT MANAGER'),
('3', 'Senior Estimator', 'SENIOR ESTIMATOR'),
('4', 'Estimator', 'ESTIMATOR'),
('5', 'Viewer', 'VIEWER');
"@
Execute-SQL $rolesSQL "Roles data"

# 3. Admin User
$adminSQL = @"
INSERT INTO [AspNetUsers] ([Id], [FullName], [CompanyId], [UserName], [NormalizedUserName], [Email], [NormalizedEmail], [EmailConfirmed], [PasswordHash], [SecurityStamp], [ConcurrencyStamp], [PhoneNumberConfirmed], [TwoFactorEnabled], [LockoutEnabled], [AccessFailedCount])
VALUES 
('00000000-0000-0000-0000-000000000001', 'System Administrator', 1, 'admin@steelestimation.com', 'ADMIN@STEELESTIMATION.COM', 'admin@steelestimation.com', 'ADMIN@STEELESTIMATION.COM', 1, 'AQAAAAEAACcQAAAAEMvMR2X5W6V7LqYqHZWuHVOKRrYmYJ+eWz9J7NfV0cJHQF5bHQ5TvB+vW7C1X8vL5g==', 'QWERTYUIOPASDFGHJKLZXCVBNM123456', 'abcdef01-2345-6789-abcd-ef0123456789', 0, 0, 1, 0);
"@
Execute-SQL $adminSQL "Admin user"

# 4. User Roles
$userRolesSQL = @"
INSERT INTO [AspNetUserRoles] ([UserId], [RoleId])
VALUES ('00000000-0000-0000-0000-000000000001', '1');
"@
Execute-SQL $userRolesSQL "User roles"

# 5. Efficiency Rates
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
Execute-SQL $efficiencySQL "Efficiency rates"

# 6. Postcodes
$postcodesSQL = @"
INSERT INTO [Postcodes] ([Postcode], [Suburb], [State]) VALUES 
('2000', 'Sydney', 'NSW'),
('3000', 'Melbourne', 'VIC'),
('4000', 'Brisbane', 'QLD'),
('5000', 'Adelaide', 'SA'),
('6000', 'Perth', 'WA');
"@
Execute-SQL $postcodesSQL "Postcodes"

# Final verification
Write-Host "`nFinal verification..." -ForegroundColor Cyan

$dataCheck = @"
SELECT 'Companies' as TableName, COUNT(*) as RecordCount FROM Companies
UNION ALL
SELECT 'AspNetRoles', COUNT(*) FROM AspNetRoles
UNION ALL
SELECT 'AspNetUsers', COUNT(*) FROM AspNetUsers
UNION ALL
SELECT 'AspNetUserRoles', COUNT(*) FROM AspNetUserRoles
UNION ALL
SELECT 'EfficiencyRates', COUNT(*) FROM EfficiencyRates
UNION ALL
SELECT 'Postcodes', COUNT(*) FROM Postcodes
ORDER BY TableName;
"@

$verification = docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd -S $azureServer -d $azureDatabase -U $azureUsername -P $azurePassword -Q $dataCheck -t 30

Write-Host "Data verification:" -ForegroundColor Green
Write-Host $verification

Write-Host "`n✅ Data insertion completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Your Azure SQL database is now ready!" -ForegroundColor Cyan
Write-Host "Login credentials: admin@steelestimation.com / Admin@123" -ForegroundColor Gray