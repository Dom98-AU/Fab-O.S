# Script to update App Service connection string
# Use this if Managed Identity SQL access isn't working

$resourceGroupName = "NWIApps"
$appServiceName = "app-steel-estimation-prod"
$sqlServerName = "nwiapps"
$databaseName = "sqldb-steel-estimation-prod"

# Get SQL credentials
$sqlUsername = Read-Host "Enter SQL Username"
$sqlPassword = Read-Host "Enter SQL Password" -AsSecureString
$sqlPasswordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sqlPassword))

# Build connection string
$connectionString = "Server=tcp:$sqlServerName.database.windows.net,1433;Database=$databaseName;User ID=$sqlUsername;Password=$sqlPasswordText;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

Write-Host "Updating App Service connection string..." -ForegroundColor Yellow

# Update the connection string
az webapp config connection-string set `
    --name $appServiceName `
    --resource-group $resourceGroupName `
    --connection-string-type SQLServer `
    --settings DefaultConnection="$connectionString"

Write-Host "Connection string updated!" -ForegroundColor Green
Write-Host "Note: For production, consider storing the password in Key Vault" -ForegroundColor Yellow