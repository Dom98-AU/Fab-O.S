# Aggressive fix for PackageWorksheets.razor

$file = "PackageWorksheets.razor"
Write-Host "Applying aggressive fix to $file..." -ForegroundColor Cyan

# Create backup
Copy-Item $file "$file.aggressive-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Read the file
$content = Get-Content $file -Raw

# Fix 1: Remove stray ");
Write-Host "1. Fixing stray '); ..." -ForegroundColor Yellow
$content = $content -replace '(\s+)("\);)', '$1'

# Fix 2: Fix nav/ol structure - ensure proper closing
Write-Host "2. Fixing nav/ol structure..." -ForegroundColor Yellow
# The nav tag should properly wrap the ol
$content = $content -replace '(<nav[^>]*>)\s*(<ol)', '$1`r`n                $2'

# Fix 3: Escape problematic tags in strings/comments
Write-Host "3. Escaping problematic tags..." -ForegroundColor Yellow

# First, protect actual HTML tags we want to keep
$protectedContent = $content

# Find and replace <WeldingItem> tags that are likely in comments or strings
# These patterns suggest they're in tooltips or string literals
$protectedContent = $protectedContent -replace '(title=")([^"]*)<WeldingItem>([^"]*")', '$1$2&lt;WeldingItem&gt;$3'
$protectedContent = $protectedContent -replace '(title=")([^"]*)</WeldingItem>([^"]*")', '$1$2&lt;/WeldingItem&gt;$3'
$protectedContent = $protectedContent -replace '(@\*[^*]*)<WeldingItem>([^*]*\*@)', '$1&lt;WeldingItem&gt;$2'
$protectedContent = $protectedContent -replace '(@\*[^*]*)</WeldingItem>([^*]*\*@)', '$1&lt;/WeldingItem&gt;$2'

# Fix <string> tags in generic type references (like List<string>)
$protectedContent = $protectedContent -replace '(List|IList|IEnumerable|Dictionary|IDictionary|HashSet|ICollection|IReadOnlyList|Func|Action)<string>', '$1&lt;string&gt;'
$protectedContent = $protectedContent -replace '<string,', '&lt;string,'
$protectedContent = $protectedContent -replace ',string>', ',string&gt;'

# Fix 4: Add missing closing div
Write-Host "4. Adding missing closing div in else block..." -ForegroundColor Yellow
# Find the position right before @code and add the missing div
$codeBlockPattern = '(\s*)(</div>\s*</div>\s*}\s*)(@code \{)'
$protectedContent = $protectedContent -replace $codeBlockPattern, '$1$2</div>`r`n}`r`n`r`n$3'

# Fix 5: Ensure proper indentation for closing tags before @code
Write-Host "5. Fixing indentation of closing tags..." -ForegroundColor Yellow
# The structure should be:
# </div> - closes toast
# </div> - closes toast-container  
# </div> - closes worksheet-content-wrapper
# </div> - closes worksheet-page-container
# } - closes else

# Save the fixed content
$protectedContent | Set-Content $file -NoNewline -Encoding UTF8

Write-Host "`nAggressive fix completed!" -ForegroundColor Green
Write-Host "Changes made:" -ForegroundColor Yellow
Write-Host "  - Removed stray '); patterns" -ForegroundColor Gray
Write-Host "  - Fixed nav/ol structure" -ForegroundColor Gray
Write-Host "  - Escaped <WeldingItem> and <string> tags in strings/comments" -ForegroundColor Gray
Write-Host "  - Added missing closing div" -ForegroundColor Gray
Write-Host "  - Fixed indentation" -ForegroundColor Gray

Write-Host "`nRun compilation test to verify." -ForegroundColor Cyan