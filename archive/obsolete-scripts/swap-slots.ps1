# Swap staging and production slots for Steel Estimation Platform
param(
    [string]$ResourceGroupName = "NWIApps",
    [string]$AppServiceName = "app-steel-estimation-prod",
    [string]$SourceSlot = "staging",
    [string]$TargetSlot = "production"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Slot Swap - Promote Staging to Production" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "This will swap the staging slot with production!" -ForegroundColor Yellow
Write-Host "Current staging will become production." -ForegroundColor Yellow
Write-Host "Current production will become staging." -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

# Show current URLs
Write-Host "`nCurrent URLs:" -ForegroundColor White
Write-Host "Production: https://$AppServiceName.azurewebsites.net" -ForegroundColor Green
Write-Host "Staging: https://$AppServiceName-staging.azurewebsites.net" -ForegroundColor Yellow

# Confirm swap
Write-Host "`nHave you thoroughly tested the staging environment?" -ForegroundColor Red
$tested = Read-Host "Type 'YES' to confirm you have tested staging"
if ($tested -ne "YES") {
    Write-Host "Swap cancelled. Please test staging first!" -ForegroundColor Red
    exit 0
}

$confirm = Read-Host "`nType 'SWAP TO PRODUCTION' to proceed with the swap"
if ($confirm -ne "SWAP TO PRODUCTION") {
    Write-Host "Swap cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host "`nStarting slot swap..." -ForegroundColor Yellow

try {
    # Perform the swap
    Switch-AzWebAppSlot -ResourceGroupName $ResourceGroupName `
                        -Name $AppServiceName `
                        -SourceSlotName $SourceSlot `
                        -DestinationSlotName $TargetSlot `
                        -SwapWithPreviewAction CompleteSlotSwap
    
    Write-Host "`nSlot swap completed successfully!" -ForegroundColor Green
    
    # Wait for swap to complete
    Write-Host "Waiting for swap to fully complete (30 seconds)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    # Test both slots
    Write-Host "`nTesting swapped slots..." -ForegroundColor Yellow
    
    # Test production (which now has what was in staging)
    try {
        $prodResponse = Invoke-WebRequest -Uri "https://$AppServiceName.azurewebsites.net" -UseBasicParsing -TimeoutSec 30
        Write-Host "Production is responding: $($prodResponse.StatusCode)" -ForegroundColor Green
    } catch {
        Write-Host "Production test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test staging (which now has what was in production)
    try {
        $stagingResponse = Invoke-WebRequest -Uri "https://$AppServiceName-staging.azurewebsites.net" -UseBasicParsing -TimeoutSec 30
        Write-Host "Staging is responding: $($stagingResponse.StatusCode)" -ForegroundColor Yellow
    } catch {
        Write-Host "Staging test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Swap Completed Successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "What was in staging is now in production!" -ForegroundColor Green
    Write-Host "What was in production is now in staging!" -ForegroundColor Yellow
    Write-Host "`nIf you need to rollback, run this script again." -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
    
} catch {
    Write-Error "Slot swap failed: $_"
    Write-Host "`nIf the swap partially completed, you may need to:" -ForegroundColor Yellow
    Write-Host "1. Check the Azure Portal for the current state" -ForegroundColor Gray
    Write-Host "2. Manually complete or cancel the swap" -ForegroundColor Gray
    Write-Host "3. Run this script again to rollback if needed" -ForegroundColor Gray
    exit 1
}