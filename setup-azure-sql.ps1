# Setup script for Azure SQL Database
param(
    [string]$ResourceGroup = "FabOS-RG",
    [string]$Location = "australiaeast",
    [string]$ServerName = "fabos-sql-server",
    [string]$DatabaseName = "FabOS-DB",
    [string]$AdminUser = "fabosadmin"
)

Write-Host "Setting up Azure SQL Database for Fab-O.S..." -ForegroundColor Cyan

# Login to Azure
Write-Host "Logging into Azure..." -ForegroundColor Yellow
az login

# Create Resource Group
Write-Host "Creating Resource Group..." -ForegroundColor Yellow
az group create --name $ResourceGroup --location $Location

# Create SQL Server
Write-Host "Creating SQL Server..." -ForegroundColor Yellow
$password = Read-Host "Enter SQL Admin Password" -AsSecureString
$passwordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

az sql server create `
    --name $ServerName `
    --resource-group $ResourceGroup `
    --location $Location `
    --admin-user $AdminUser `
    --admin-password $passwordText

# Configure Firewall
Write-Host "Configuring Firewall..." -ForegroundColor Yellow
# Allow Azure services
az sql server firewall-rule create `
    --resource-group $ResourceGroup `
    --server $ServerName `
    --name AllowAzureServices `
    --start-ip-address 0.0.0.0 `
    --end-ip-address 0.0.0.0

# Allow your current IP
$myIP = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content
az sql server firewall-rule create `
    --resource-group $ResourceGroup `
    --server $ServerName `
    --name MyIP `
    --start-ip-address $myIP `
    --end-ip-address $myIP

# Create Database
Write-Host "Creating Database..." -ForegroundColor Yellow
az sql db create `
    --resource-group $ResourceGroup `
    --server $ServerName `
    --name $DatabaseName `
    --service-objective S0 `
    --zone-redundant false

# Get connection string
$connectionString = az sql db show-connection-string `
    --server $ServerName `
    --name $DatabaseName `
    --client ado.net `
    --output tsv

Write-Host "`nSetup Complete!" -ForegroundColor Green
Write-Host "Connection String:" -ForegroundColor Cyan
Write-Host $connectionString -ForegroundColor Yellow
Write-Host "`nUpdate your .env file with:" -ForegroundColor Cyan
Write-Host "AZURE_SQL_PASSWORD=$passwordText" -ForegroundColor Yellow
Write-Host "AZURE_SQL_SERVER=$ServerName.database.windows.net" -ForegroundColor Yellow
Write-Host "AZURE_SQL_DATABASE=$DatabaseName" -ForegroundColor Yellow
Write-Host "AZURE_SQL_USER=$AdminUser" -ForegroundColor Yellow