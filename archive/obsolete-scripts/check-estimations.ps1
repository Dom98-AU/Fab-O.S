# Check Estimations table data

$ErrorActionPreference = "Stop"

Write-Host "Checking Estimations table..." -ForegroundColor Green

$connectionString = "Server=localhost;Database=SteelEstimationDb;Trusted_Connection=True;TrustServerCertificate=True;"

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    # Count estimations
    $command = $connection.CreateCommand()
    $command.CommandText = "SELECT COUNT(*) as Total FROM Estimations"
    $count = $command.ExecuteScalar()
    
    Write-Host ""
    Write-Host "Total Estimations: $count" -ForegroundColor Cyan
    
    # Get recent estimations
    $command.CommandText = @"
SELECT TOP 10 
    Id,
    EstimationNumber,
    EstimationName,
    CompanyId,
    CreatedDate,
    Status
FROM Estimations
ORDER BY CreatedDate DESC
"@
    
    $reader = $command.ExecuteReader()
    
    Write-Host ""
    Write-Host "Recent Estimations:" -ForegroundColor Yellow
    Write-Host "-------------------" -ForegroundColor Yellow
    
    $hasData = $false
    while ($reader.Read()) {
        $hasData = $true
        $id = $reader["Id"]
        $number = $reader["EstimationNumber"]
        $name = $reader["EstimationName"]
        $companyId = $reader["CompanyId"]
        $created = $reader["CreatedDate"]
        $status = $reader["Status"]
        
        Write-Host "ID: $id | Number: $number | Name: $name | Company: $companyId | Created: $created | Status: $status" -ForegroundColor White
    }
    
    if (-not $hasData) {
        Write-Host "No estimations found in the database." -ForegroundColor Red
    }
    
    $reader.Close()
    
    # Check if there's a backup or if data was moved
    $command.CommandText = @"
SELECT 
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE '%Estimation%'
ORDER BY TABLE_NAME
"@
    
    $reader = $command.ExecuteReader()
    
    Write-Host ""
    Write-Host "All tables containing 'Estimation':" -ForegroundColor Yellow
    Write-Host "-----------------------------------" -ForegroundColor Yellow
    
    while ($reader.Read()) {
        $tableName = $reader["TABLE_NAME"]
        Write-Host $tableName -ForegroundColor White
    }
    
    $reader.Close()
    $connection.Close()
}
catch {
    Write-Error "Failed to check estimations: $_"
    exit 1
}