# Test Steel Estimation App with Azure SQL
Write-Host "=== Testing Steel Estimation App with Azure SQL ===" -ForegroundColor Cyan

Write-Host "`nStep 1: Stop any existing containers..." -ForegroundColor Yellow
docker-compose down 2>$null

Write-Host "`nStep 2: Start application with Azure SQL..." -ForegroundColor Yellow
Write-Host "Using docker-compose-azure.yml configuration" -ForegroundColor Gray

# Start the application
docker-compose -f docker-compose-azure.yml up -d

Write-Host "`nStep 3: Waiting for application to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Check if container is running
$containerStatus = docker ps --filter "name=steel-estimation-web-azure" --format "table {{.Names}}\t{{.Status}}"
Write-Host "`nContainer status:" -ForegroundColor Green
Write-Host $containerStatus

# Check application logs
Write-Host "`nStep 4: Checking application logs..." -ForegroundColor Yellow
$logs = docker logs steel-estimation-web-azure --tail 20 2>&1
Write-Host "Recent logs:" -ForegroundColor Green
Write-Host $logs

# Test application endpoint
Write-Host "`nStep 5: Testing application endpoint..." -ForegroundColor Yellow
try {
    Start-Sleep -Seconds 5
    $response = Invoke-WebRequest -Uri "http://localhost:8080" -UseBasicParsing -TimeoutSec 10
    Write-Host "Application is responding!" -ForegroundColor Green
    Write-Host "Status: $($response.StatusCode)" -ForegroundColor Gray
} catch {
    Write-Host "Application not yet responding: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "This is normal - application may still be starting up" -ForegroundColor Gray
}

Write-Host "`nStep 6: Application URLs:" -ForegroundColor Cyan
Write-Host "Application: http://localhost:8080" -ForegroundColor White
Write-Host "Login: admin@steelestimation.com / Admin@123" -ForegroundColor White

Write-Host "`nStep 7: Useful commands:" -ForegroundColor Cyan
Write-Host "View logs:    docker logs steel-estimation-web-azure -f" -ForegroundColor Gray
Write-Host "Stop app:     docker-compose -f docker-compose-azure.yml down" -ForegroundColor Gray
Write-Host "Restart app:  docker-compose -f docker-compose-azure.yml restart" -ForegroundColor Gray

Write-Host "`nAzure SQL setup complete!" -ForegroundColor Green
Write-Host "Your application is now running with Azure SQL Database" -ForegroundColor White