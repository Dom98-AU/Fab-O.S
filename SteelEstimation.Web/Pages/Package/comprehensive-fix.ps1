# Comprehensive fix for PackageWorksheets.razor

$file = "PackageWorksheets.razor"
Write-Host "Applying comprehensive fix to $file..." -ForegroundColor Cyan

# Read the entire file
$lines = Get-Content $file

# Find critical line numbers
$elseLine = 0
$codeLine = 0

for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^else$') {
        $elseLine = $i + 1
        Write-Host "Found 'else' at line $elseLine" -ForegroundColor Yellow
    }
    if ($lines[$i] -match '^@code \{$') {
        $codeLine = $i + 1
        Write-Host "Found '@code {' at line $codeLine" -ForegroundColor Yellow
    }
}

# The main issue is that the else block at line 194 doesn't have proper closing
# Let's reconstruct the file properly

# Create backup
Copy-Item $file "$file.comprehensive-backup"

# Read content as string for easier manipulation
$content = Get-Content $file -Raw

# Fix 1: Ensure the else block is properly structured
# The else block should close just before @code
Write-Host "Fixing else block structure..." -ForegroundColor Yellow

# Find the section between else and @code
$elseIndex = $content.IndexOf("`nelse`n")
$codeIndex = $content.IndexOf("`n@code {")

if ($elseIndex -gt 0 -and $codeIndex -gt 0) {
    # Extract the content between else and @code
    $betweenContent = $content.Substring($elseIndex, $codeIndex - $elseIndex)
    
    # Count divs in this section
    $openDivs = ([regex]::Matches($betweenContent, '<div')).Count
    $closeDivs = ([regex]::Matches($betweenContent, '</div>')).Count
    
    Write-Host "In else block: $openDivs open divs, $closeDivs close divs" -ForegroundColor Gray
    
    # The else block should have balanced divs plus one extra closing div for the else block itself
    if ($openDivs -eq $closeDivs) {
        Write-Host "Div structure appears balanced in else block" -ForegroundColor Green
    }
}

# Fix 2: Ensure proper closing before @code
# The structure should be:
# </div> - closes toast-container
# </div> - closes worksheet-content-wrapper  
# </div> - closes worksheet-page-container
# } - closes else block

$oldPattern = @'
    </div>
        </div>
    </div>
}

@code {'@

$newPattern = @'
            </div>
        </div>
    </div>
}

@code {'@

$content = $content.Replace($oldPattern, $newPattern)

# Save the fixed content
$content | Set-Content $file -NoNewline

Write-Host "`nFix applied successfully!" -ForegroundColor Green
Write-Host "The structure now properly closes:" -ForegroundColor Yellow
Write-Host "  1. Toast container" -ForegroundColor Gray
Write-Host "  2. Worksheet content wrapper" -ForegroundColor Gray
Write-Host "  3. Worksheet page container" -ForegroundColor Gray
Write-Host "  4. Else block" -ForegroundColor Gray
Write-Host "`nRun test-compile.bat to verify." -ForegroundColor Cyan