# Check what data exists in Docker SQL Server
Write-Host "=== Checking Docker Database Data ===" -ForegroundColor Cyan

# Check if Docker container is running
$dockerRunning = docker ps --filter "name=steel-estimation-sql" --format "{{.Names}}"
if (-not $dockerRunning) {
    Write-Host "Warning: Docker SQL container not running. Starting it..." -ForegroundColor Yellow
    docker-compose up -d sql-server
    Start-Sleep -Seconds 10
}

Write-Host "`nChecking data in Docker SQL Server..." -ForegroundColor Yellow

# Check each table for data
$tables = @("Companies", "AspNetUsers", "Projects", "Estimations", "Packages", "ProcessingItems", "WeldingItems", "Customers")

foreach ($table in $tables) {
    try {
        $count = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Password123' -C -d SteelEstimationDB -Q "SELECT COUNT(*) FROM [$table]" -h -1 2>$null
        
        if ($count -and $count.Trim() -ne "" -and [int]$count.Trim() -gt 0) {
            Write-Host "  $table`: $($count.Trim()) records" -ForegroundColor Green
            
            # Show sample data for important tables
            if ($table -eq "Projects" -and [int]$count.Trim() -gt 0) {
                $sampleProjects = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Password123' -C -d SteelEstimationDB -Q "SELECT TOP 3 ProjectNumber, Name FROM [$table]" 2>$null
                Write-Host "    Sample projects:" -ForegroundColor Gray
                Write-Host "    $sampleProjects" -ForegroundColor Gray
            }
            
            if ($table -eq "Estimations" -and [int]$count.Trim() -gt 0) {
                $sampleEstimations = docker exec steel-estimation-sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P 'YourStrong@Password123' -C -d SteelEstimationDB -Q "SELECT TOP 3 EstimationNumber, Name FROM [$table]" 2>$null
                Write-Host "    Sample estimations:" -ForegroundColor Gray  
                Write-Host "    $sampleEstimations" -ForegroundColor Gray
            }
        } else {
            Write-Host "  $table`: 0 records" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  $table`: Could not check" -ForegroundColor Red
    }
}

Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "Azure SQL has essential tables and basic data for app to work" -ForegroundColor Green
Write-Host "If Docker has actual project data, we can migrate it separately" -ForegroundColor Yellow
Write-Host "`nNext steps:" -ForegroundColor White
Write-Host "1. Test the app with Azure SQL first: .\test-azure-app.ps1" -ForegroundColor Gray
Write-Host "2. If you have important data in Docker, we can migrate it" -ForegroundColor Gray