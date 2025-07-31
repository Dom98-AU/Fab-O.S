# PowerShell script to generate password hash for the application
param(
    [string]$Password = "Admin@123"
)

Add-Type -AssemblyName System.Security.Cryptography

# Generate a 128-bit salt
$salt = New-Object byte[] 16
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($salt)

# Convert password to bytes
$passwordBytes = [System.Text.Encoding]::UTF8.GetBytes($Password)

# Generate hash using PBKDF2
$iterations = 100000
$hashBytes = New-Object byte[] 32

$pbkdf2 = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($passwordBytes, $salt, $iterations, [System.Security.Cryptography.HashAlgorithmName]::SHA256)
$hashBytes = $pbkdf2.GetBytes(32)

# Convert to base64 and combine
$saltBase64 = [Convert]::ToBase64String($salt)
$hashBase64 = [Convert]::ToBase64String($hashBytes)
$finalHash = "$saltBase64.$hashBase64"

Write-Host "Password: $Password" -ForegroundColor Green
Write-Host "Hash: $finalHash" -ForegroundColor Cyan
Write-Host "`nSQL to update admin password:" -ForegroundColor Yellow
Write-Host @"
UPDATE Users 
SET PasswordHash = '$finalHash',
    LastModified = GETUTCDATE()
WHERE Email = 'admin@steelestimation.com';
"@ -ForegroundColor Gray