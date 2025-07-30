# PowerShell script to fix Razor structure issues
$file = "PackageWorksheets.razor"

Write-Host "Analyzing and fixing Razor structure issues..." -ForegroundColor Cyan

# Read the file
$content = Get-Content $file -Raw

# Find the location of @code block
$codeBlockIndex = $content.IndexOf("@code {")
if ($codeBlockIndex -eq -1) {
    Write-Host "ERROR: Could not find @code block!" -ForegroundColor Red
    exit 1
}

# Extract content before @code block
$beforeCode = $content.Substring(0, $codeBlockIndex)

# Count braces in the content before @code
$openBraces = ([regex]::Matches($beforeCode, '(?<!@code\s*){(?![^"]*")')).Count
$closeBraces = ([regex]::Matches($beforeCode, '}(?![^"]*")')).Count

Write-Host "Brace count before @code block:" -ForegroundColor Yellow
Write-Host "  Open braces: $openBraces" -ForegroundColor Gray
Write-Host "  Close braces: $closeBraces" -ForegroundColor Gray
Write-Host "  Balance: $($openBraces - $closeBraces)" -ForegroundColor Gray

# Check for common issues
Write-Host "`nChecking for common issues..." -ForegroundColor Yellow

# 1. Check if there's a Console.WriteLine in markup
if ($beforeCode -match 'Console\.WriteLine[^}]*}') {
    Write-Host "  Found Console.WriteLine in markup section - this needs to be in a code block" -ForegroundColor Red
}

# 2. Check div balance
$openDivs = ([regex]::Matches($beforeCode, '<div')).Count
$closeDivs = ([regex]::Matches($beforeCode, '</div>')).Count
Write-Host "  DIV balance: $openDivs open, $closeDivs close (diff: $($openDivs - $closeDivs))" -ForegroundColor Gray

# 3. Find the else block
$elseMatch = [regex]::Match($beforeCode, '(?m)^else\s*$')
if ($elseMatch.Success) {
    $lineNumber = ($beforeCode.Substring(0, $elseMatch.Index) -split "`n").Count
    Write-Host "  Found 'else' at line ~$lineNumber" -ForegroundColor Gray
    
    # Check what's right before the else
    $beforeElse = $beforeCode.Substring([Math]::Max(0, $elseMatch.Index - 200), [Math]::Min(200, $elseMatch.Index))
    if ($beforeElse -match '}\s*$') {
        Write-Host "  'else' block appears to be properly preceded by }" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: 'else' block may not be properly preceded by }" -ForegroundColor Red
    }
}

Write-Host "`nSummary:" -ForegroundColor Cyan
if ($openBraces -eq $closeBraces -and $openDivs -eq $closeDivs + 1) {
    Write-Host "  Structure appears to be correct (1 extra div is expected for the page container)" -ForegroundColor Green
} else {
    Write-Host "  Structure issues detected!" -ForegroundColor Red
}

Write-Host "`nTo fix remaining issues, ensure:" -ForegroundColor Yellow
Write-Host "  1. No C# code (like Console.WriteLine) is in the markup section outside of @{ } blocks"
Write-Host "  2. All HTML tags are properly closed"
Write-Host "  3. The @code block is at the root level (not inside any other block)"