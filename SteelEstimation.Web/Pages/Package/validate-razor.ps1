# PowerShell script to validate Razor file structure
$file = "PackageWorksheets.razor"

Write-Host "Validating $file structure..." -ForegroundColor Cyan

# Count opening and closing div tags
$content = Get-Content $file -Raw
$openDivs = ([regex]::Matches($content, '<div')).Count
$closeDivs = ([regex]::Matches($content, '</div>')).Count

Write-Host "Opening divs: $openDivs" -ForegroundColor Yellow
Write-Host "Closing divs: $closeDivs" -ForegroundColor Yellow

if ($openDivs -eq $closeDivs) {
    Write-Host "✓ DIV tags are balanced" -ForegroundColor Green
} else {
    Write-Host "✗ DIV tags are NOT balanced (difference: $($openDivs - $closeDivs))" -ForegroundColor Red
}

# Check for @code block
if ($content -match '@code\s*{') {
    Write-Host "✓ @code block found" -ForegroundColor Green
} else {
    Write-Host "✗ @code block not found" -ForegroundColor Red
}

# Check for common Razor syntax errors
$razorErrors = @()

# Check for unclosed @if/@foreach blocks
$ifCount = ([regex]::Matches($content, '@if\s*\(')).Count
$foreachCount = ([regex]::Matches($content, '@foreach\s*\(')).Count
$openBraces = ([regex]::Matches($content, '(?<!@code\s*){(?![^"]*")')).Count
$closeBraces = ([regex]::Matches($content, '}(?![^"]*")')).Count

Write-Host "`n@if blocks: $ifCount" -ForegroundColor Yellow
Write-Host "@foreach blocks: $foreachCount" -ForegroundColor Yellow
Write-Host "Open braces: $openBraces" -ForegroundColor Yellow
Write-Host "Close braces: $closeBraces" -ForegroundColor Yellow

# Look for common indentation issues
$lines = $content -split "`r?`n"
$lineNum = 0
$indentIssues = @()

foreach ($line in $lines) {
    $lineNum++
    if ($line -match '^\s+</' -and $line -notmatch '^\s{4,}') {
        $indentIssues += "Line $lineNum: Possible indentation issue - closing tag"
    }
}

if ($indentIssues.Count -gt 0) {
    Write-Host "`nPotential indentation issues:" -ForegroundColor Yellow
    $indentIssues | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
}

Write-Host "`nValidation complete." -ForegroundColor Cyan