# Kill any running dotnet processes

Write-Host "Checking for running dotnet processes..." -ForegroundColor Yellow

$dotnetProcesses = Get-Process | Where-Object { $_.ProcessName -like "dotnet" -or $_.ProcessName -like "SteelEstimation*" }

if ($dotnetProcesses) {
    Write-Host "Found the following processes:" -ForegroundColor Cyan
    $dotnetProcesses | ForEach-Object {
        Write-Host "  - $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Stopping processes..." -ForegroundColor Yellow
    
    $dotnetProcesses | ForEach-Object {
        try {
            Stop-Process -Id $_.Id -Force
            Write-Host "  Stopped process $($_.Id)" -ForegroundColor Green
        }
        catch {
            Write-Host "  Failed to stop process $($_.Id): $_" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "All dotnet processes have been terminated." -ForegroundColor Green
}
else {
    Write-Host "No running dotnet processes found." -ForegroundColor Green
}

# Check if port 5003 is still in use
Write-Host ""
Write-Host "Checking if port 5003 is still in use..." -ForegroundColor Yellow

$port5003 = Get-NetTCPConnection -LocalPort 5003 -ErrorAction SilentlyContinue

if ($port5003) {
    Write-Host "Port 5003 is still in use by process:" -ForegroundColor Red
    $port5003 | ForEach-Object {
        $process = Get-Process -Id $_.OwningProcess
        Write-Host "  - $($process.ProcessName) (PID: $($_.OwningProcess))" -ForegroundColor White
    }
}
else {
    Write-Host "Port 5003 is free." -ForegroundColor Green
}