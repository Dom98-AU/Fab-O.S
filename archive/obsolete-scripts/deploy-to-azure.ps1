# Deployment Script for Steel Estimation Platform
# Deploys the application to Azure App Service

# Variables
$resourceGroupName = "NWIApps"  # Using existing resource group
$appServiceName = "app-steel-estimation-prod"
$projectPath = "./SteelEstimation.Web/SteelEstimation.Web.csproj"

Write-Host "Starting deployment to Azure..." -ForegroundColor Yellow

# Build the project
Write-Host "Building project..." -ForegroundColor Yellow
dotnet build $projectPath --configuration Release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

# Publish the project
Write-Host "Publishing project..." -ForegroundColor Yellow
dotnet publish $projectPath --configuration Release --output ./publish

if ($LASTEXITCODE -ne 0) {
    Write-Host "Publish failed!" -ForegroundColor Red
    exit 1
}

# Create a zip file for deployment
Write-Host "Creating deployment package..." -ForegroundColor Yellow
$zipPath = "./publish.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath
}

Compress-Archive -Path ./publish/* -DestinationPath $zipPath

# Deploy to Azure App Service
Write-Host "Deploying to Azure App Service..." -ForegroundColor Yellow
az webapp deployment source config-zip `
    --resource-group $resourceGroupName `
    --name $appServiceName `
    --src $zipPath

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nDeployment successful!" -ForegroundColor Green
    Write-Host "Application URL: https://$appServiceName.azurewebsites.net" -ForegroundColor Cyan
    
    # Clean up
    Remove-Item $zipPath
    Remove-Item -Recurse -Force ./publish
} else {
    Write-Host "Deployment failed!" -ForegroundColor Red
}

# Show application logs
Write-Host "`nFetching recent logs..." -ForegroundColor Yellow
az webapp log tail `
    --name $appServiceName `
    --resource-group $resourceGroupName `
    --timeout 30