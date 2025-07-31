# Fixed staging deployment script
param(
    [string]$ResourceGroupName = "NWIApps",
    [string]$AppServiceName = "app-steel-estimation-prod",
    [string]$SlotName = "staging"
)

Write-Host "Starting deployment to STAGING/SANDBOX environment..." -ForegroundColor Yellow
Write-Host "This will deploy to the staging slot, not production!" -ForegroundColor Yellow

# Confirm deployment
$confirm = Read-Host "Are you sure you want to deploy to STAGING? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Deployment cancelled." -ForegroundColor Red
    exit 0
}

# Get current directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

# 1. Build and publish
Write-Host "`nBuilding application..." -ForegroundColor Yellow
dotnet build ./SteelEstimation.Web/SteelEstimation.Web.csproj --configuration Release
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed!"
    exit 1
}

# Use absolute path for publish folder
$publishFolder = Join-Path $scriptPath "publish-staging"
if (Test-Path $publishFolder) {
    Write-Host "Removing existing publish folder..." -ForegroundColor Yellow
    Remove-Item $publishFolder -Recurse -Force
}

Write-Host "Publishing application to: $publishFolder" -ForegroundColor Yellow
dotnet publish ./SteelEstimation.Web/SteelEstimation.Web.csproj `
    --configuration Release `
    --output "$publishFolder" `
    --runtime win-x64 `
    --self-contained false

if ($LASTEXITCODE -ne 0) {
    Write-Error "Publish failed!"
    exit 1
}

# Verify publish folder exists
if (-not (Test-Path $publishFolder)) {
    Write-Error "Publish folder not found at: $publishFolder"
    exit 1
}

Write-Host "Publish folder contents:" -ForegroundColor Cyan
Get-ChildItem $publishFolder | Select-Object Name, Length, LastWriteTime | Format-Table

# 2. Create deployment package
Write-Host "`nCreating deployment package..." -ForegroundColor Yellow
$zipPath = Join-Path $scriptPath "deploy-staging.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath
}

try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($publishFolder, $zipPath)
    Write-Host "Deployment package created: $zipPath" -ForegroundColor Green
} catch {
    Write-Error "Failed to create deployment package: $_"
    exit 1
}

# 3. Deploy to staging slot
Write-Host "`nDeploying to Azure Staging Slot..." -ForegroundColor Yellow
try {
    # Check Azure login
    $account = Get-AzContext
    if (-not $account) {
        Write-Host "Not logged in to Azure. Please login." -ForegroundColor Yellow
        Connect-AzAccount
    }
    
    # Deploy to staging slot
    $webApp = Get-AzWebAppSlot -ResourceGroupName $ResourceGroupName `
                               -Name $AppServiceName `
                               -Slot $SlotName
    
    if (-not $webApp) {
        Write-Error "Staging slot not found! Please create it first."
        exit 1
    }
    
    # Deploy the package
    Publish-AzWebApp -ResourceGroupName $ResourceGroupName `
                     -Name $AppServiceName `
                     -Slot $SlotName `
                     -ArchivePath $zipPath `
                     -Force
    
    Write-Host "Deployment to staging successful!" -ForegroundColor Green
    
    # Clean up
    Remove-Item $zipPath -Force
    Remove-Item $publishFolder -Recurse -Force
    
    # 4. Configure staging-specific settings
    Write-Host "`nConfiguring staging environment settings..." -ForegroundColor Yellow
    $appSettings = @{
        "ASPNETCORE_ENVIRONMENT" = "Staging"
        "Environment:Name" = "Staging"
    }
    
    Set-AzWebAppSlot -ResourceGroupName $ResourceGroupName `
                     -Name $AppServiceName `
                     -Slot $SlotName `
                     -AppSettings $appSettings
    
    # 5. Restart staging
    Write-Host "`nRestarting Staging Slot..." -ForegroundColor Yellow
    Restart-AzWebAppSlot -ResourceGroupName $ResourceGroupName `
                         -Name $AppServiceName `
                         -Slot $SlotName
    
    Write-Host "`nWaiting for staging to start (30 seconds)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    # 6. Test staging
    $stagingUrl = "https://$AppServiceName-$SlotName.azurewebsites.net"
    Write-Host "`nTesting staging application..." -ForegroundColor Yellow
    Write-Host "URL: $stagingUrl" -ForegroundColor Cyan
    
    try {
        $response = Invoke-WebRequest -Uri $stagingUrl -UseBasicParsing -TimeoutSec 30
        Write-Host "Success! Staging returned: $($response.StatusCode)" -ForegroundColor Green
        
        # Test database
        Write-Host "`nTesting database connectivity..." -ForegroundColor Yellow
        try {
            $dbTestUrl = "$stagingUrl/dbtest"
            $dbResponse = Invoke-WebRequest -Uri $dbTestUrl -UseBasicParsing -TimeoutSec 30
            Write-Host "Database test endpoint accessible!" -ForegroundColor Green
        } catch {
            Write-Host "Database test endpoint returned: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Staging test failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Check the Log Stream in Azure Portal for details" -ForegroundColor Yellow
    }
    
} catch {
    Write-Error "Deployment failed: $_"
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force -ErrorAction SilentlyContinue }
    if (Test-Path $publishFolder) { Remove-Item $publishFolder -Recurse -Force -ErrorAction SilentlyContinue }
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Staging Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Staging URL: https://$AppServiceName-$SlotName.azurewebsites.net" -ForegroundColor Cyan
Write-Host "Database Test: https://$AppServiceName-$SlotName.azurewebsites.net/dbtest" -ForegroundColor Cyan
Write-Host "Auth Test: https://$AppServiceName-$SlotName.azurewebsites.net/authtest" -ForegroundColor Cyan
Write-Host "Login: https://$AppServiceName-$SlotName.azurewebsites.net/login" -ForegroundColor Cyan
Write-Host "`nTo monitor logs:" -ForegroundColor Yellow
Write-Host "az webapp log tail --name $AppServiceName --slot $SlotName --resource-group $ResourceGroupName" -ForegroundColor Gray
Write-Host "`nTo swap to production later:" -ForegroundColor Yellow
Write-Host "Switch-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppServiceName -SourceSlotName $SlotName -DestinationSlotName 'production'" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan