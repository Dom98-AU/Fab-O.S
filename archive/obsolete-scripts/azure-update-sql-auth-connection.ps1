# Script to update App Service to use SQL authentication

$resourceGroupName = "NWIApps"
$appServiceName = "app-steel-estimation-prod"

# Prompt for SQL credentials
$sqlUsername = Read-Host "Enter SQL Username"
$sqlPassword = Read-Host "Enter SQL Password" -AsSecureString
$sqlPasswordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sqlPassword))

# Connection string for SQL authentication
$connectionString = "Server=tcp:nwiapps.database.windows.net,1433;Initial Catalog=sqldb-steel-estimation-prod;Persist Security Info=False;User ID=$sqlUsername;Password=$sqlPasswordText;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

Write-Host "Updating App Service to use SQL authentication..." -ForegroundColor Yellow

# Update the connection string
az webapp config connection-string set `
    --name $appServiceName `
    --resource-group $resourceGroupName `
    --connection-string-type SQLAzure `
    --settings DefaultConnection="$connectionString"

Write-Host "Connection string updated!" -ForegroundColor Green
Write-Host "Note: Consider migrating to Managed Identity later for better security" -ForegroundColor Yellow