# Configure staging slot settings for Steel Estimation Platform
param(
    [string]$ResourceGroupName = "NWIApps",
    [string]$AppServiceName = "app-steel-estimation-prod",
    [string]$SlotName = "staging",
    [string]$SandboxDatabaseName = "sqldb-steel-estimation-sandbox",
    [string]$SqlServerName = "nwiapps"
)

Write-Host "Configuring Staging Slot Settings..." -ForegroundColor Yellow

# Login to Azure if needed
$context = Get-AzContext
if (-not $context) {
    Write-Host "Logging into Azure..." -ForegroundColor Yellow
    Connect-AzAccount
}

try {
    # Check if staging slot exists
    $slot = Get-AzWebAppSlot -ResourceGroupName $ResourceGroupName `
                            -Name $AppServiceName `
                            -Slot $SlotName `
                            -ErrorAction SilentlyContinue
    
    if (-not $slot) {
        Write-Host "Staging slot not found. Creating it..." -ForegroundColor Yellow
        New-AzWebAppSlot -ResourceGroupName $ResourceGroupName `
                        -Name $AppServiceName `
                        -Slot $SlotName
        Write-Host "Staging slot created." -ForegroundColor Green
    }
    
    # Configure app settings for staging
    Write-Host "`nConfiguring staging app settings..." -ForegroundColor Yellow
    
    # Build connection string for sandbox database
    $sandboxConnectionString = "Server=$SqlServerName.database.windows.net;Database=$SandboxDatabaseName;Authentication=Active Directory Managed Identity;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    
    # Define staging-specific settings
    $appSettings = @{
        "ASPNETCORE_ENVIRONMENT" = "Staging"
        "Environment:Name" = "Staging"
        "Environment:ShowDebugInfo" = "true"
        "DetailedErrors" = "true"
        "Logging:LogLevel:Default" = "Information"
        "Logging:LogLevel:Microsoft.AspNetCore" = "Information"
    }
    
    # Define connection strings (these are stored separately from app settings)
    $connectionStrings = @{
        "DefaultConnection" = @{
            "value" = $sandboxConnectionString
            "type" = "SQLAzure"
        }
    }
    
    # Update app settings
    Set-AzWebAppSlot -ResourceGroupName $ResourceGroupName `
                     -Name $AppServiceName `
                     -Slot $SlotName `
                     -AppSettings $appSettings
    
    Write-Host "App settings configured." -ForegroundColor Green
    
    # Update connection strings
    Write-Host "`nConfiguring connection strings..." -ForegroundColor Yellow
    
    # Get current slot config
    $slotConfig = Get-AzWebAppSlot -ResourceGroupName $ResourceGroupName `
                                  -Name $AppServiceName `
                                  -Slot $SlotName
    
    # Set connection string using Azure CLI (PowerShell cmdlet doesn't handle this well)
    az webapp config connection-string set `
        --resource-group $ResourceGroupName `
        --name $AppServiceName `
        --slot $SlotName `
        --connection-string-type SQLAzure `
        --settings DefaultConnection=$sandboxConnectionString
    
    Write-Host "Connection strings configured." -ForegroundColor Green
    
    # Configure slot-specific settings (settings that don't swap)
    Write-Host "`nConfiguring sticky settings..." -ForegroundColor Yellow
    
    $stickySettings = @(
        "ASPNETCORE_ENVIRONMENT",
        "Environment:Name",
        "DefaultConnection"
    )
    
    # Make these settings "sticky" to the slot
    Set-AzWebAppSlotConfigName -ResourceGroupName $ResourceGroupName `
                              -Name $AppServiceName `
                              -AppSettingNames $stickySettings `
                              -ConnectionStringNames @("DefaultConnection")
    
    Write-Host "Sticky settings configured." -ForegroundColor Green
    
    # Enable Always On for staging (optional, but recommended)
    Write-Host "`nEnabling Always On for staging slot..." -ForegroundColor Yellow
    $slotConfig.SiteConfig.AlwaysOn = $true
    Set-AzWebAppSlot -WebApp $slotConfig
    
    # Restart staging slot to apply all changes
    Write-Host "`nRestarting staging slot..." -ForegroundColor Yellow
    Restart-AzWebAppSlot -ResourceGroupName $ResourceGroupName `
                         -Name $AppServiceName `
                         -Slot $SlotName
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Staging Slot Configuration Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Staging URL: https://$AppServiceName-staging.azurewebsites.net" -ForegroundColor Yellow
    Write-Host "Database: $SandboxDatabaseName" -ForegroundColor Yellow
    Write-Host "Environment: Staging" -ForegroundColor Yellow
    Write-Host "`nSticky settings (won't swap with production):" -ForegroundColor White
    foreach ($setting in $stickySettings) {
        Write-Host "  - $setting" -ForegroundColor Gray
    }
    Write-Host "`nNext steps:" -ForegroundColor White
    Write-Host "1. Deploy your application using: .\deploy.ps1 -Environment Staging" -ForegroundColor Gray
    Write-Host "2. Run database migrations on the sandbox database" -ForegroundColor Gray
    Write-Host "3. Test thoroughly before swapping to production" -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor Cyan
    
} catch {
    Write-Error "Failed to configure staging slot: $_"
    exit 1
}