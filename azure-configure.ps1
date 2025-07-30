# Azure Configuration Script for Steel Estimation Platform
# Run this AFTER azure-setup.ps1 completes successfully

# Variables (must match azure-setup.ps1)
$resourceGroupName = "NWIApps"  # Using existing resource group
$appServiceName = "app-steel-estimation-prod"
$sqlServerName = "nwiapps"  # Using existing SQL Server
$databaseName = "sqldb-steel-estimation-prod"
$keyVaultName = "NWIDev"  # Using existing Key Vault
$appInsightsName = "ai-steel-estimation-prod"

# Enable Managed Identity for App Service
Write-Host "Enabling Managed Identity for App Service..." -ForegroundColor Yellow
az webapp identity assign `
    --name $appServiceName `
    --resource-group $resourceGroupName

# Get the Managed Identity Object ID
$identityObjectId = az webapp identity show `
    --name $appServiceName `
    --resource-group $resourceGroupName `
    --query principalId `
    --output tsv

# Grant Key Vault access to App Service Managed Identity
Write-Host "Granting Key Vault access to App Service..." -ForegroundColor Yellow
az keyvault set-policy `
    --name $keyVaultName `
    --object-id $identityObjectId `
    --secret-permissions get list

# Get Application Insights Connection String
$appInsightsConnString = az monitor app-insights component show `
    --app $appInsightsName `
    --resource-group $resourceGroupName `
    --query connectionString `
    --output tsv

# Configure App Service Settings
Write-Host "Configuring App Service Settings..." -ForegroundColor Yellow

# Build SQL Connection String with Managed Identity
$sqlConnectionString = "Server=tcp:$sqlServerName.database.windows.net,1433;Database=$databaseName;Authentication=Active Directory Managed Identity;"

# Set App Settings
az webapp config appsettings set `
    --name $appServiceName `
    --resource-group $resourceGroupName `
    --settings `
    "ASPNETCORE_ENVIRONMENT=Production" `
    "ConnectionStrings__DefaultConnection=$sqlConnectionString" `
    "ApplicationInsights__ConnectionString=$appInsightsConnString" `
    "KeyVault__Url=https://$keyVaultName.vault.azure.net/"

# Configure Always On
Write-Host "Enabling Always On..." -ForegroundColor Yellow
az webapp config set `
    --name $appServiceName `
    --resource-group $resourceGroupName `
    --always-on true

# Configure HTTPS Only
Write-Host "Enabling HTTPS Only..." -ForegroundColor Yellow
az webapp update `
    --name $appServiceName `
    --resource-group $resourceGroupName `
    --https-only true

# Add JWT Secret to Key Vault
Write-Host "Adding JWT Secret to Key Vault..." -ForegroundColor Yellow
$jwtSecret = [System.Convert]::ToBase64String((1..32 | ForEach {Get-Random -Maximum 256}))
az keyvault secret set `
    --vault-name $keyVaultName `
    --name "jwt-secret" `
    --value $jwtSecret

# Create deployment slots
Write-Host "Creating Staging Slot..." -ForegroundColor Yellow
az webapp deployment slot create `
    --name $appServiceName `
    --resource-group $resourceGroupName `
    --slot staging

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Configuration Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Grant SQL Database access to Managed Identity" -ForegroundColor White
Write-Host "2. Run database migrations" -ForegroundColor White
Write-Host "3. Deploy application code" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan