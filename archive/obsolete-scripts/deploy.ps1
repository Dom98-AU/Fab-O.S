# Unified deployment script for Steel Estimation Platform
# Can deploy to either Production or Staging/Sandbox
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Production", "Staging", "Sandbox")]
    [string]$Environment,
    
    [string]$ResourceGroupName = "NWIApps",
    [string]$AppServiceName = "app-steel-estimation-prod"
)

# Set color based on environment
$envColor = if ($Environment -eq "Production") { "Red" } else { "Yellow" }

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Steel Estimation Platform Deployment" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Target Environment: $Environment" -ForegroundColor $envColor
Write-Host "========================================" -ForegroundColor Cyan

# Map environment names
$targetEnvironment = if ($Environment -eq "Sandbox") { "Staging" } else { $Environment }

# Confirm deployment
if ($Environment -eq "Production") {
    Write-Host "`nWARNING: You are about to deploy to PRODUCTION!" -ForegroundColor Red
    Write-Host "This will affect live users!" -ForegroundColor Red
    $confirm = Read-Host "Type 'DEPLOY TO PRODUCTION' to confirm"
    if ($confirm -ne "DEPLOY TO PRODUCTION") {
        Write-Host "Production deployment cancelled." -ForegroundColor Yellow
        exit 0
    }
} else {
    Write-Host "`nYou are about to deploy to $Environment environment." -ForegroundColor Yellow
    $confirm = Read-Host "Continue? (yes/no)"
    if ($confirm -ne "yes") {
        Write-Host "Deployment cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Call appropriate deployment script
Write-Host "`nStarting deployment process..." -ForegroundColor Green

if ($Environment -eq "Production") {
    # Deploy to production
    & "$PSScriptRoot\deploy-production.ps1" -ResourceGroupName $ResourceGroupName -AppServiceName $AppServiceName
} else {
    # Deploy to staging/sandbox
    & "$PSScriptRoot\deploy-staging.ps1" -ResourceGroupName $ResourceGroupName -AppServiceName $AppServiceName -SlotName "staging"
}

# Show post-deployment information
if ($LASTEXITCODE -eq 0) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Deployment Successful!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    
    if ($Environment -eq "Production") {
        Write-Host "Production URL: https://$AppServiceName.azurewebsites.net" -ForegroundColor Green
    } else {
        Write-Host "Staging URL: https://$AppServiceName-staging.azurewebsites.net" -ForegroundColor Yellow
        Write-Host "`nTo promote staging to production:" -ForegroundColor White
        Write-Host "1. Test thoroughly in staging" -ForegroundColor Gray
        Write-Host "2. Run: .\swap-slots.ps1" -ForegroundColor Gray
    }
} else {
    Write-Host "`nDeployment failed! Check the errors above." -ForegroundColor Red
}

Write-Host "========================================" -ForegroundColor Cyan