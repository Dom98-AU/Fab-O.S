# Minimal surgical fix for PackageWorksheets.razor
# This script makes only the absolute minimum changes needed

$file = "PackageWorksheets.razor"
Write-Host "Applying minimal surgical fix to $file..." -ForegroundColor Cyan

# Read the file
$content = Get-Content $file -Raw

# Fix 1: Remove the stray "); that's causing parsing issues
Write-Host "1. Removing stray '); ..." -ForegroundColor Yellow
$content = $content -replace '\s+private void SetFilter\(string filter\)\s*\{\s*"\);', '    private void SetFilter(string filter)
    {'

# Fix 2: Ensure the else block closes properly
# The structure should have balanced divs within the else block
Write-Host "2. Checking else block structure..." -ForegroundColor Yellow

# Count divs between else and @code
$elseMatch = [regex]::Match($content, '(?m)^else\s*$')
$codeMatch = [regex]::Match($content, '(?m)^@code \{')

if ($elseMatch.Success -and $codeMatch.Success) {
    $betweenContent = $content.Substring($elseMatch.Index + $elseMatch.Length, $codeMatch.Index - ($elseMatch.Index + $elseMatch.Length))
    
    # Count braces and divs
    $openBraces = ([regex]::Matches($betweenContent, '\{')).Count
    $closeBraces = ([regex]::Matches($betweenContent, '\}')).Count
    $openDivs = ([regex]::Matches($betweenContent, '<div')).Count
    $closeDivs = ([regex]::Matches($betweenContent, '</div>')).Count
    
    Write-Host "  Between else and @code:" -ForegroundColor Gray
    Write-Host "    Braces: $openBraces open, $closeBraces close" -ForegroundColor Gray
    Write-Host "    Divs: $openDivs open, $closeDivs close" -ForegroundColor Gray
}

# Save the fixed content
$content | Set-Content $file -NoNewline

Write-Host "`nMinimal fix applied!" -ForegroundColor Green
Write-Host "Run compilation to check if this resolves the main issues." -ForegroundColor Cyan