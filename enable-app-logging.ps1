# Enable Application Logging for Azure App Service
param(
    [string]$ResourceGroupName = "NWIApps",
    [string]$AppServiceName = "app-steel-estimation-prod"
)

Write-Host "Enabling application logging for $AppServiceName..." -ForegroundColor Green

# Enable application logging
$webapp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName

# Configure logging
$webapp.SiteConfig.HttpLoggingEnabled = $true
$webapp.SiteConfig.DetailedErrorLoggingEnabled = $true
$webapp.SiteConfig.RequestTracingEnabled = $true

# Set the web app configuration
Set-AzWebApp -WebApp $webapp

# Enable file system logging
Set-AzWebAppDiagnosticLog -ResourceGroupName $ResourceGroupName `
                          -Name $AppServiceName `
                          -ApplicationLogging `
                          -LogLevel Information `
                          -StorageLevel Filesystem

Write-Host "Application logging enabled!" -ForegroundColor Green
Write-Host "Log Level: Information" -ForegroundColor Yellow
Write-Host "Storage: File System" -ForegroundColor Yellow

Write-Host "`nRestarting App Service to apply changes..." -ForegroundColor Green
Restart-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName

Write-Host "`nLogging has been enabled. You can now:" -ForegroundColor Green
Write-Host "1. Go to Azure Portal > Your App Service > Log stream" -ForegroundColor White
Write-Host "2. Or use this PowerShell to view logs:" -ForegroundColor White
Write-Host "   Get-AzWebAppLog -ResourceGroupName $ResourceGroupName -Name $AppServiceName -Tail" -ForegroundColor Cyan

Write-Host "`nWaiting 30 seconds for app to restart..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host "`nFetching recent logs..." -ForegroundColor Green
try {
    # Try to get logs using Kudu API
    $webapp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName
    
    # Get publishing credentials
    $creds = Invoke-AzResourceAction -ResourceGroupName $ResourceGroupName `
                                     -ResourceType Microsoft.Web/sites/config `
                                     -ResourceName "$AppServiceName/publishingcredentials" `
                                     -Action list `
                                     -ApiVersion 2015-08-01 `
                                     -Force
    
    $username = $creds.Properties.PublishingUserName
    $password = $creds.Properties.PublishingPassword
    
    # Build auth header
    $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("${username}:${password}")))
    $headers = @{
        Authorization = "Basic $base64Auth"
    }
    
    # Get log files
    $logUrl = "https://$AppServiceName.scm.azurewebsites.net/api/logs/application"
    $response = Invoke-RestMethod -Uri $logUrl -Headers $headers -Method Get
    
    if ($response) {
        Write-Host "`nRecent application logs:" -ForegroundColor Yellow
        $response | Select-Object -Last 20 | ForEach-Object { Write-Host $_ }
    }
} catch {
    Write-Host "Could not retrieve logs via API. Please check in Azure Portal." -ForegroundColor Yellow
}