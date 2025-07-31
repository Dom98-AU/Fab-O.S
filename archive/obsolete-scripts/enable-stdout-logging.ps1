# Enable stdout logging in deployed web.config
param(
    [string]$ResourceGroupName = "NWIApps",
    [string]$AppServiceName = "app-steel-estimation-prod"
)

Write-Host "Enabling stdout logging..." -ForegroundColor Green

# Get publishing credentials
$webapp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName
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
    "Content-Type" = "application/xml"
}

# New web.config with stdout logging enabled
$newWebConfig = @'
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <location path="." inheritInChildApplications="false">
    <system.webServer>
      <handlers>
        <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
      </handlers>
      <aspNetCore processPath="dotnet" arguments=".\SteelEstimation.Web.dll" stdoutLogEnabled="true" stdoutLogFile="\\?\%home%\LogFiles\stdout" hostingModel="OutOfProcess">
        <environmentVariables>
          <environmentVariable name="ASPNETCORE_ENVIRONMENT" value="Production" />
          <environmentVariable name="ASPNETCORE_DETAILEDERRORS" value="true" />
        </environmentVariables>
      </aspNetCore>
    </system.webServer>
  </location>
</configuration>
'@

# Update web.config via Kudu
$webConfigUrl = "https://$AppServiceName.scm.azurewebsites.net/api/vfs/site/wwwroot/web.config"
try {
    $response = Invoke-RestMethod -Uri $webConfigUrl `
                                  -Headers $headers `
                                  -Method PUT `
                                  -Body $newWebConfig
    
    Write-Host "web.config updated with stdout logging enabled" -ForegroundColor Green
    
    # Restart the app
    Write-Host "`nRestarting App Service..." -ForegroundColor Yellow
    Restart-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName
    
    Write-Host "`nWaiting 30 seconds for app to restart..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    # Try to access the app to generate logs
    Write-Host "`nAccessing app to generate logs..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri "https://$AppServiceName.azurewebsites.net" -UseBasicParsing -TimeoutSec 10
    } catch {
        Write-Host "App returned error (expected)" -ForegroundColor Gray
    }
    
    Write-Host "`nNow check the Log Stream in Azure Portal for stdout logs" -ForegroundColor Green
    Write-Host "Or access: https://$AppServiceName.scm.azurewebsites.net/DebugConsole" -ForegroundColor Cyan
    Write-Host "Navigate to: LogFiles folder and look for stdout*.log files" -ForegroundColor Yellow
    
} catch {
    Write-Error "Failed to update web.config: $_"
}