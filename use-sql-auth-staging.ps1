# Alternative: Use SQL Authentication instead of Managed Identity
# This script switches staging to use SQL authentication

param(
    [string]$SqlUsername = "staging_user",
    [string]$SqlPassword = ""  # You'll need to provide this
)

if ([string]::IsNullOrEmpty($SqlPassword)) {
    $SqlPassword = Read-Host "Enter SQL password for staging user" -AsSecureString
    $SqlPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SqlPassword))
}

# Create connection string with SQL authentication
$connectionString = "Server=nwiapps.database.windows.net;Database=sqldb-steel-estimation-sandbox;User Id=$SqlUsername;Password=$SqlPassword;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

Write-Host "Updating connection string to use SQL authentication..." -ForegroundColor Yellow

# Update the connection string
az webapp config connection-string set `
    --resource-group "NWIApps" `
    --name "app-steel-estimation-prod" `
    --slot "staging" `
    --settings DefaultConnection="$connectionString" `
    --connection-string-type SQLAzure

Write-Host "Connection string updated!" -ForegroundColor Green

# Restart the staging slot
Write-Host "Restarting staging slot..." -ForegroundColor Yellow
az webapp restart --resource-group "NWIApps" --name "app-steel-estimation-prod" --slot "staging"

Write-Host "`nConfiguration complete!" -ForegroundColor Green
Write-Host "Make sure to create the SQL user in the database first:" -ForegroundColor Yellow
Write-Host @"
-- Run this in the sandbox database:
CREATE LOGIN [$SqlUsername] WITH PASSWORD = '$SqlPassword';
CREATE USER [$SqlUsername] FOR LOGIN [$SqlUsername];
ALTER ROLE db_datareader ADD MEMBER [$SqlUsername];
ALTER ROLE db_datawriter ADD MEMBER [$SqlUsername];
ALTER ROLE db_ddladmin ADD MEMBER [$SqlUsername];
"@ -ForegroundColor Cyan