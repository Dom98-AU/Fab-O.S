# Diagnostic script for local development issues
Write-Host "=== Steel Estimation Platform - Local Development Diagnostics ===" -ForegroundColor Cyan

# 1. Check .NET SDK
Write-Host "`n1. Checking .NET SDK..." -ForegroundColor Yellow
dotnet --version

# 2. Check SQL Server
Write-Host "`n2. Checking SQL Server..." -ForegroundColor Yellow
$sqlService = Get-Service -Name "MSSQLSERVER" -ErrorAction SilentlyContinue
if ($sqlService) {
    Write-Host "   SQL Server Status: $($sqlService.Status)" -ForegroundColor Green
} else {
    Write-Host "   SQL Server not found!" -ForegroundColor Red
}

# 3. Test database connection
Write-Host "`n3. Testing database connection..." -ForegroundColor Yellow
$connectionString = "Server=localhost;Database=SteelEstimationDb;Trusted_Connection=True;"
try {
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()
    Write-Host "   Database connection: SUCCESS" -ForegroundColor Green
    
    # Check if admin user exists
    $command = $connection.CreateCommand()
    $command.CommandText = "SELECT COUNT(*) FROM Users WHERE Email = 'admin@steelestimation.com'"
    $count = $command.ExecuteScalar()
    Write-Host "   Admin user exists: $($count -gt 0)" -ForegroundColor Green
    
    $connection.Close()
} catch {
    Write-Host "   Database connection: FAILED - $_" -ForegroundColor Red
}

# 4. Check ports
Write-Host "`n4. Checking port availability..." -ForegroundColor Yellow
$ports = @(5000, 5001, 62744, 62745)
foreach ($port in $ports) {
    $tcpConnection = Test-NetConnection -ComputerName localhost -Port $port -WarningAction SilentlyContinue
    if ($tcpConnection.TcpTestSucceeded) {
        Write-Host "   Port $port : IN USE" -ForegroundColor Yellow
    } else {
        Write-Host "   Port $port : AVAILABLE" -ForegroundColor Green
    }
}

# 5. Check Windows Firewall
Write-Host "`n5. Checking Windows Firewall..." -ForegroundColor Yellow
$firewallProfile = Get-NetFirewallProfile -Name Domain,Private,Public | Where-Object {$_.Enabled -eq $true}
if ($firewallProfile) {
    Write-Host "   Firewall is enabled on profiles: $($firewallProfile.Name -join ', ')" -ForegroundColor Yellow
    Write-Host "   You may need to allow localhost connections" -ForegroundColor Yellow
} else {
    Write-Host "   Firewall is disabled" -ForegroundColor Green
}

Write-Host "`n=== Diagnostics Complete ===" -ForegroundColor Cyan
Write-Host "`nTo run the application with minimal configuration:" -ForegroundColor Yellow
Write-Host "cd SteelEstimation.Web" -ForegroundColor White
Write-Host 'dotnet run --urls "http://localhost:5000"' -ForegroundColor White