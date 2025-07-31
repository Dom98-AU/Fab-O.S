# Check Projects table data

$ErrorActionPreference = "Stop"

Write-Host "Checking Projects table..." -ForegroundColor Green

$connectionString = "Server=localhost;Database=SteelEstimationDb;Trusted_Connection=True;TrustServerCertificate=True;"

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    # Count projects
    $command = $connection.CreateCommand()
    $command.CommandText = "SELECT COUNT(*) as Total FROM Projects"
    $count = $command.ExecuteScalar()
    
    Write-Host ""
    Write-Host "Total Projects: $count" -ForegroundColor Cyan
    
    # Get recent projects
    $command.CommandText = @"
SELECT TOP 10 
    Id,
    ProjectName,
    JobNumber,
    CustomerId,
    EstimationStage,
    CreatedDate,
    IsDeleted
FROM Projects
ORDER BY CreatedDate DESC
"@
    
    $reader = $command.ExecuteReader()
    
    Write-Host ""
    Write-Host "Recent Projects:" -ForegroundColor Yellow
    Write-Host "----------------" -ForegroundColor Yellow
    
    $hasData = $false
    while ($reader.Read()) {
        $hasData = $true
        $id = $reader["Id"]
        $name = $reader["ProjectName"]
        $jobNumber = $reader["JobNumber"]
        $customerId = if ($reader["CustomerId"] -eq [DBNull]::Value) { "NULL" } else { $reader["CustomerId"] }
        $stage = $reader["EstimationStage"]
        $created = $reader["CreatedDate"]
        $isDeleted = $reader["IsDeleted"]
        
        Write-Host "ID: $id | Name: $name | Job#: $jobNumber | Customer: $customerId | Stage: $stage | Created: $created | Deleted: $isDeleted" -ForegroundColor White
    }
    
    if (-not $hasData) {
        Write-Host "No projects found in the database." -ForegroundColor Red
    }
    
    $reader.Close()
    
    # Check for deleted projects
    $command.CommandText = "SELECT COUNT(*) FROM Projects WHERE IsDeleted = 1"
    $deletedCount = $command.ExecuteScalar()
    
    Write-Host ""
    Write-Host "Deleted Projects: $deletedCount" -ForegroundColor Yellow
    
    $connection.Close()
}
catch {
    Write-Error "Failed to check projects: $($_.Exception.Message)"
    exit 1
}