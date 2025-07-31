# Configure App Service settings
param(
    [string]$ResourceGroupName = "NWIApps",
    [string]$AppServiceName = "app-steel-estimation-prod",
    [string]$KeyVaultName = "NWIDev"
)

Write-Host "Configuring App Service settings..." -ForegroundColor Green

# Get the JWT secret from Key Vault
$jwtSecret = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name "jwt-secret" -AsPlainText

# Configure app settings
$settings = @{
    "ASPNETCORE_ENVIRONMENT" = "Production"
    "JwtSettings__SecretKey" = $jwtSecret
    "JwtSettings__Issuer" = "SteelEstimation"
    "JwtSettings__Audience" = "SteelEstimation"
    "JwtSettings__ExpiryHours" = "8"
    "Serilog__MinimumLevel__Default" = "Information"
    "Serilog__MinimumLevel__Override__Microsoft" = "Warning"
    "Serilog__MinimumLevel__Override__Microsoft.Hosting.Lifetime" = "Information"
}

# Get existing app settings
$webapp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName
$existingSettings = @{}
foreach ($setting in $webapp.SiteConfig.AppSettings) {
    $existingSettings[$setting.Name] = $setting.Value
}

# Merge settings
foreach ($key in $settings.Keys) {
    $existingSettings[$key] = $settings[$key]
}

# Update app settings
Set-AzWebApp -ResourceGroupName $ResourceGroupName `
             -Name $AppServiceName `
             -AppSettings $existingSettings

Write-Host "App settings updated successfully!" -ForegroundColor Green

Write-Host "`nRedeploying application with updated settings..." -ForegroundColor Green

# Redeploy the application
& ./deploy-azure-webapp.ps1

Write-Host "`nApplication should now be running correctly!" -ForegroundColor Green