# PowerShell script to verify staging database setup
# Target: sqldb-steel-estimation-sandbox

param(
    [Parameter(Mandatory=$true)]
    [string]$SqlUsername = "sqladmin",
    
    [Parameter(Mandatory=$true)]
    [SecureString]$SqlPassword
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Staging Database Verification" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Database: sqldb-steel-estimation-sandbox" -ForegroundColor Yellow
Write-Host "Server: nwiapps.database.windows.net" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

# Convert SecureString to plain text
$PlainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SqlPassword))

# Create connection string
$connectionString = "Server=nwiapps.database.windows.net;Database=sqldb-steel-estimation-sandbox;User Id=$SqlUsername;Password=$PlainPassword;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

# SQL query to check database state
$query = @"
-- Check if EF Migrations History table exists
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '__EFMigrationsHistory')
BEGIN
    SELECT 'EF Migrations History' as [Check], 'EXISTS' as [Status], COUNT(*) as [Count] FROM __EFMigrationsHistory
END
ELSE
BEGIN
    SELECT 'EF Migrations History' as [Check], 'NOT EXISTS' as [Status], 0 as [Count]
END

-- Check core tables
SELECT 'Users Table' as [Check], 
    CASE WHEN EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Users') 
    THEN 'EXISTS' ELSE 'NOT EXISTS' END as [Status],
    CASE WHEN EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Users')
    THEN (SELECT COUNT(*) FROM Users) ELSE 0 END as [Count]

UNION ALL

SELECT 'Roles Table' as [Check], 
    CASE WHEN EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Roles') 
    THEN 'EXISTS' ELSE 'NOT EXISTS' END as [Status],
    CASE WHEN EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Roles')
    THEN (SELECT COUNT(*) FROM Roles) ELSE 0 END as [Count]

UNION ALL

SELECT 'Projects Table' as [Check], 
    CASE WHEN EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Projects') 
    THEN 'EXISTS' ELSE 'NOT EXISTS' END as [Status],
    CASE WHEN EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Projects')
    THEN (SELECT COUNT(*) FROM Projects) ELSE 0 END as [Count]

-- Check for admin user
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Users')
BEGIN
    SELECT 'Admin User' as [Check], 
        CASE WHEN EXISTS (SELECT * FROM Users WHERE Email = 'admin@steelestimation.com') 
        THEN 'EXISTS' ELSE 'NOT EXISTS' END as [Status],
        0 as [Count]
END

-- Check Managed Identity permissions
SELECT 'Managed Identity' as [Check], 
    CASE WHEN EXISTS (
        SELECT * FROM sys.database_principals 
        WHERE name = 'app-steel-estimation-prod/slots/staging'
    ) THEN 'EXISTS' ELSE 'NOT EXISTS' END as [Status],
    0 as [Count]

-- List all tables
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME
"@

try {
    Write-Host "`nConnecting to database..." -ForegroundColor Yellow
    
    # Import SQL Server module or use .NET directly
    Add-Type -AssemblyName "System.Data"
    
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()
    
    Write-Host "Connected successfully!" -ForegroundColor Green
    
    # Execute query
    $command = $connection.CreateCommand()
    $command.CommandText = $query
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataset) | Out-Null
    
    Write-Host "`nDatabase Status:" -ForegroundColor Cyan
    Write-Host "----------------" -ForegroundColor Cyan
    
    # Display first result set (checks)
    if ($dataset.Tables.Count -gt 0) {
        $dataset.Tables[0] | Format-Table -AutoSize
    }
    
    # Display table list if available
    if ($dataset.Tables.Count -gt 1) {
        Write-Host "`nExisting Tables:" -ForegroundColor Cyan
        Write-Host "----------------" -ForegroundColor Cyan
        $dataset.Tables[1] | ForEach-Object { Write-Host "  - $($_.TABLE_NAME)" -ForegroundColor White }
    }
    
    $connection.Close()
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Verification Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    
} catch {
    Write-Host "`nError connecting to database:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Verify credentials are correct" -ForegroundColor White
    Write-Host "2. Check if your IP is allowed in Azure SQL firewall" -ForegroundColor White
    Write-Host "3. Ensure the database exists: sqldb-steel-estimation-sandbox" -ForegroundColor White
}

Write-Host "`nPress any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")