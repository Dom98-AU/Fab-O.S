# Get stdout logs from Kudu
param(
    [string]$ResourceGroupName = "NWIApps",
    [string]$AppServiceName = "app-steel-estimation-prod"
)

Write-Host "Fetching stdout logs from App Service..." -ForegroundColor Green

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

# List files in LogFiles directory
Write-Host "`nChecking for log files..." -ForegroundColor Yellow
$listUrl = "https://$AppServiceName.scm.azurewebsites.net/api/vfs/LogFiles/"
try {
    $files = Invoke-RestMethod -Uri $listUrl -Headers $headers -Method Get
    
    Write-Host "`nAvailable log files:" -ForegroundColor Green
    $files | Where-Object { $_.name -like "*.log" -or $_.name -like "stdout*" } | ForEach-Object {
        Write-Host "  - $($_.name)" -ForegroundColor Gray
    }
    
    # Get stdout logs
    $stdoutLogs = $files | Where-Object { $_.name -like "stdout*" }
    
    if ($stdoutLogs) {
        Write-Host "`nFetching stdout logs..." -ForegroundColor Yellow
        foreach ($log in $stdoutLogs | Select-Object -Last 3) {
            $logUrl = "https://$AppServiceName.scm.azurewebsites.net/api/vfs/LogFiles/$($log.name)"
            Write-Host "`nContent of $($log.name):" -ForegroundColor Cyan
            try {
                $content = Invoke-RestMethod -Uri $logUrl -Headers $headers -Method Get
                Write-Host $content -ForegroundColor Gray
            } catch {
                Write-Host "Could not read $($log.name)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "`nNo stdout logs found. Checking application event log..." -ForegroundColor Yellow
        
        # Try to get eventlog.xml
        $eventLogUrl = "https://$AppServiceName.scm.azurewebsites.net/api/vfs/LogFiles/eventlog.xml"
        try {
            $eventLog = Invoke-RestMethod -Uri $eventLogUrl -Headers $headers -Method Get
            Write-Host "`nEvent log content:" -ForegroundColor Cyan
            
            # Parse XML and show recent errors
            [xml]$xml = $eventLog
            $events = $xml.Events.Event | Where-Object { $_.Level -eq "Error" } | Select-Object -Last 5
            
            foreach ($event in $events) {
                Write-Host "`nTime: $($event.TimeCreated)" -ForegroundColor Yellow
                Write-Host "Provider: $($event.Provider)" -ForegroundColor Gray
                Write-Host "Message: $($event.Data)" -ForegroundColor Gray
            }
        } catch {
            Write-Host "Could not read event log" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "Error accessing log files: $_" -ForegroundColor Red
}

Write-Host "`nYou can also access logs directly via Kudu:" -ForegroundColor Green
Write-Host "https://$AppServiceName.scm.azurewebsites.net/DebugConsole" -ForegroundColor Cyan
Write-Host "Navigate to: LogFiles folder" -ForegroundColor Yellow