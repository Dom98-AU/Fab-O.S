# Careful fix for PackageWorksheets.razor structure

$file = "PackageWorksheets.razor"
Write-Host "Carefully fixing $file structure..." -ForegroundColor Cyan

# Read the file
$content = Get-Content $file -Raw

# First, let's remove the problematic Console.WriteLine statements that might be outside of code blocks
Write-Host "1. Removing any Console.WriteLine outside of proper code blocks..." -ForegroundColor Yellow

# Find and fix any Console.WriteLine that's not in a proper @{ } block
$pattern = '(?<!@\{[^}]*)\bConsole\.WriteLine\([^)]+\);?\s*(?![^{]*\})'
$content = $content -replace $pattern, ''

# Fix the div structure around the toast notifications
Write-Host "2. Fixing div structure around toast notifications..." -ForegroundColor Yellow

# The toast container needs proper closing
$toastPattern = '(\s+)@\* Toast notifications for field changes \*@\s*\r?\n\s*<div class="toast-container">'
$content = $content -replace $toastPattern, '$1@* Toast notifications for field changes *@$1<div class="toast-container">'

# Ensure the else block closes properly before @code
Write-Host "3. Ensuring else block closes properly..." -ForegroundColor Yellow

# Find the @code block
$codeIndex = $content.IndexOf('@code {')
if ($codeIndex -gt 0) {
    # Look backwards from @code to find the proper closing structure
    $beforeCode = $content.Substring(0, $codeIndex)
    
    # Count open and close divs in the else block
    $elseIndex = $beforeCode.LastIndexOf("`nelse`n")
    if ($elseIndex -gt 0) {
        $elseContent = $beforeCode.Substring($elseIndex)
        $openDivs = ([regex]::Matches($elseContent, '<div[^>]*>')).Count
        $closeDivs = ([regex]::Matches($elseContent, '</div>')).Count
        
        Write-Host "  In else block: $openDivs open divs, $closeDivs close divs" -ForegroundColor Gray
        
        # Ensure proper closing structure before @code
        # Should be: </div></div></div>}
        $endPattern = '\s*</div>\s*</div>\s*}\s*(?=@code)'
        if ($content -match $endPattern) {
            Write-Host "  Else block appears to have closing structure" -ForegroundColor Green
        } else {
            Write-Host "  Adding proper closing structure to else block" -ForegroundColor Yellow
            # Insert proper closing before @code
            $content = $content -replace '(\s*)(@code \{)', "        </div>`r`n    </div>`r`n</div>`r`n}`r`n`r`n`$2"
        }
    }
}

# Save the fixed content
$content | Set-Content $file -NoNewline

Write-Host "`nFix applied!" -ForegroundColor Green
Write-Host "Run test-compile.bat to verify." -ForegroundColor Cyan