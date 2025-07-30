# Find all potential issues in PackageWorksheets.razor

$file = "PackageWorksheets.razor"
Write-Host "Searching for all potential issues..." -ForegroundColor Cyan

$content = Get-Content $file -Raw

# Check for various problematic patterns
$issues = @()

# 1. Stray ");
$strayParens = [regex]::Matches($content, '"\);')
if ($strayParens.Count -gt 0) {
    $issues += "Found $($strayParens.Count) instances of stray `");"
    foreach ($match in $strayParens) {
        $lineNum = ($content.Substring(0, $match.Index) -split "`n").Count
        Write-Host "  Line ~$lineNum" -ForegroundColor Gray
    }
}

# 2. <WeldingItem> tags
$weldingTags = [regex]::Matches($content, '</?WeldingItem>')
if ($weldingTags.Count -gt 0) {
    $issues += "Found $($weldingTags.Count) <WeldingItem> tags"
}

# 3. Dictionary<string, pattern
$dictPattern = [regex]::Matches($content, 'Dictionary<string,')
if ($dictPattern.Count -gt 0) {
    $issues += "Found $($dictPattern.Count) Dictionary<string, patterns that may need escaping"
}

# 4. List<string> pattern
$listPattern = [regex]::Matches($content, 'List<string>')
if ($listPattern.Count -gt 0) {
    $issues += "Found $($listPattern.Count) List<string> patterns that may need escaping"
}

# 5. Multiline strings with @"
$multilineStrings = [regex]::Matches($content, '@"')
if ($multilineStrings.Count -gt 0) {
    $issues += "Found $($multilineStrings.Count) multiline string literals (@`")"
    foreach ($match in $multilineStrings) {
        $lineNum = ($content.Substring(0, $match.Index) -split "`n").Count
        Write-Host "  Multiline string at line ~$lineNum" -ForegroundColor Yellow
    }
}

Write-Host "`nIssues found:" -ForegroundColor Yellow
foreach ($issue in $issues) {
    Write-Host "  - $issue" -ForegroundColor Red
}

# Check if SetFilter has the stray ");
$setFilterMatch = [regex]::Match($content, 'private void SetFilter\([^)]+\)\s*\{[^}]*\}')
if ($setFilterMatch.Success) {
    $setFilterContent = $setFilterMatch.Value
    if ($setFilterContent -match '"\);') {
        Write-Host "`nCRITICAL: SetFilter method contains stray `"); at line ~4208" -ForegroundColor Red
    }
}