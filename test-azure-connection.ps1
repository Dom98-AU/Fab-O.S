# Test Azure SQL Connection
param(
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$true)]
    [string]$Password
)

Write-Host "Testing Azure SQL Connection..." -ForegroundColor Cyan

# Method 1: Using -U without domain
Write-Host "`nMethod 1: Testing with username only..." -ForegroundColor Yellow
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S "nwiapps.database.windows.net,1433" `
    -d "sqldb-steel-estimation-sandbox" `
    -U $Username `
    -P $Password `
    -Q "SELECT 'Connected successfully!' as Status"

# Method 2: Using full server name in username
Write-Host "`nMethod 2: Testing with username@servername..." -ForegroundColor Yellow
$fullUsername = $Username + "@nwiapps"
docker run --rm mcr.microsoft.com/mssql-tools:latest /opt/mssql-tools/bin/sqlcmd `
    -S "nwiapps.database.windows.net,1433" `
    -d "sqldb-steel-estimation-sandbox" `
    -U $fullUsername `
    -P $Password `
    -Q "SELECT 'Connected successfully!' as Status"

# Method 3: Using environment variables
Write-Host "`nMethod 3: Testing with environment variables..." -ForegroundColor Yellow
docker run --rm `
    -e SQLCMDSERVER="nwiapps.database.windows.net" `
    -e SQLCMDDBNAME="sqldb-steel-estimation-sandbox" `
    -e SQLCMDUSER=$Username `
    -e SQLCMDPASSWORD=$Password `
    mcr.microsoft.com/mssql-tools:latest `
    /opt/mssql-tools/bin/sqlcmd -Q "SELECT 'Connected successfully!' as Status"