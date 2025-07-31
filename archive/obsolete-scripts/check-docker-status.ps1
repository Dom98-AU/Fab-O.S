# Check Docker container status
Write-Host "=== Docker Container Status ===" -ForegroundColor Cyan

Write-Host "`nChecking Docker containers..." -ForegroundColor Yellow
$containers = docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
Write-Host $containers

Write-Host "`nChecking if SQL container exists..." -ForegroundColor Yellow
$sqlContainer = docker ps -a --filter "name=steel-estimation-sql" --format "{{.Names}} - {{.Status}}"
if ($sqlContainer) {
    Write-Host "SQL Container: $sqlContainer" -ForegroundColor Green
} else {
    Write-Host "SQL Container: Not found" -ForegroundColor Red
}

Write-Host "`nDocker Summary:" -ForegroundColor Cyan
Write-Host "If SQL container is stopped/missing, that's OK!" -ForegroundColor Yellow
Write-Host "You now have Azure SQL with your data ready to use." -ForegroundColor Green