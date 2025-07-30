# PowerShell script to check migration status in staging database
param(
    [Parameter(Mandatory=$true)]
    [string]$SqlUsername = "sqladmin",
    
    [Parameter(Mandatory=$true)]
    [SecureString]$SqlPassword
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Checking Migration Status" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

# Convert SecureString to plain text
$PlainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SqlPassword))

# Create connection string
$connectionString = "Server=nwiapps.database.windows.net;Database=sqldb-steel-estimation-sandbox;User Id=$SqlUsername;Password=$PlainPassword;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

# SQL query to check migration status
$query = @"
-- Check if migrations table exists and what migrations are applied
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '__EFMigrationsHistory')
BEGIN
    SELECT 'Migrations Applied:' as Status
    SELECT MigrationId, ProductVersion FROM __EFMigrationsHistory
END
ELSE
BEGIN
    SELECT 'No migrations history table found' as Status
END

-- Check if tables exist
SELECT 
    'Tables Exist' as CheckType,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE') as TableCount

-- List all tables
SELECT TABLE_NAME, 
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE c.TABLE_NAME = t.TABLE_NAME) as ColumnCount
FROM INFORMATION_SCHEMA.TABLES t 
WHERE TABLE_TYPE = 'BASE TABLE' 
ORDER BY TABLE_NAME

-- Check if admin user exists
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Users')
BEGIN
    SELECT TOP 5 Id, Username, Email, IsActive, CreatedDate 
    FROM Users 
    ORDER BY Id
END
"@

try {
    Add-Type -AssemblyName "System.Data"
    
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()
    
    Write-Host "Connected to database successfully!" -ForegroundColor Green
    
    $command = $connection.CreateCommand()
    $command.CommandText = $query
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataset) | Out-Null
    
    # Display results
    for ($i = 0; $i -lt $dataset.Tables.Count; $i++) {
        $table = $dataset.Tables[$i]
        if ($table.Rows.Count -gt 0) {
            Write-Host "`n" -NoNewline
            $table | Format-Table -AutoSize
        }
    }
    
    $connection.Close()
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "What to do next:" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    
    Write-Host "`nIf tables exist but no migration history:" -ForegroundColor Yellow
    Write-Host "1. The database was created manually (not through EF migrations)" -ForegroundColor White
    Write-Host "2. You need to add the migration history manually" -ForegroundColor White
    Write-Host "3. Or drop and recreate the database" -ForegroundColor White
    
    Write-Host "`nIf migration history exists:" -ForegroundColor Yellow
    Write-Host "1. Check if '20250630054245_InitialCreate' is listed" -ForegroundColor White
    Write-Host "2. If yes, the database is up to date" -ForegroundColor White
    Write-Host "3. If no, you may need to sync the migration state" -ForegroundColor White
    
} catch {
    Write-Host "`nError:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host "`nPress any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")