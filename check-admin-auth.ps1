# Check admin user authentication details
Write-Host "Checking admin user in database..." -ForegroundColor Green

$connectionString = "Server=localhost;Database=SteelEstimationDb;Trusted_Connection=True;TrustServerCertificate=True;"

$query = @"
SELECT 
    Id,
    Username,
    Email,
    PasswordHash,
    SecurityStamp,
    IsActive,
    IsEmailConfirmed,
    FailedLoginAttempts,
    LockedOutUntil
FROM Users 
WHERE Email = 'admin@steelestimation.com'
"@

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()
    
    $command = $connection.CreateCommand()
    $command.CommandText = $query
    
    $reader = $command.ExecuteReader()
    
    if ($reader.Read()) {
        Write-Host "`nAdmin User Found:" -ForegroundColor Yellow
        Write-Host "ID: $($reader['Id'])" -ForegroundColor Cyan
        Write-Host "Username: $($reader['Username'])" -ForegroundColor Cyan
        Write-Host "Email: $($reader['Email'])" -ForegroundColor Cyan
        Write-Host "Password Hash: $($reader['PasswordHash'])" -ForegroundColor Cyan
        Write-Host "Security Stamp: $($reader['SecurityStamp'])" -ForegroundColor Cyan
        Write-Host "Is Active: $($reader['IsActive'])" -ForegroundColor Cyan
        Write-Host "Email Confirmed: $($reader['IsEmailConfirmed'])" -ForegroundColor Cyan
        Write-Host "Failed Login Attempts: $($reader['FailedLoginAttempts'])" -ForegroundColor Cyan
        Write-Host "Locked Out Until: $($reader['LockedOutUntil'])" -ForegroundColor Cyan
    } else {
        Write-Host "Admin user not found!" -ForegroundColor Red
    }
    
    $reader.Close()
    $connection.Close()
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}