# Find SQL Server instances and databases
Write-Host "Finding SQL Server instances..." -ForegroundColor Cyan

# Check services
Write-Host "`n1. SQL Server Services:" -ForegroundColor Yellow
Get-Service | Where-Object {$_.Name -like "*SQL*"} | Select-Object Name, Status, DisplayName | Format-Table

# Check for SQL Server instances
Write-Host "`n2. Checking common SQL Server instances:" -ForegroundColor Yellow
$instances = @(
    "localhost",
    ".\SQLEXPRESS",
    "(localdb)\MSSQLLocalDB",
    "$env:COMPUTERNAME",
    "$env:COMPUTERNAME\SQLEXPRESS"
)

foreach ($instance in $instances) {
    Write-Host "`nTrying $instance..." -ForegroundColor Gray
    try {
        $result = Invoke-Sqlcmd -ServerInstance $instance -Query "SELECT @@VERSION" -ErrorAction Stop -ConnectionTimeout 2
        Write-Host "✓ Connected to: $instance" -ForegroundColor Green
        Write-Host "  Version: $($result[0])" -ForegroundColor Gray
        
        # List databases
        Write-Host "  Databases:" -ForegroundColor Cyan
        $dbs = Invoke-Sqlcmd -ServerInstance $instance -Query "SELECT name FROM sys.databases WHERE name NOT IN ('master','tempdb','model','msdb')" -ErrorAction Stop
        foreach ($db in $dbs) {
            Write-Host "    - $($db.name)" -ForegroundColor White
        }
    } catch {
        Write-Host "✗ Cannot connect to: $instance" -ForegroundColor Red
    }
}

Write-Host "`n3. Connection string from appsettings.Development.json:" -ForegroundColor Yellow
$appsettings = Get-Content ".\SteelEstimation.Web\appsettings.Development.json" | ConvertFrom-Json
Write-Host $appsettings.ConnectionStrings.DefaultConnection -ForegroundColor Cyan

Write-Host "`nBased on the results above, use the working instance name with the export script." -ForegroundColor Green