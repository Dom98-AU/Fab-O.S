# PowerShell script to set connection string for staging slot
param(
    [string]$ResourceGroupName = "NWIApps",
    [string]$AppServiceName = "app-steel-estimation-prod",
    [string]$SlotName = "staging"
)

Write-Host "Setting connection string for staging slot..." -ForegroundColor Green

# Connection string for Managed Identity
$connectionString = "Server=nwiapps.database.windows.net;Database=sqldb-steel-estimation-sandbox;Authentication=Active Directory Managed Identity;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

# Get current app settings
$webApp = Get-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppServiceName -Slot $SlotName

# Create hashtable for connection strings
$connectionStrings = @{
    "DefaultConnection" = @{
        "value" = $connectionString
        "type" = "SQLAzure"
    }
}

# Set the connection string
Write-Host "Adding DefaultConnection string..." -ForegroundColor Yellow
Set-AzWebAppSlot -ResourceGroupName $ResourceGroupName `
                 -Name $AppServiceName `
                 -Slot $SlotName `
                 -ConnectionStrings $connectionStrings

Write-Host "Connection string set successfully!" -ForegroundColor Green

# Restart the slot
Write-Host "Restarting staging slot..." -ForegroundColor Yellow
Restart-AzWebAppSlot -ResourceGroupName $ResourceGroupName `
                     -Name $AppServiceName `
                     -Slot $SlotName

Write-Host "Waiting for restart (30 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Test the connection
Write-Host "`nTesting database connection..." -ForegroundColor Yellow
$dbTestUrl = "https://$AppServiceName-$SlotName.azurewebsites.net/dbtest"

try {
    $response = Invoke-WebRequest -Uri $dbTestUrl -UseBasicParsing -TimeoutSec 30
    Write-Host "Database test successful!" -ForegroundColor Green
} catch {
    Write-Host "Database test failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nThis might be due to:" -ForegroundColor Yellow
    Write-Host "1. Managed Identity not having database access" -ForegroundColor White
    Write-Host "2. Need to grant permissions with SQL script" -ForegroundColor White
}

Write-Host "`nConnection string has been set!" -ForegroundColor Green
Write-Host "If database test failed, run the grant-staging-access.sql script in Azure Portal" -ForegroundColor Yellow