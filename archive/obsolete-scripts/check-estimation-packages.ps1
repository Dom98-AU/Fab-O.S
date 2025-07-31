# Check packages for a specific estimation

$ErrorActionPreference = "Stop"

Write-Host "Checking packages for estimation..." -ForegroundColor Green

$connectionString = "Server=localhost;Database=SteelEstimationDb_CloudDev;Trusted_Connection=True;TrustServerCertificate=True;"

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    # Get estimation details
    $command = $connection.CreateCommand()
    $command.CommandText = @"
SELECT Id, ProjectName, JobNumber 
FROM Projects 
WHERE Id = 3
"@
    
    $reader = $command.ExecuteReader()
    
    if ($reader.Read()) {
        $projectName = $reader["ProjectName"]
        $jobNumber = $reader["JobNumber"]
        Write-Host ""
        Write-Host "Estimation 3: $projectName (Job: $jobNumber)" -ForegroundColor Cyan
    }
    
    $reader.Close()
    
    # Get packages for this estimation
    $command.CommandText = @"
SELECT Id, PackageName, ProjectId 
FROM Packages 
WHERE ProjectId = 3
ORDER BY Id
"@
    
    $reader = $command.ExecuteReader()
    
    Write-Host ""
    Write-Host "Packages for this estimation:" -ForegroundColor Yellow
    Write-Host "----------------------------" -ForegroundColor Yellow
    
    $hasPackages = $false
    while ($reader.Read()) {
        $hasPackages = $true
        $packageId = $reader["Id"]
        $packageName = $reader["PackageName"]
        
        Write-Host "Package ID: $packageId - $packageName" -ForegroundColor White
        Write-Host "  URL: /estimation/3/package/$packageId/worksheets" -ForegroundColor Green
    }
    
    if (-not $hasPackages) {
        Write-Host "No packages found for this estimation!" -ForegroundColor Red
    }
    
    $reader.Close()
    $connection.Close()
}
catch {
    Write-Error "Failed to check packages: $($_.Exception.Message)"
    exit 1
}