# Quick check of Azure SQL Database status
param(
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$true)]
    [string]$Password
)

Write-Host "Checking Azure SQL Database: sqldb-steel-estimation-sandbox" -ForegroundColor Cyan
Write-Host "Server: nwiapps.database.windows.net" -ForegroundColor Yellow

# Check if we can connect
Write-Host "`nTesting connection..." -ForegroundColor Green
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S "nwiapps.database.windows.net" `
    -d "sqldb-steel-estimation-sandbox" `
    -U $Username `
    -P $Password `
    -C `
    -Q "SELECT @@VERSION"

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nConnection failed! Please check:" -ForegroundColor Red
    Write-Host "1. Username and password" -ForegroundColor Yellow
    Write-Host "2. Your IP is whitelisted in Azure firewall" -ForegroundColor Yellow
    exit 1
}

# Check existing tables
Write-Host "`nChecking existing tables..." -ForegroundColor Green
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S "nwiapps.database.windows.net" `
    -d "sqldb-steel-estimation-sandbox" `
    -U $Username `
    -P $Password `
    -C `
    -Q "SELECT COUNT(*) as TableCount FROM sys.tables WHERE is_ms_shipped = 0"

# List all user tables
Write-Host "`nListing all tables:" -ForegroundColor Green
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S "nwiapps.database.windows.net" `
    -d "sqldb-steel-estimation-sandbox" `
    -U $Username `
    -P $Password `
    -C `
    -Q "SELECT name as TableName FROM sys.tables WHERE is_ms_shipped = 0 ORDER BY name"

# Check for specific Steel Estimation tables
Write-Host "`nChecking for Steel Estimation tables..." -ForegroundColor Green
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S "nwiapps.database.windows.net" `
    -d "sqldb-steel-estimation-sandbox" `
    -U $Username `
    -P $Password `
    -C `
    -Q @"
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Users') THEN 'YES' 
        ELSE 'NO' 
    END as 'Users Table Exists',
    CASE 
        WHEN EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Projects') THEN 'YES' 
        ELSE 'NO' 
    END as 'Projects Table Exists',
    CASE 
        WHEN EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Companies') THEN 'YES' 
        ELSE 'NO' 
    END as 'Companies Table Exists'
"@

# If tables exist, check record counts
Write-Host "`nChecking data in existing tables..." -ForegroundColor Green
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S "nwiapps.database.windows.net" `
    -d "sqldb-steel-estimation-sandbox" `
    -U $Username `
    -P $Password `
    -C `
    -Q @"
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Users')
    SELECT 'Users' as TableName, COUNT(*) as Records FROM Users
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Projects')
    SELECT 'Projects' as TableName, COUNT(*) as Records FROM Projects
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Companies')
    SELECT 'Companies' as TableName, COUNT(*) as Records FROM Companies
"@