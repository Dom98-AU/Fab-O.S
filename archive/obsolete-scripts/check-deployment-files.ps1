# Check what files were deployed
param(
    [string]$ResourceGroupName = "NWIApps",
    [string]$AppServiceName = "app-steel-estimation-prod"
)

Write-Host "Checking deployed files in App Service..." -ForegroundColor Green

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
}

# List files in wwwroot
Write-Host "`nFiles in wwwroot:" -ForegroundColor Yellow
$filesUrl = "https://$AppServiceName.scm.azurewebsites.net/api/vfs/site/wwwroot/"
try {
    $files = Invoke-RestMethod -Uri $filesUrl -Headers $headers -Method Get
    $files | ForEach-Object {
        Write-Host "  - $($_.name) ($(if($_.size) { "$($_.size) bytes" } else { "directory" }))" -ForegroundColor Gray
    }
    
    # Check if web.config exists
    $webConfigExists = $files | Where-Object { $_.name -eq "web.config" }
    if ($webConfigExists) {
        Write-Host "`nweb.config found. Content:" -ForegroundColor Yellow
        $webConfigUrl = "https://$AppServiceName.scm.azurewebsites.net/api/vfs/site/wwwroot/web.config"
        $webConfigContent = Invoke-RestMethod -Uri $webConfigUrl -Headers $headers -Method Get
        Write-Host $webConfigContent -ForegroundColor Gray
    } else {
        Write-Host "`nNo web.config found!" -ForegroundColor Red
    }
    
    # Check if main DLL exists
    $dllExists = $files | Where-Object { $_.name -eq "SteelEstimation.Web.dll" }
    if ($dllExists) {
        Write-Host "`nSteelEstimation.Web.dll found ($($dllExists.size) bytes)" -ForegroundColor Green
    } else {
        Write-Host "`nSteelEstimation.Web.dll NOT found!" -ForegroundColor Red
    }
    
} catch {
    Write-Error "Failed to access Kudu: $_"
}

Write-Host "`nYou can manually check files at:" -ForegroundColor Yellow
Write-Host "https://$AppServiceName.scm.azurewebsites.net/DebugConsole" -ForegroundColor Cyan