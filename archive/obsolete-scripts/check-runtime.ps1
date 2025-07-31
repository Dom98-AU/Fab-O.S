# Check and configure App Service runtime
param(
    [string]$ResourceGroupName = "NWIApps",
    [string]$AppServiceName = "app-steel-estimation-prod"
)

Write-Host "Checking App Service configuration..." -ForegroundColor Green

# Get the web app
$webapp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName

Write-Host "`nCurrent configuration:" -ForegroundColor Yellow
Write-Host "Runtime Stack: $($webapp.SiteConfig.WindowsFxVersion)" -ForegroundColor Gray
Write-Host "Net Framework Version: $($webapp.SiteConfig.NetFrameworkVersion)" -ForegroundColor Gray
Write-Host "Platform: $($webapp.Kind)" -ForegroundColor Gray

# Set the runtime stack to .NET 8
Write-Host "`nSetting runtime stack to .NET 8..." -ForegroundColor Green

$webapp.SiteConfig.NetFrameworkVersion = "v8.0"
$webapp.SiteConfig.WindowsFxVersion = "DOTNET|8.0"

# Update the web app
Set-AzWebApp -WebApp $webapp

Write-Host "Runtime stack updated to .NET 8" -ForegroundColor Green

# Also ensure 64-bit platform
Write-Host "`nEnsuring 64-bit platform..." -ForegroundColor Yellow
Set-AzWebApp -ResourceGroupName $ResourceGroupName `
             -Name $AppServiceName `
             -Use32BitWorkerProcess $false

Write-Host "Configuration updated successfully!" -ForegroundColor Green

# Restart the app
Write-Host "`nRestarting App Service..." -ForegroundColor Green
Restart-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName

Write-Host "App Service restarted. Waiting for it to come online..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check status
Write-Host "`nChecking application status..." -ForegroundColor Green
try {
    $response = Invoke-WebRequest -Uri "https://$AppServiceName.azurewebsites.net" -UseBasicParsing -TimeoutSec 10
    Write-Host "Application responded with status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "Application check failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nPlease check the Log Stream in Azure Portal for detailed error messages." -ForegroundColor Yellow
}