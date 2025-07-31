# Check App Service Plan details
param(
    [string]$ResourceGroupName = "NWIApps",
    [string]$AppServicePlanName = "NWIInternal"
)

Write-Host "Checking App Service Plan configuration..." -ForegroundColor Green

# Get the App Service Plan
$plan = Get-AzAppServicePlan -ResourceGroupName $ResourceGroupName -Name $AppServicePlanName

Write-Host "`nApp Service Plan Details:" -ForegroundColor Yellow
Write-Host "Name: $($plan.Name)" -ForegroundColor Gray
Write-Host "SKU: $($plan.Sku.Name) - $($plan.Sku.Tier)" -ForegroundColor Gray
Write-Host "Worker Size: $($plan.WorkerSize)" -ForegroundColor Gray
Write-Host "Number of Workers: $($plan.CurrentNumberOfWorkers)" -ForegroundColor Gray
Write-Host "Is Linux: $($plan.IsSpot)" -ForegroundColor Gray
Write-Host "Status: $($plan.Status)" -ForegroundColor Gray

# Check if it's Windows
if ($plan.Kind -eq "linux") {
    Write-Host "`nThis is a Linux App Service Plan!" -ForegroundColor Red
    Write-Host "The application was built for Windows. This could be the issue." -ForegroundColor Yellow
} else {
    Write-Host "`nThis is a Windows App Service Plan (correct)" -ForegroundColor Green
}

Write-Host "`nChecking all App Services in this plan..." -ForegroundColor Yellow
$apps = Get-AzWebApp -ResourceGroupName $ResourceGroupName | Where-Object { $_.ServerFarmId -like "*$AppServicePlanName*" }
$apps | ForEach-Object {
    Write-Host "  - $($_.Name) (State: $($_.State))" -ForegroundColor Gray
}