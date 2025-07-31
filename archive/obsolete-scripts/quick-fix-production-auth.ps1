# Quick fix for production - use SQL authentication temporarily
param(
    [Parameter(Mandatory=$true)]
    [string]$SqlPassword
)

# Create connection string with SQL auth using your admin credentials
$connectionString = "Server=nwiapps.database.windows.net;Database=sqldb-steel-estimation-prod;User Id=nwiapps;Password=$SqlPassword;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

# Update production connection string
az webapp config connection-string set `
    --resource-group "NWIApps" `
    --name "app-steel-estimation-prod" `
    --settings DefaultConnection="$connectionString" `
    --connection-string-type SQLAzure

# Restart
az webapp restart --resource-group "NWIApps" --name "app-steel-estimation-prod"

Write-Host "Production should be working in about 30 seconds..."
Write-Host "This is a temporary fix. We can troubleshoot Managed Identity later."