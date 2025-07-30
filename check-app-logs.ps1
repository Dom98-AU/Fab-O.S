# Check Azure App Service logs
param(
    [string]$ResourceGroupName = "NWIApps",
    [string]$AppServiceName = "app-steel-estimation-prod"
)

Write-Host "Checking application logs..." -ForegroundColor Green

# Get the web app
$webapp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName

Write-Host "App Service State: $($webapp.State)" -ForegroundColor Yellow
Write-Host "App Service URL: https://$($webapp.DefaultHostName)" -ForegroundColor Yellow

# Check if app is running
if ($webapp.State -ne "Running") {
    Write-Host "Starting App Service..." -ForegroundColor Yellow
    Start-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName
    Start-Sleep -Seconds 10
}

# Get recent logs using Kudu API
Write-Host "`nFetching application logs..." -ForegroundColor Green

$username = $webapp.PublishingUserName
$password = (Get-AzWebAppPublishingProfile -ResourceGroupName $ResourceGroupName -Name $AppServiceName -OutputFile "temp.xml" | Out-Null)

# Read the publishing profile to get credentials
[xml]$profile = Get-Content "temp.xml"
$username = $profile.publishData.publishProfile[0].userName
$password = $profile.publishData.publishProfile[0].userPWD
Remove-Item "temp.xml"

# Get logs from Kudu
$base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("${username}:${password}")))
$headers = @{
    Authorization = "Basic $base64Auth"
}

try {
    # Get eventlog.xml for startup errors
    $eventLogUrl = "https://$AppServiceName.scm.azurewebsites.net/api/vfs/LogFiles/eventlog.xml"
    $response = Invoke-RestMethod -Uri $eventLogUrl -Headers $headers -Method Get
    Write-Host "`nEvent Log entries:" -ForegroundColor Yellow
    Write-Host $response -ForegroundColor Gray
} catch {
    Write-Host "Could not retrieve event log" -ForegroundColor Red
}

try {
    # Get application logs
    $logUrl = "https://$AppServiceName.scm.azurewebsites.net/api/logs/application"
    $logs = Invoke-RestMethod -Uri $logUrl -Headers $headers -Method Get
    
    if ($logs) {
        Write-Host "`nApplication Logs:" -ForegroundColor Yellow
        foreach ($log in $logs[-10..-1]) {  # Last 10 entries
            Write-Host $log -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "Could not retrieve application logs" -ForegroundColor Red
}

# Check configuration
Write-Host "`nChecking App Service Configuration..." -ForegroundColor Green
$appSettings = (Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName).SiteConfig.AppSettings

Write-Host "`nApplication Settings:" -ForegroundColor Yellow
$appSettings | ForEach-Object {
    if ($_.Name -notlike "*SECRET*" -and $_.Name -notlike "*KEY*" -and $_.Name -notlike "*PASSWORD*") {
        Write-Host "$($_.Name): $($_.Value)" -ForegroundColor Gray
    } else {
        Write-Host "$($_.Name): [HIDDEN]" -ForegroundColor Gray
    }
}

# Check connection strings
$connStrings = (Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName).SiteConfig.ConnectionStrings
if ($connStrings) {
    Write-Host "`nConnection Strings:" -ForegroundColor Yellow
    $connStrings | ForEach-Object {
        Write-Host "$($_.Name): [Configured]" -ForegroundColor Gray
    }
}

Write-Host "`nFor more detailed logs, check the Azure Portal:" -ForegroundColor Yellow
Write-Host "1. Go to your App Service in Azure Portal" -ForegroundColor White
Write-Host "2. Navigate to 'Diagnose and solve problems'" -ForegroundColor White
Write-Host "3. Or go to 'Log stream' under Monitoring" -ForegroundColor White