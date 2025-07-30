# Fix script to create App Service with correct runtime
# Run this after the main setup script if App Service creation failed

$resourceGroupName = "NWIApps"
$appServicePlanName = "NWIInternal"
$appServiceName = "app-steel-estimation-prod"

Write-Host "Creating App Service with correct runtime..." -ForegroundColor Yellow

# First, check available runtimes
Write-Host "Available Windows runtimes:" -ForegroundColor Cyan
az webapp list-runtimes --os-type windows | Select-String -Pattern "dotnet"

# Create App Service with correct .NET 8 runtime
az webapp create `
    --name $appServiceName `
    --resource-group $resourceGroupName `
    --plan $appServicePlanName `
    --runtime "dotnet:8"

if ($LASTEXITCODE -eq 0) {
    Write-Host "App Service created successfully!" -ForegroundColor Green
} else {
    Write-Host "Trying alternative runtime format..." -ForegroundColor Yellow
    # Try without runtime and configure it later
    az webapp create `
        --name $appServiceName `
        --resource-group $resourceGroupName `
        --plan $appServicePlanName
        
    # Then set the stack
    az webapp config set `
        --name $appServiceName `
        --resource-group $resourceGroupName `
        --net-framework-version "v8.0"
}

Write-Host "App Service URL: https://$appServiceName.azurewebsites.net" -ForegroundColor Cyan