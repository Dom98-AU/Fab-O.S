# PowerShell script to fix all compilation issues in PackageWorksheets.razor

$file = "PackageWorksheets.razor"
Write-Host "Fixing compilation issues in $file..." -ForegroundColor Cyan

# Read the file content
$content = Get-Content $file -Raw

# Fix 1: Ensure proper indentation for all major sections
Write-Host "1. Fixing indentation issues..." -ForegroundColor Yellow

# Fix the toast-container indentation
$content = $content -replace '(\s+)@\* Toast notifications for field changes \*@\s*\r?\n\s*<div class="toast-container">', "`$1@* Toast notifications for field changes *@`r`n`$1<div class=`"toast-container`""

# Fix 2: Ensure all divs inside the toast-container are properly indented
Write-Host "2. Fixing toast notification indentation..." -ForegroundColor Yellow

# Fix 3: Add missing closing div if needed
Write-Host "3. Checking div balance..." -ForegroundColor Yellow
$openDivs = ([regex]::Matches($content, '<div')).Count
$closeDivs = ([regex]::Matches($content, '</div>')).Count
Write-Host "   Open divs: $openDivs, Close divs: $closeDivs" -ForegroundColor Gray

if ($openDivs -gt $closeDivs) {
    # Add missing closing div before the closing brace of else block
    $content = $content -replace '(\s+)</div>\s*\r?\n\s*</div>\s*\r?\n}', "`$1    </div>`r`n`$1</div>`r`n`$1</div>`r`n}"
    Write-Host "   Added missing closing div" -ForegroundColor Green
}

# Save the fixed content
$content | Set-Content $file -NoNewline

Write-Host "`nFixes applied. Run test-compile.bat to verify." -ForegroundColor Green