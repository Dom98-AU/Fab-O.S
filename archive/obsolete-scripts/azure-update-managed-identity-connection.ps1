# Script to update App Service to use Managed Identity connection string

$resourceGroupName = "NWIApps"
$appServiceName = "app-steel-estimation-prod"

# Connection string for Managed Identity (Active Directory Default)
$connectionString = "Server=tcp:nwiapps.database.windows.net,1433;Initial Catalog=sqldb-steel-estimation-prod;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;Authentication=Active Directory Default;"

Write-Host "Updating App Service to use Managed Identity connection..." -ForegroundColor Yellow

# Update the connection string
az webapp config connection-string set `
    --name $appServiceName `
    --resource-group $resourceGroupName `
    --connection-string-type SQLAzure `
    --settings DefaultConnection="$connectionString"

Write-Host "Connection string updated to use Managed Identity!" -ForegroundColor Green
Write-Host "The App Service will now authenticate using its Managed Identity" -ForegroundColor Cyan