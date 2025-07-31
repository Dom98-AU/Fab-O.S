# Quick script to seed admin user using .NET SqlClient
Write-Host "Seeding admin user..." -ForegroundColor Yellow

$connectionString = "Server=localhost;Database=SteelEstimationDb;Trusted_Connection=True;TrustServerCertificate=True;"

# Read the SQL script
$sqlScript = Get-Content -Path "$PSScriptRoot\seed-fixed.sql" -Raw

# Execute using .NET SqlClient
try {
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()
    
    # Split by GO statements and execute each batch
    $sqlScript -split '\bGO\b' | ForEach-Object {
        $batch = $_.Trim()
        if ($batch -ne "") {
            $command = $connection.CreateCommand()
            $command.CommandText = $batch
            $command.ExecuteNonQuery() | Out-Null
        }
    }
    
    $connection.Close()
    Write-Host "Admin user seeded successfully!" -ForegroundColor Green
    Write-Host "Email: admin@steelestimation.com" -ForegroundColor Cyan
    Write-Host "Password: Admin@123" -ForegroundColor Cyan
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}