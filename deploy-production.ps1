# Production deployment script for Steel Estimation Platform
param(
    [string]$ResourceGroupName = "NWIApps",
    [string]$AppServiceName = "app-steel-estimation-prod"
)

Write-Host "Starting deployment to PRODUCTION environment..." -ForegroundColor Red
Write-Host "WARNING: This will deploy directly to production!" -ForegroundColor Red

# Confirm deployment
$confirm = Read-Host "Are you sure you want to deploy to PRODUCTION? (yes/no)"
if ($confirm -ne "yes") {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host "`nProceeding with production deployment..." -ForegroundColor Green

# 1. Ensure App Service has correct runtime
Write-Host "`nConfiguring App Service runtime..." -ForegroundColor Yellow
$webapp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName

# Set to .NET 8
$webapp.SiteConfig.NetFrameworkVersion = "v8.0"
$webapp.SiteConfig.ManagedPipelineMode = "Integrated"
$webapp.SiteConfig.Use32BitWorkerProcess = $false

# Update metadata
if (-not $webapp.SiteConfig.AppSettings) {
    $webapp.SiteConfig.AppSettings = @()
}

$metadataExists = $webapp.SiteConfig.AppSettings | Where-Object { $_.Name -eq "WEBSITE_NODE_DEFAULT_VERSION" }
if (-not $metadataExists) {
    $webapp.SiteConfig.AppSettings += @{
        Name = "WEBSITE_NODE_DEFAULT_VERSION"
        Value = "~18"
    }
}

Set-AzWebApp -WebApp $webapp

Write-Host "Runtime configured" -ForegroundColor Green

# 2. Build and publish
Write-Host "`nBuilding application..." -ForegroundColor Yellow
dotnet build ./SteelEstimation.Web/SteelEstimation.Web.csproj --configuration Release
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed!"
    exit 1
}

$publishFolder = "./publish-final"
if (Test-Path $publishFolder) {
    Remove-Item $publishFolder -Recurse -Force
}

Write-Host "Publishing application..." -ForegroundColor Yellow
dotnet publish ./SteelEstimation.Web/SteelEstimation.Web.csproj `
    --configuration Release `
    --output $publishFolder `
    --runtime win-x64 `
    --self-contained false

if ($LASTEXITCODE -ne 0) {
    Write-Error "Publish failed!"
    exit 1
}

# 3. Create deployment package
Write-Host "`nCreating deployment package..." -ForegroundColor Yellow
$zipPath = "./deploy-final.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($publishFolder, $zipPath)

# 4. Deploy
Write-Host "`nDeploying to Azure..." -ForegroundColor Yellow
try {
    Publish-AzWebApp -ResourceGroupName $ResourceGroupName `
                     -Name $AppServiceName `
                     -ArchivePath $zipPath `
                     -Force
    
    Write-Host "Deployment successful!" -ForegroundColor Green
    
    # Clean up
    Remove-Item $zipPath -Force
    Remove-Item $publishFolder -Recurse -Force
    
    # 5. Restart app
    Write-Host "`nRestarting App Service..." -ForegroundColor Yellow
    Restart-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName
    
    Write-Host "`nWaiting for app to start (60 seconds)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 60
    
    # 6. Test
    Write-Host "`nTesting application..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "https://$AppServiceName.azurewebsites.net" -UseBasicParsing -TimeoutSec 30
        Write-Host "Success! Application returned: $($response.StatusCode)" -ForegroundColor Green
        Write-Host "Content: $($response.Content)" -ForegroundColor Gray
    } catch {
        Write-Host "Application test failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Check the Log Stream in Azure Portal for details" -ForegroundColor Yellow
    }
    
} catch {
    Write-Error "Deployment failed: $_"
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    Remove-Item $publishFolder -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

Write-Host "`nDeployment complete!" -ForegroundColor Green
Write-Host "URL: https://$AppServiceName.azurewebsites.net" -ForegroundColor Cyan