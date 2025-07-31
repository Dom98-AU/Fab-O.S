# PowerShell script to check staging logs and diagnose issues
param(
    [int]$WaitSeconds = 60
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Checking Staging Application Status" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

# Check if Azure CLI is installed
$azInstalled = Get-Command az -ErrorAction SilentlyContinue
if (-not $azInstalled) {
    Write-Host "Azure CLI not installed. Checking via PowerShell..." -ForegroundColor Yellow
    
    # Try to get logs via PowerShell
    try {
        $logs = Get-AzWebAppSlotWebDeploymentLog -ResourceGroupName "NWIApps" `
                                                  -Name "app-steel-estimation-prod" `
                                                  -Slot "staging" `
                                                  -ErrorAction Stop
        Write-Host "Recent deployment logs:" -ForegroundColor Cyan
        $logs | Format-List
    } catch {
        Write-Host "Could not retrieve logs via PowerShell" -ForegroundColor Red
    }
    
    Write-Host "`nPlease check logs in Azure Portal:" -ForegroundColor Yellow
    Write-Host "1. Go to Azure Portal" -ForegroundColor White
    Write-Host "2. Navigate to app-steel-estimation-prod" -ForegroundColor White
    Write-Host "3. Go to Deployment slots > staging" -ForegroundColor White
    Write-Host "4. Check 'Log stream' or 'Diagnose and solve problems'" -ForegroundColor White
    
} else {
    Write-Host "Streaming logs for $WaitSeconds seconds..." -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop early" -ForegroundColor Gray
    
    # Stream logs using Azure CLI
    $process = Start-Process -FilePath "az" `
                            -ArgumentList "webapp log tail --name app-steel-estimation-prod --slot staging --resource-group NWIApps" `
                            -PassThru `
                            -NoNewWindow
    
    Start-Sleep -Seconds $WaitSeconds
    
    if (-not $process.HasExited) {
        $process.Kill()
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Common 503 Error Causes:" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "1. Database connection failure" -ForegroundColor White
Write-Host "   - Check connection string in App Service Configuration" -ForegroundColor Gray
Write-Host "   - Verify Managed Identity permissions" -ForegroundColor Gray
Write-Host "`n2. Missing configuration" -ForegroundColor White
Write-Host "   - Check ASPNETCORE_ENVIRONMENT is set to 'Staging'" -ForegroundColor Gray
Write-Host "   - Verify all required app settings are configured" -ForegroundColor Gray
Write-Host "`n3. Startup errors" -ForegroundColor White
Write-Host "   - Missing assemblies or dependencies" -ForegroundColor Gray
Write-Host "   - Errors in Program.cs during startup" -ForegroundColor Gray
Write-Host "`n4. Migration failures" -ForegroundColor White
Write-Host "   - Database migration errors on startup" -ForegroundColor Gray
Write-Host "   - Permission issues for Managed Identity" -ForegroundColor Gray

# Test if the app is responding now
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testing application status..." -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

$stagingUrl = "https://app-steel-estimation-prod-staging.azurewebsites.net"
$maxRetries = 3
$retryDelay = 10

for ($i = 1; $i -le $maxRetries; $i++) {
    Write-Host "`nAttempt $i of $maxRetries..." -ForegroundColor Yellow
    
    try {
        $response = Invoke-WebRequest -Uri $stagingUrl -UseBasicParsing -TimeoutSec 30
        Write-Host "Success! Application is responding with status: $($response.StatusCode)" -ForegroundColor Green
        break
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "Failed with status: $statusCode - $($_.Exception.Message)" -ForegroundColor Red
        
        if ($i -lt $maxRetries) {
            Write-Host "Waiting $retryDelay seconds before retry..." -ForegroundColor Gray
            Start-Sleep -Seconds $retryDelay
        }
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Diagnostic Steps:" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "1. Check Kudu console:" -ForegroundColor White
Write-Host "   https://app-steel-estimation-prod-staging.scm.azurewebsites.net" -ForegroundColor Cyan
Write-Host "   - Go to Debug Console > CMD" -ForegroundColor Gray
Write-Host "   - Navigate to LogFiles folder" -ForegroundColor Gray
Write-Host "   - Check eventlog.xml for startup errors" -ForegroundColor Gray
Write-Host "`n2. Check Application Insights (if configured)" -ForegroundColor White
Write-Host "`n3. Verify database connectivity:" -ForegroundColor White
Write-Host "   - Run the verify-staging-database.ps1 script" -ForegroundColor Gray
Write-Host "`n4. Check environment variables in Kudu:" -ForegroundColor White
Write-Host "   - Go to Environment tab in Kudu" -ForegroundColor Gray
Write-Host "   - Verify ASPNETCORE_ENVIRONMENT = Staging" -ForegroundColor Gray