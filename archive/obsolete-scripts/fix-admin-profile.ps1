# Fix admin profile to prevent redirect to welcome page
Write-Host "Fixing admin profile..." -ForegroundColor Green

$connectionString = "Server=localhost;Database=SteelEstimationDb;Trusted_Connection=True;TrustServerCertificate=True;"

$updateQuery = @"
UPDATE Users 
SET FirstName = 'System',
    LastName = 'Administrator',
    CompanyName = 'Steel Estimation Platform',
    JobTitle = 'System Administrator',
    IsEmailConfirmed = 1,
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
    
    # Verify the update
    $command.CommandText = "SELECT FirstName, LastName, IsEmailConfirmed FROM Users WHERE Email = 'admin@steelestimation.com'"
    $reader = $command.ExecuteReader()
    
    if ($reader.Read()) {
        Write-Host "`nAdmin user profile:" -ForegroundColor Yellow
        Write-Host "First Name: $($reader['FirstName'])" -ForegroundColor Cyan
        Write-Host "Last Name: $($reader['LastName'])" -ForegroundColor Cyan
        Write-Host "Email Confirmed: $($reader['IsEmailConfirmed'])" -ForegroundColor Cyan
    }
    
    $reader.Close()
    $connection.Close()
    
    Write-Host "`nAdmin profile fixed!" -ForegroundColor Green
    Write-Host "Now when you login, you'll be redirected to the home page instead of the welcome page." -ForegroundColor Yellow
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}