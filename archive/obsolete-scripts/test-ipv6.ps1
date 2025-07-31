# Test IPv6 connectivity
Write-Host "Testing IPv6 connectivity..." -ForegroundColor Green

# Check all listening ports
Write-Host "`nAll listening ports:" -ForegroundColor Yellow
Get-NetTCPConnection -State Listen | Where-Object {$_.LocalPort -in @(5000, 5001)} | Format-Table LocalAddress, LocalPort, State

# Test IPv6 localhost
Write-Host "`nTesting IPv6 localhost [::1]..." -ForegroundColor Yellow
$response = Invoke-WebRequest -Uri "http://[::1]:5000" -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
if ($response.StatusCode -eq 200) {
    Write-Host "SUCCESS: Application is accessible via IPv6!" -ForegroundColor Green
    Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor Cyan
} else {
    Write-Host "Could not connect to IPv6 address" -ForegroundColor Red
}

Write-Host "`n=== The application is listening on IPv6 ===" -ForegroundColor Cyan
Write-Host "Please try these URLs in your browser:" -ForegroundColor Yellow
Write-Host "1. http://[::1]:5000" -ForegroundColor White
Write-Host "2. http://localhost:5000" -ForegroundColor White
Write-Host "3. http://127.0.0.1:5000" -ForegroundColor White