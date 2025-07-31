# Test staging slot configuration
param(
    [string]$ResourceGroupName = "NWIApps",
    [string]$AppServiceName = "app-steel-estimation-prod",
    [string]$SlotName = "staging"
)

Write-Host "Testing staging slot configuration..." -ForegroundColor Yellow

# Test 1: Check slot exists and is running
Write-Host "`n1. Checking slot status..." -ForegroundColor Cyan
$slot = Get-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppServiceName -Slot $SlotName
if ($slot) {
    Write-Host "   - Slot exists: YES" -ForegroundColor Green
    Write-Host "   - State: $($slot.State)" -ForegroundColor $(if($slot.State -eq "Running") {"Green"} else {"Red"})
    Write-Host "   - Enabled: $($slot.Enabled)" -ForegroundColor $(if($slot.Enabled) {"Green"} else {"Red"})
    Write-Host "   - URL: https://$($slot.DefaultHostName)" -ForegroundColor Gray
}
else {
    Write-Host "   - Slot does not exist!" -ForegroundColor Red
    exit 1
}

# Test 2: Check runtime stack
Write-Host "`n2. Checking runtime configuration..." -ForegroundColor Cyan
$config = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $AppServiceName -Slot $SlotName
Write-Host "   - .NET Version: $($config.SiteConfig.NetFrameworkVersion)" -ForegroundColor $(if($config.SiteConfig.NetFrameworkVersion -eq "v8.0") {"Green"} else {"Red"})
Write-Host "   - Platform: $(if($config.SiteConfig.Use32BitWorkerProcess) {"32-bit"} else {"64-bit"})" -ForegroundColor $(if(!$config.SiteConfig.Use32BitWorkerProcess) {"Green"} else {"Yellow"})

# Test 3: Check app settings
Write-Host "`n3. Checking app settings..." -ForegroundColor Cyan
$appSettings = (Get-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppServiceName -Slot $SlotName).SiteConfig.AppSettings
$requiredSettings = @("ASPNETCORE_ENVIRONMENT", "Environment:Name")
foreach ($setting in $requiredSettings) {
    $value = ($appSettings | Where-Object { $_.Name -eq $setting }).Value
    if ($value) {
        Write-Host "   - $setting = $value" -ForegroundColor Green
    }
    else {
        Write-Host "   - $setting = NOT SET" -ForegroundColor Red
    }
}

# Test 4: Check connection string
Write-Host "`n4. Checking database connection..." -ForegroundColor Cyan
$connStrings = Get-AzWebAppSlotConnectionString -ResourceGroupName $ResourceGroupName -Name $AppServiceName -Slot $SlotName
if ($connStrings) {
    $defaultConn = $connStrings | Where-Object { $_.Name -eq "DefaultConnection" }
    if ($defaultConn) {
        Write-Host "   - DefaultConnection configured: YES" -ForegroundColor Green
        Write-Host "   - Type: $($defaultConn.Type)" -ForegroundColor Gray
        if ($defaultConn.ConnectionString -match "sandbox") {
            Write-Host "   - Points to sandbox database: YES" -ForegroundColor Green
        }
        else {
            Write-Host "   - Points to sandbox database: NO" -ForegroundColor Red
        }
    }
    else {
        Write-Host "   - DefaultConnection: NOT CONFIGURED" -ForegroundColor Red
    }
}

# Test 5: Check if deployment files exist
Write-Host "`n5. Checking deployment readiness..." -ForegroundColor Cyan
$publishPath = Join-Path $PSScriptRoot "publish"
if (Test-Path $publishPath) {
    $files = Get-ChildItem -Path $publishPath -File -Recurse
    $dllCount = ($files | Where-Object { $_.Extension -eq ".dll" }).Count
    Write-Host "   - Publish folder exists: YES" -ForegroundColor Green
    Write-Host "   - Total files: $($files.Count)" -ForegroundColor Gray
    Write-Host "   - DLL files: $dllCount" -ForegroundColor $(if($dllCount -gt 0) {"Green"} else {"Red"})
    
    # Check for main executable
    $mainDll = Join-Path $publishPath "SteelEstimation.Web.dll"
    if (Test-Path $mainDll) {
        Write-Host "   - Main executable found: YES" -ForegroundColor Green
    }
    else {
        Write-Host "   - Main executable found: NO" -ForegroundColor Red
    }
}
else {
    Write-Host "   - Publish folder exists: NO" -ForegroundColor Red
    Write-Host "   - Run 'dotnet publish' first!" -ForegroundColor Yellow
}

# Test 6: Try to access the site
Write-Host "`n6. Testing site accessibility..." -ForegroundColor Cyan
$stagingUrl = "https://$AppServiceName-$SlotName.azurewebsites.net"
try {
    $response = Invoke-WebRequest -Uri $stagingUrl -Method Head -TimeoutSec 10 -UseBasicParsing
    Write-Host "   - Site responds: YES (Status: $($response.StatusCode))" -ForegroundColor Green
}
catch {
    if ($_.Exception.Response.StatusCode) {
        Write-Host "   - Site responds: YES (Status: $($_.Exception.Response.StatusCode))" -ForegroundColor Yellow
    }
    else {
        Write-Host "   - Site responds: NO" -ForegroundColor Red
        Write-Host "   - Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nConfiguration test completed!" -ForegroundColor Green