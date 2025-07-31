# Redeploy to staging slot after runtime configuration change
param(
    [string]$ResourceGroupName = "NWIApps",
    [string]$AppServiceName = "app-steel-estimation-prod",
    [string]$SlotName = "staging"
)

Write-Host "Redeploying to staging slot after runtime change..." -ForegroundColor Yellow

# Change to project directory
Set-Location $PSScriptRoot

# Create deployment package
$zipPath = Join-Path $PSScriptRoot "staging-redeploy.zip"
Write-Host "Creating deployment package..." -ForegroundColor Yellow

if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

# Compress the publish folder
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory(
    (Join-Path $PSScriptRoot "publish"),
    $zipPath,
    [System.IO.Compression.CompressionLevel]::Optimal,
    $false
)

Write-Host "Package created: $zipPath" -ForegroundColor Green
$fileSize = (Get-Item $zipPath).Length / 1MB
Write-Host "Package size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Cyan

# Deploy to staging slot
Write-Host "`nDeploying to staging slot..." -ForegroundColor Yellow
try {
    Publish-AzWebApp -ResourceGroupName $ResourceGroupName `
                     -Name $AppServiceName `
                     -Slot $SlotName `
                     -ArchivePath $zipPath `
                     -Force
    
    Write-Host "Deployment to staging slot completed successfully!" -ForegroundColor Green
    
    # Restart the slot
    Write-Host "`nRestarting staging slot..." -ForegroundColor Yellow
    Restart-AzWebApp -ResourceGroupName $ResourceGroupName `
                     -Name $AppServiceName `
                     -Slot $SlotName
    
    Write-Host "Staging slot restarted." -ForegroundColor Green
    
    # Test the staging site
    Start-Sleep -Seconds 30
    Write-Host "`nTesting staging site..." -ForegroundColor Yellow
    $stagingUrl = "https://$AppServiceName-staging.azurewebsites.net"
    
    try {
        $response = Invoke-WebRequest -Uri $stagingUrl -Method Head -TimeoutSec 30
        if ($response.StatusCode -eq 200) {
            Write-Host "Staging site is accessible!" -ForegroundColor Green
            Write-Host "URL: $stagingUrl" -ForegroundColor Cyan
        }
        else {
            Write-Host "Staging site returned status code: $($response.StatusCode)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Failed to access staging site: $_" -ForegroundColor Red
    }
}
catch {
    Write-Host "Deployment failed: $_" -ForegroundColor Red
    exit 1
}
finally {
    # Clean up
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
        Write-Host "`nDeployment package cleaned up." -ForegroundColor Gray
    }
}

Write-Host "`nRedeploy completed!" -ForegroundColor Green