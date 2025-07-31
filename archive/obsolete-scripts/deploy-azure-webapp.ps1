# Deploy to Azure App Service using Az PowerShell module
param(
    [string]$ResourceGroupName = "NWIApps",
    [string]$AppServiceName = "app-steel-estimation-prod"
)

Write-Host "Starting deployment to Azure App Service..." -ForegroundColor Green

# Check if already logged in
$context = Get-AzContext
if (!$context) {
    Write-Host "Please login to Azure..." -ForegroundColor Yellow
    Connect-AzAccount
}

Write-Host "Building application..." -ForegroundColor Green

# Build the Web project specifically
dotnet build ./SteelEstimation.Web/SteelEstimation.Web.csproj --configuration Release
if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed!"
    exit 1
}

Write-Host "Publishing application..." -ForegroundColor Green

# Publish the Web project
$publishFolder = "./publish-output"
if (Test-Path $publishFolder) {
    Remove-Item $publishFolder -Recurse -Force
}

dotnet publish ./SteelEstimation.Web/SteelEstimation.Web.csproj --configuration Release --output $publishFolder
if ($LASTEXITCODE -ne 0) {
    Write-Error "Publish failed!"
    exit 1
}

Write-Host "Creating deployment package..." -ForegroundColor Green

# Create zip file
$zipPath = "./deploy.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath
}

# Use .NET compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($publishFolder, $zipPath)

Write-Host "Deploying to Azure App Service: $AppServiceName" -ForegroundColor Green

try {
    # Deploy using Publish-AzWebApp
    $webapp = Publish-AzWebApp -ResourceGroupName $ResourceGroupName `
                              -Name $AppServiceName `
                              -ArchivePath $zipPath `
                              -Force
    
    Write-Host "Deployment successful!" -ForegroundColor Green
    Write-Host "Application URL: https://$AppServiceName.azurewebsites.net" -ForegroundColor Cyan
    
    # Clean up
    Remove-Item $zipPath -Force
    Remove-Item $publishFolder -Recurse -Force
    
    # Check app service health
    Write-Host "`nChecking application status..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    $response = Invoke-WebRequest -Uri "https://$AppServiceName.azurewebsites.net" -UseBasicParsing -TimeoutSec 30
    if ($response.StatusCode -eq 200) {
        Write-Host "Application is responding successfully!" -ForegroundColor Green
    } else {
        Write-Host "Application returned status code: $($response.StatusCode)" -ForegroundColor Yellow
    }
    
} catch {
    Write-Error "Deployment failed: $_"
    
    # Try to get more error details
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response details: $responseBody" -ForegroundColor Red
    }
    
    # Clean up on failure
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    if (Test-Path $publishFolder) { Remove-Item $publishFolder -Recurse -Force }
    
    exit 1
}

Write-Host "`nDeployment complete!" -ForegroundColor Green
Write-Host "Your application is now running at: https://$AppServiceName.azurewebsites.net" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Visit the URL to test the application" -ForegroundColor White
Write-Host "2. Check Application Insights for monitoring data" -ForegroundColor White
Write-Host "3. Review logs in the Azure Portal if you encounter issues" -ForegroundColor White