# Extract key features from PackageWorksheets.razor

Write-Host "Extracting features from PackageWorksheets.razor..." -ForegroundColor Cyan

$content = Get-Content "PackageWorksheets.razor" -Raw

# Extract key sections
Write-Host "`nKey features found:" -ForegroundColor Yellow

# 1. Page directive and using statements
if ($content -match '@page[^@]+@using[^@]+') {
    Write-Host "  [+] Page directives and using statements" -ForegroundColor Green
}

# 2. Styles section
if ($content -match '<style>[\s\S]+?</style>') {
    Write-Host "  [+] Custom styles section" -ForegroundColor Green
}

# 3. Parameters in @code
if ($content -match '\[Parameter\].*?EstimationId.*?\[Parameter\].*?PackageId') {
    Write-Host "  [+] Page parameters (EstimationId, PackageId)" -ForegroundColor Green
}

# 4. Key features to preserve
$features = @(
    @{Name="Delivery Bundles"; Pattern="DeliveryBundle|delivery.*bundle|BulkDeliveryBundleModal"},
    @{Name="Pack Bundles"; Pattern="PackBundle|pack.*bundle"},
    @{Name="Split Rows"; Pattern="SplitRows|split.*row|ShowSplitRowsModal"},
    @{Name="Bundle Management"; Pattern="BundleManagement|ShowBundleManagementWindow"},
    @{Name="Worksheet Templates"; Pattern="WorksheetTemplate|activeWorksheet|GetActiveTemplate"},
    @{Name="Time Tracking"; Pattern="TimeTracker|timeTracker"},
    @{Name="Field Change Notifications"; Pattern="FieldChangeNotification|_fieldChangeNotifications"},
    @{Name="Column Freezing"; Pattern="frozen.*column|FrozenColumn"},
    @{Name="History/Undo"; Pattern="UndoLastChange|RedoLastChange|_changeHistory"},
    @{Name="Efficiency Rates"; Pattern="EfficiencyRate|efficiency.*rate"},
    @{Name="Connection Types"; Pattern="ConnectionType|connection.*type"},
    @{Name="Material Mapping"; Pattern="MaterialMapping|material.*mapping"}
)

foreach ($feature in $features) {
    if ($content -match $feature.Pattern) {
        Write-Host "  [+] $($feature.Name)" -ForegroundColor Green
    }
}

# 5. Modal dialogs
$modals = [regex]::Matches($content, 'Show\w+Modal|show\w+Modal').Value | Select-Object -Unique
Write-Host "`n  Modal dialogs found: $($modals.Count)" -ForegroundColor Cyan
$modals | ForEach-Object { Write-Host "    - $_" -ForegroundColor Gray }

# 6. Event handlers
$handlers = [regex]::Matches($content, 'Handle\w+|On\w+Changed').Value | Select-Object -Unique | Select-Object -First 10
Write-Host "`n  Event handlers found: $($handlers.Count)+" -ForegroundColor Cyan
$handlers | ForEach-Object { Write-Host "    - $_" -ForegroundColor Gray }

Write-Host "`nExtraction complete!" -ForegroundColor Green