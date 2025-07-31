# Azure Setup Script for Steel Estimation Platform
# Run this script in PowerShell with Azure CLI or Azure PowerShell module installed

# Variables
$resourceGroupName = "NWIApps"  # Using existing resource group
$location = "australiaeast"  # Change to your preferred location if needed
$appServicePlanName = "NWIInternal"  # Using existing App Service Plan
$appServiceName = "app-steel-estimation-prod"
$sqlServerName = "nwiapps"  # Using existing SQL Server
$databaseName = "sqldb-steel-estimation-prod"
$keyVaultName = "NWIDev"  # Using existing Key Vault
$appInsightsName = "ai-steel-estimation-prod"
$storageAccountName = "steelestimationstorage"  # Must be globally unique, lowercase, no hyphens

# Login to Azure
Write-Host "Logging into Azure..." -ForegroundColor Yellow
az login

# Using existing Resource Group - Skip creation
Write-Host "Using existing Resource Group: $resourceGroupName" -ForegroundColor Yellow
# az group create --name $resourceGroupName --location $location  # Commented out - using existing

# Using existing App Service Plan - Skip creation
Write-Host "Using existing App Service Plan: $appServicePlanName" -ForegroundColor Yellow
# az appservice plan create `
#     --name $appServicePlanName `
#     --resource-group $resourceGroupName `
#     --location $location `
#     --sku S1 `
#     --is-linux false  # Commented out - using existing

# Create App Service
Write-Host "Creating App Service..." -ForegroundColor Yellow
az webapp create `
    --name $appServiceName `
    --resource-group $resourceGroupName `
    --plan $appServicePlanName `
    --runtime "DOTNET:8.0"

# Using existing SQL Server - Skip creation
Write-Host "Using existing SQL Server: $sqlServerName" -ForegroundColor Yellow
# Ensure firewall rule exists for Azure services (in case it's not already set)
Write-Host "Ensuring SQL Server Firewall allows Azure services..." -ForegroundColor Yellow
try {
    az sql server firewall-rule create `
        --resource-group $resourceGroupName `
        --server $sqlServerName `
        --name AllowAzureServices `
        --start-ip-address 0.0.0.0 `
        --end-ip-address 0.0.0.0 2>$null
} catch {
    Write-Host "Firewall rule already exists or cannot be created" -ForegroundColor Yellow
}

# Create SQL Database (Standard S2)
Write-Host "Creating SQL Database..." -ForegroundColor Yellow
az sql db create `
    --name $databaseName `
    --server $sqlServerName `
    --resource-group $resourceGroupName `
    --service-objective S2 `
    --zone-redundant false

# Using existing Key Vault - Skip creation
Write-Host "Using existing Key Vault: $keyVaultName" -ForegroundColor Yellow
# az keyvault create `
#     --name $keyVaultName `
#     --resource-group $resourceGroupName `
#     --location $location `
#     --sku standard  # Commented out - using existing

# Create Application Insights
Write-Host "Creating Application Insights..." -ForegroundColor Yellow
az monitor app-insights component create `
    --app $appInsightsName `
    --location $location `
    --resource-group $resourceGroupName `
    --application-type web

# Create Storage Account (for file uploads)
Write-Host "Creating Storage Account..." -ForegroundColor Yellow
az storage account create `
    --name $storageAccountName `
    --resource-group $resourceGroupName `
    --location $location `
    --sku Standard_LRS `
    --kind StorageV2

# Get Connection String
Write-Host "`nGetting SQL Connection String..." -ForegroundColor Green
$sqlConnection = az sql db show-connection-string `
    --client ado.net `
    --server $sqlServerName `
    --name $databaseName `
    --query connectionString `
    --output tsv

# Get App Insights Instrumentation Key
Write-Host "Getting Application Insights Key..." -ForegroundColor Green
$appInsightsKey = az monitor app-insights component show `
    --app $appInsightsName `
    --resource-group $resourceGroupName `
    --query instrumentationKey `
    --output tsv

# Output important information
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Azure Resources Created Successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Resource Group: $resourceGroupName" -ForegroundColor White
Write-Host "App Service URL: https://$appServiceName.azurewebsites.net" -ForegroundColor White
Write-Host "SQL Server: $sqlServerName.database.windows.net" -ForegroundColor White
Write-Host "Database: $databaseName" -ForegroundColor White
Write-Host "Key Vault: $keyVaultName" -ForegroundColor White
Write-Host "`nIMPORTANT: Update the SQL Server password immediately!" -ForegroundColor Red
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Update appsettings.json with the connection string" -ForegroundColor White
Write-Host "2. Store secrets in Key Vault" -ForegroundColor White
Write-Host "3. Configure managed identity for App Service" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan