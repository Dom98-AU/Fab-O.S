# Direct deployment to Azure App Service
Write-Host "Direct deployment to Azure App Service..." -ForegroundColor Green

# Build the application
Write-Host "Building application..." -ForegroundColor Yellow
dotnet publish ./SteelEstimation.Web/SteelEstimation.Web.csproj -c Release -o ./publish

# Create zip file
Write-Host "Creating deployment package..." -ForegroundColor Yellow
if (Test-Path ./deploy.zip) {
    Remove-Item ./deploy.zip -Force
}
Compress-Archive -Path ./publish/* -DestinationPath ./deploy.zip -Force

# Deploy using Azure CLI with the correct resource names
Write-Host "Deploying to Azure..." -ForegroundColor Yellow

# First, let's check if we're logged in
$account = az account show 2>$null
if (-not $account) {
    Write-Host "Not logged into Azure CLI. Logging in..." -ForegroundColor Yellow
    az login
}

# Deploy to the app service directly
az webapp deploy `
    --resource-group "nwiapps" `
    --name "app-steel-estimation-prod" `
    --slot "staging" `
    --src-path "./deploy.zip" `
    --type "zip"

# Cleanup
Write-Host "Cleaning up..." -ForegroundColor Yellow
Remove-Item -Path ./publish -Recurse -Force
Remove-Item -Path ./deploy.zip -Force

Write-Host "Deployment complete!" -ForegroundColor Green
Write-Host "TestDb URL: https://app-steel-estimation-prod-staging.azurewebsites.net/TestDb" -ForegroundColor Cyan