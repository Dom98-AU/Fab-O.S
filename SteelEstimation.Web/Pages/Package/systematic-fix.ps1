# Systematic fix for PackageWorksheets.razor
$file = "PackageWorksheets.razor"
Write-Host "Applying systematic fix to $file..." -ForegroundColor Cyan

# Read the file
$content = Get-Content $file -Raw

# Fix 1: The main structural issue is likely the Console.WriteLine inside the if block
Write-Host "1. Fixing Console.WriteLine in if block..." -ForegroundColor Yellow
# Remove the Console.WriteLine that's causing parsing issues
$content = $content -replace '(@if \(!_isDataLoaded[^{]+\{)\s*Console\.WriteLine[^;]+;', '$1'

# Fix 2: Fix the stray "); that appears in SetFilter method
Write-Host "2. Fixing stray '); in SetFilter method..." -ForegroundColor Yellow
$content = $content -replace '(private void SetFilter\(string filter\)\s*\{)\s*"\);', '$1'

# Fix 3: Ensure the else block has proper closing
Write-Host "3. Checking else block structure..." -ForegroundColor Yellow
# The else block needs exactly 3 closing divs plus the closing brace
# Find the section right before @code
$codeIndex = $content.IndexOf('@code {')
if ($codeIndex -gt 0) {
    # Look for the pattern of closing divs before @code
    $beforeCode = $content.Substring([Math]::Max(0, $codeIndex - 500), [Math]::Min(500, $codeIndex))
    
    # Count the closing divs in this section
    $closingDivCount = ([regex]::Matches($beforeCode, '</div>')).Count
    Write-Host "  Found $closingDivCount closing divs before @code" -ForegroundColor Gray
    
    # The structure should end with:
    # </div> (toast div)
    # </div> (toast container)
    # </div> (worksheet-content-wrapper)
    # </div> (worksheet-page-container)
    # } (else block)
    
    # Ensure we have the right pattern
    $pattern = '(\s*)(</div>\s*</div>\s*}\s*)(@code \{)'
    $replacement = '$1        </div>`n    </div>`n    </div>`n</div>`n}`n`n$3'
    $content = $content -replace $pattern, $replacement
}

# Fix 4: Fix any literal backticks that might have been introduced
Write-Host "4. Fixing any literal backticks..." -ForegroundColor Yellow
$content = $content -replace '`n', "`n"
$content = $content -replace '`r', "`r"

# Save the fixed content
$content | Set-Content $file -NoNewline -Encoding UTF8

Write-Host "`nSystematic fix applied!" -ForegroundColor Green
Write-Host "Changes made:" -ForegroundColor Yellow
Write-Host "  - Removed Console.WriteLine from if block" -ForegroundColor Gray
Write-Host "  - Fixed stray '); syntax error" -ForegroundColor Gray
Write-Host "  - Ensured proper closing structure for else block" -ForegroundColor Gray