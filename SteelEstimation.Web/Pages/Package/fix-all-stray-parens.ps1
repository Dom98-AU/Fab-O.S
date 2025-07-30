# Fix all stray "); instances in PackageWorksheets.razor

$file = "PackageWorksheets.razor"
Write-Host "Fixing all stray `"); instances..." -ForegroundColor Cyan

# Read the file
$content = Get-Content $file -Raw

# Count before
$beforeCount = ([regex]::Matches($content, '"\);')).Count
Write-Host "Found $beforeCount instances of stray `");" -ForegroundColor Yellow

# Replace all instances of "); with just ");
# This pattern is likely from Console.WriteLine statements
$content = $content -replace '"\);', '");'

# Count after
$afterCount = ([regex]::Matches($content, '"\);')).Count
Write-Host "After fix: $afterCount instances remaining" -ForegroundColor Green

# Save the file
$content | Set-Content $file -NoNewline -Encoding UTF8

Write-Host "`nFixed $($beforeCount - $afterCount) instances!" -ForegroundColor Green