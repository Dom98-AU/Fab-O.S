#!/usr/bin/env pwsh
# Quick Docker rebuild script for Steel Estimation Platform
# Use this when you need a full rebuild (new packages, Docker config changes, etc.)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Steel Estimation Docker Rebuild" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Stop and remove containers
Write-Host "Stopping containers..." -ForegroundColor Yellow
docker-compose down

# Optional: Clean up dangling images to save space
Write-Host "Cleaning up dangling images..." -ForegroundColor Yellow
docker image prune -f

# Build fresh without cache
Write-Host "Building fresh container (no cache)..." -ForegroundColor Yellow
docker-compose build --no-cache

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed! Check the error messages above." -ForegroundColor Red
    exit 1
}

# Start containers
Write-Host "Starting containers..." -ForegroundColor Yellow
docker-compose up -d

# Wait a moment for container to be ready
Write-Host "Waiting for container to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Check if container is running
$containerStatus = docker ps --filter "name=steel-estimation-web-dev" --format "{{.Status}}"
if ($containerStatus -like "*Up*") {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " Rebuild Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Application is running at:" -ForegroundColor Green
    Write-Host "  http://localhost:8080" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Login with:" -ForegroundColor Green
    Write-Host "  Email: admin@steelestimation.com" -ForegroundColor Cyan
    Write-Host "  Password: Admin@123" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "View logs with: docker-compose logs -f web" -ForegroundColor Gray
} else {
    Write-Host ""
    Write-Host "Warning: Container may not have started properly." -ForegroundColor Yellow
    Write-Host "Check logs with: docker-compose logs web" -ForegroundColor Yellow
}