# Simple deployment script using Azure CLI
Write-Host "Deploying Steel Estimation Platform to Azure..." -ForegroundColor Green

# Build the application
Write-Host "Building application..." -ForegroundColor Yellow
dotnet publish ./SteelEstimation.Web/SteelEstimation.Web.csproj -c Release -o ./publish

# Create zip file
Write-Host "Creating deployment package..." -ForegroundColor Yellow
Compress-Archive -Path ./publish/* -DestinationPath ./deploy.zip -Force

# Deploy using Azure CLI
Write-Host "Deploying to Azure..." -ForegroundColor Yellow
az webapp deployment source config-zip `
    --resource-group rg-steel-estimation-prod `
    --name app-steel-estimation-prod `
    --slot staging `
    --src ./deploy.zip

# Cleanup
Remove-Item -Path ./publish -Recurse -Force
Remove-Item -Path ./deploy.zip -Force

Write-Host "Deployment complete!" -ForegroundColor Green
Write-Host "TestDb URL: https://app-steel-estimation-prod-staging.azurewebsites.net/TestDb" -ForegroundColor Cyan