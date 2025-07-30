# Import SQL data into Docker SQL Server
param(
    [string]$SqlFile = ".\docker\sql\exported-data.sql",
    [string]$ContainerName = "steel-estimation-sql",
    [string]$Password = "YourStrong@Password123"
)

Write-Host "Importing data into Docker SQL Server..." -ForegroundColor Green

# Check if file exists
if (-not (Test-Path $SqlFile)) {
    Write-Host "SQL file not found: $SqlFile" -ForegroundColor Red
    Write-Host "Please run .\export-for-docker.ps1 first to export your data." -ForegroundColor Yellow
    exit 1
}

# Check if container is running
$containerStatus = docker ps --filter "name=$ContainerName" --format "{{.Status}}"
if (-not $containerStatus) {
    Write-Host "Container '$ContainerName' is not running." -ForegroundColor Red
    Write-Host "Please run 'docker-compose up -d' first." -ForegroundColor Yellow
    exit 1
}

Write-Host "Container status: $containerStatus" -ForegroundColor Gray

# Copy SQL file into container
Write-Host "Copying SQL file to container..." -ForegroundColor Cyan
docker cp $SqlFile "${ContainerName}:/tmp/import.sql"

# Import the data
Write-Host "Importing data (this may take a few minutes)..." -ForegroundColor Cyan
$importCommand = @"
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P '$Password' -C -i /tmp/import.sql
"@

docker exec $ContainerName bash -c $importCommand

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nData import completed successfully!" -ForegroundColor Green
    
    # Clean up
    docker exec $ContainerName rm /tmp/import.sql
    
    # Show some statistics
    Write-Host "`nVerifying import..." -ForegroundColor Cyan
    $verifyCommand = @"
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P '$Password' -C -Q "
SELECT 
    t.name AS TableName,
    p.rows AS RecordCount
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
WHERE i.index_id <= 1
GROUP BY t.name, p.rows
HAVING p.rows > 0
ORDER BY t.name
"
"@
    
    docker exec $ContainerName bash -c $verifyCommand
    
    Write-Host "`nYou can now access your application at: http://localhost:8080" -ForegroundColor Green
} else {
    Write-Host "`nError during import. Check the logs above for details." -ForegroundColor Red
}