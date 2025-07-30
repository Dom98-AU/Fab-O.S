# Comprehensive analysis of PackageWorksheets.razor

$file = "PackageWorksheets.razor"
Write-Host "Performing comprehensive analysis of $file..." -ForegroundColor Cyan

# Read all lines
$lines = Get-Content $file
$content = Get-Content $file -Raw

Write-Host "`n=== File Structure Analysis ===" -ForegroundColor Yellow

# Find key sections
$pageDirectiveLine = -1
$ifBlockLine = -1
$elseLine = -1
$codeLine = -1

for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^@page') {
        $pageDirectiveLine = $i + 1
    }
    if ($lines[$i] -match '@if \(!_isDataLoaded') {
        $ifBlockLine = $i + 1
    }
    if ($lines[$i] -eq 'else') {
        $elseLine = $i + 1
    }
    if ($lines[$i] -eq '@code {') {
        $codeLine = $i + 1
    }
}

Write-Host "Key sections found at lines:" -ForegroundColor Gray
Write-Host "  @page directive: $pageDirectiveLine" -ForegroundColor Gray
Write-Host "  @if block: $ifBlockLine" -ForegroundColor Gray
Write-Host "  else block: $elseLine" -ForegroundColor Gray
Write-Host "  @code block: $codeLine" -ForegroundColor Gray

# Analyze tag balance in different sections
Write-Host "`n=== Tag Balance Analysis ===" -ForegroundColor Yellow

# Function to count tags
function Count-Tags {
    param($text)
    
    $openDivs = ([regex]::Matches($text, '<div[^>]*>')).Count
    $closeDivs = ([regex]::Matches($text, '</div>')).Count
    $openNav = ([regex]::Matches($text, '<nav[^>]*>')).Count
    $closeNav = ([regex]::Matches($text, '</nav>')).Count
    
    return @{
        OpenDivs = $openDivs
        CloseDivs = $closeDivs
        DivBalance = $openDivs - $closeDivs
        OpenNav = $openNav
        CloseNav = $closeNav
        NavBalance = $openNav - $closeNav
    }
}

# Analyze the else block
if ($elseLine -gt 0 -and $codeLine -gt 0) {
    $elseContent = ""
    for ($i = $elseLine - 1; $i -lt $codeLine - 1; $i++) {
        $elseContent += $lines[$i] + "`n"
    }
    
    $elseTags = Count-Tags $elseContent
    Write-Host "In else block:" -ForegroundColor Gray
    Write-Host "  DIVs: $($elseTags.OpenDivs) open, $($elseTags.CloseDivs) close (balance: $($elseTags.DivBalance))" -ForegroundColor Gray
    Write-Host "  NAVs: $($elseTags.OpenNav) open, $($elseTags.CloseNav) close (balance: $($elseTags.NavBalance))" -ForegroundColor Gray
}

# Check for specific issues
Write-Host "`n=== Specific Issues Found ===" -ForegroundColor Yellow

# 1. Check nav structure around line 200
if ($elseLine -gt 0) {
    $navLine = $elseLine + 5  # approximately where nav should be
    if ($navLine -lt $lines.Count) {
        Write-Host "Around nav tag (line ~$navLine):" -ForegroundColor Gray
        for ($i = [Math]::Max(0, $navLine - 3); $i -lt [Math]::Min($lines.Count, $navLine + 3); $i++) {
            Write-Host "  $($i + 1): $($lines[$i])" -ForegroundColor Gray
        }
    }
}

# 2. Check for problematic patterns
$issues = @()

# Check for stray ");
if ($content -match '"\);') {
    $issues += "Found stray `"); pattern that may cause parsing errors"
}

# Check for <WeldingItem> tags
$weldingTags = ([regex]::Matches($content, '</?WeldingItem>')).Count
if ($weldingTags -gt 0) {
    $issues += "Found $weldingTags <WeldingItem> tags that need escaping"
}

# Check for <string> tags
$stringTags = ([regex]::Matches($content, '</?string[>,]')).Count
if ($stringTags -gt 0) {
    $issues += "Found $stringTags <string> tags that need escaping"
}

# Display issues
if ($issues.Count -gt 0) {
    foreach ($issue in $issues) {
        Write-Host "  - $issue" -ForegroundColor Red
    }
} else {
    Write-Host "  No specific syntax issues found" -ForegroundColor Green
}

Write-Host "`n=== Recommendations ===" -ForegroundColor Cyan
Write-Host "1. Add $($elseTags.DivBalance) closing </div> tags in else block" -ForegroundColor Yellow
if ($elseTags.NavBalance -ne 0) {
    Write-Host "2. Fix nav tag balance" -ForegroundColor Yellow
}
Write-Host "3. Fix any syntax issues identified above" -ForegroundColor Yellow