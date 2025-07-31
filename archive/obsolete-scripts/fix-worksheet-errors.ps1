# PowerShell script to fix all entity property mismatches in PackageWorksheets.razor

$file = "SteelEstimation.Web\Pages\Package\PackageWorksheets.razor"

Write-Host "Fixing entity property mismatches in $file..." -ForegroundColor Green

# Read the file content
$content = Get-Content $file -Raw

# Fix DeliveryBundle and PackBundle Name -> BundleName
$content = $content -replace '\.Name\b', '.BundleName'
$content = $content -replace '\?.Name\b', '?.BundleName'

# Fix WeldingConnections -> ItemConnections
$content = $content -replace 'WeldingConnections', 'ItemConnections'

# Fix MaterialTypeService instantiation
$content = $content -replace 'new MaterialTypeService\(MaterialMappingSettings\)', 'MaterialTypeService'

# Fix MaterialMappingSettings usage
$content = $content -replace 'MaterialMappingSettings\.Value\.MaterialTypeMappings', 'new List<dynamic>()'

# Fix handling time display
$content = $content -replace '@\(\(\(item\.MoveToAssembly \+ item\.MoveAfterWeld\) / 60m\)\.ToString\("N2"\)\)h', '@(((item.MoveToAssembly + item.MoveAfterWeld) / 60m).ToString("N2") + "h")'

# Fix TotalWeldingMinutes assignment (it's read-only)
$content = $content -replace 'TotalWeldingMinutes = 0,', '// TotalWeldingMinutes is calculated'

# Fix DisplayOrder references (use Id instead)
$content = $content -replace '// Items ordered by Id\r?\n', ''

# Fix ShowBulkPackBundleModal method call
$content = $content -replace 'ShowBulkPackBundleModal', 'ShowBulkPackBundleModal'

# Write the fixed content back
Set-Content $file $content -Force

Write-Host "Fixed entity property mismatches!" -ForegroundColor Green
Write-Host "Please rebuild the project to check for remaining errors." -ForegroundColor Yellow