# Fix admin password with correct format
Write-Host "Fixing admin password..." -ForegroundColor Green

Add-Type -AssemblyName System.Security.Cryptography

$password = "Admin@123"
$saltBytes = [System.Convert]::FromBase64String("4X8vHZLKVDiNPBDzPuKMBg==")

# Generate hash with 100,000 iterations (not 10,000)
$iterations = 100000
$hashBytes = [System.Security.Cryptography.Rfc2898DeriveBytes]::new($password, $saltBytes, $iterations, [System.Security.Cryptography.HashAlgorithmName]::SHA256).GetBytes(32)
$hash = [System.Convert]::ToBase64String($hashBytes)

# Combine salt and hash with dot separator
$fullHash = "4X8vHZLKVDiNPBDzPuKMBg==.$hash"

Write-Host "Generated password hash: $fullHash" -ForegroundColor Cyan

# Update in database
$connectionString = "Server=localhost;Database=SteelEstimationDb;Trusted_Connection=True;TrustServerCertificate=True;"

$updateQuery = @"
UPDATE Users 
SET PasswordHash = '$fullHash',
    FailedLoginAttempts = 0,
    LockedOutUntil = NULL,
    LastModified = GETUTCDATE()
WHERE Email = 'admin@steelestimation.com'
"@

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()
    
    $command = $connection.CreateCommand()
    $command.CommandText = $updateQuery
    $rowsAffected = $command.ExecuteNonQuery()
    
    Write-Host "Updated $rowsAffected user(s)" -ForegroundColor Green
    
    $connection.Close()
    
    Write-Host "`nAdmin password fixed!" -ForegroundColor Green
    Write-Host "You can now login with:" -ForegroundColor Yellow
    Write-Host "Email: admin@steelestimation.com" -ForegroundColor White
    Write-Host "Password: Admin@123" -ForegroundColor White
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}