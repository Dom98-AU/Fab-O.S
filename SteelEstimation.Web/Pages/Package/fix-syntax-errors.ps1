# Fix syntax errors in PackageWorksheets.razor

$file = "PackageWorksheets.razor"
Write-Host "Fixing syntax errors in $file..." -ForegroundColor Cyan

# Read the file
$content = Get-Content $file -Raw

# Fix 1: Remove the stray "); at line 4179
Write-Host "1. Removing stray '); at line 4179..." -ForegroundColor Yellow
$content = $content -replace '(\s+private void SetFilter\(string filter\)\s*\{\s*)\"\);', '$1'

# Fix 2: Fix any <WeldingItem> tags that should be comments or code
Write-Host "2. Fixing WeldingItem references..." -ForegroundColor Yellow
# These are likely in comments or string literals that got misinterpreted
$content = $content -replace '<WeldingItem>', '&lt;WeldingItem&gt;'
$content = $content -replace '</WeldingItem>', '&lt;/WeldingItem&gt;'

# Fix 3: Fix <string> tags
Write-Host "3. Fixing string references..." -ForegroundColor Yellow
$content = $content -replace '<string>', '&lt;string&gt;'
$content = $content -replace '</string>', '&lt;/string&gt;'

# Fix 4: Fix <DeliveryBundle> and <PackBundle> tags
Write-Host "4. Fixing DeliveryBundle and PackBundle references..." -ForegroundColor Yellow
$content = $content -replace '<DeliveryBundle>', '&lt;DeliveryBundle&gt;'
$content = $content -replace '</DeliveryBundle>', '&lt;/DeliveryBundle&gt;'
$content = $content -replace '<PackBundle>', '&lt;PackBundle&gt;'
$content = $content -replace '</PackBundle>', '&lt;/PackBundle&gt;'

# Fix 5: Fix <string, tags
Write-Host "5. Fixing string, references..." -ForegroundColor Yellow
$content = $content -replace '<string,', '&lt;string,'

# Save the fixed content
$content | Set-Content $file -NoNewline

Write-Host "`nSyntax fixes applied!" -ForegroundColor Green
Write-Host "Run test-compile.bat to verify." -ForegroundColor Cyan