# Validate structure of PackageWorksheets.razor

$file = "PackageWorksheets.razor"
Write-Host "Validating structure of $file..." -ForegroundColor Cyan

# Read the file
$content = Get-Content $file -Raw

# Find key blocks
$ifDataLoaded = [regex]::Match($content, '@if \(!_isDataLoaded.*?\)')
$elseLine = $content.IndexOf("`nelse`n", $ifDataLoaded.Index)
$codeIndex = $content.IndexOf("`n@code {")

Write-Host "`nKey positions:" -ForegroundColor Yellow
Write-Host "  @if (!_isDataLoaded...) at position: $($ifDataLoaded.Index)" -ForegroundColor Gray
Write-Host "  else at position: $elseLine" -ForegroundColor Gray
Write-Host "  @code at position: $codeIndex" -ForegroundColor Gray

# Extract the three main sections
$beforeElse = $content.Substring(0, $elseLine)
$elseToCode = $content.Substring($elseLine, $codeIndex - $elseLine)
$afterCode = $content.Substring($codeIndex)

# Count tags in each section
Write-Host "`nTag counts:" -ForegroundColor Yellow

# In the else block
$elseOpenDivs = ([regex]::Matches($elseToCode, '<div')).Count
$elseCloseDivs = ([regex]::Matches($elseToCode, '</div>')).Count
$elseOpenBraces = ([regex]::Matches($elseToCode, '\{')).Count
$elseCloseBraces = ([regex]::Matches($elseToCode, '\}')).Count

Write-Host "  In else block:" -ForegroundColor Gray
Write-Host "    Open divs: $elseOpenDivs" -ForegroundColor Gray
Write-Host "    Close divs: $elseCloseDivs" -ForegroundColor Gray
Write-Host "    Div balance: $($elseOpenDivs - $elseCloseDivs)" -ForegroundColor $(if ($elseOpenDivs -eq $elseCloseDivs) { 'Green' } else { 'Red' })
Write-Host "    Open braces: $elseOpenBraces" -ForegroundColor Gray
Write-Host "    Close braces: $elseCloseBraces" -ForegroundColor Gray
Write-Host "    Brace balance: $($elseOpenBraces - $elseCloseBraces)" -ForegroundColor $(if ($elseOpenBraces -eq $elseCloseBraces) { 'Green' } else { 'Red' })

# Check for problematic patterns
Write-Host "`nChecking for common issues:" -ForegroundColor Yellow

# Check for <WeldingItem> tags that should be escaped
$weldingItemTags = [regex]::Matches($elseToCode, '</?WeldingItem>')
if ($weldingItemTags.Count -gt 0) {
    Write-Host "  Found $($weldingItemTags.Count) <WeldingItem> tags that may need escaping" -ForegroundColor Red
}

# Check for <string> tags
$stringTags = [regex]::Matches($elseToCode, '</?string>')
if ($stringTags.Count -gt 0) {
    Write-Host "  Found $($stringTags.Count) <string> tags that may need escaping" -ForegroundColor Red
}

Write-Host "`nRecommendation:" -ForegroundColor Cyan
if ($elseOpenDivs -ne $elseCloseDivs) {
    Write-Host "  Need to add $([Math]::Abs($elseOpenDivs - $elseCloseDivs)) closing </div> tags in the else block" -ForegroundColor Yellow
}
if ($elseOpenBraces -ne $elseCloseBraces - 1) {  # -1 because we expect one extra closing brace for the else block
    Write-Host "  Brace count issue - should have exactly 1 more closing brace than opening braces" -ForegroundColor Yellow
}