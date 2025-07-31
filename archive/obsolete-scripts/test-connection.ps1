# Test network connectivity
Write-Host "Testing network connectivity..." -ForegroundColor Green

# Test localhost resolution
Write-Host "`n1. Testing localhost resolution..." -ForegroundColor Yellow
$localhostIP = [System.Net.Dns]::GetHostAddresses("localhost")
Write-Host "   Localhost resolves to: $($localhostIP.IPAddressToString)" -ForegroundColor Cyan

# Test 127.0.0.1
Write-Host "`n2. Testing 127.0.0.1..." -ForegroundColor Yellow
Test-NetConnection -ComputerName 127.0.0.1 -Port 5000 -WarningAction SilentlyContinue | Out-Null
Write-Host "   127.0.0.1 is reachable" -ForegroundColor Green

# Check if application is listening
Write-Host "`n3. Checking listening ports..." -ForegroundColor Yellow
$listening = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Where-Object {$_.LocalPort -in @(5000, 5001)}
if ($listening) {
    $listening | ForEach-Object {
        Write-Host "   Port $($_.LocalPort) is listening on $($_.LocalAddress)" -ForegroundColor Green
    }
} else {
    Write-Host "   No application listening on ports 5000/5001" -ForegroundColor Red
}

# Test with curl
Write-Host "`n4. Testing with curl..." -ForegroundColor Yellow
$response = curl.exe -s -o /dev/null -w "%{http_code}" http://127.0.0.1:5000 2>$null
if ($response) {
    Write-Host "   HTTP Response Code: $response" -ForegroundColor Cyan
} else {
    Write-Host "   Could not connect with curl" -ForegroundColor Red
}

Write-Host "`n=== Recommendations ===" -ForegroundColor Cyan
Write-Host "Try accessing the application using:" -ForegroundColor Yellow
Write-Host "- http://127.0.0.1:5000" -ForegroundColor White
Write-Host "- http://[::1]:5000 (IPv6)" -ForegroundColor White
Write-Host "- Use Microsoft Edge instead of Firefox" -ForegroundColor White