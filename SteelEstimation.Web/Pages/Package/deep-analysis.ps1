# Deep structural analysis of PackageWorksheets.razor

$file = "PackageWorksheets.razor"
Write-Host "Performing deep structural analysis..." -ForegroundColor Cyan

$lines = Get-Content $file
$inCodeBlock = $false
$inComment = $false
$divStack = @()
$lineNum = 0

Write-Host "`nAnalyzing div tags line by line..." -ForegroundColor Yellow

foreach ($line in $lines) {
    $lineNum++
    
    # Track if we're in @code block
    if ($line -match '^@code \{') {
        $inCodeBlock = $true
        Write-Host "Line ${lineNum}: Entered @code block" -ForegroundColor Green
        break  # Stop analyzing after @code
    }
    
    # Skip comment lines
    if ($line -match '@\*') { $inComment = $true }
    if ($line -match '\*@') { $inComment = $false; continue }
    if ($inComment) { continue }
    
    # Count opening divs
    $openDivMatches = [regex]::Matches($line, '<div[^/>]*>')
    foreach ($match in $openDivMatches) {
        $divStack += @{Line = $lineNum; Content = $line.Trim()}
        if ($lineNum -ge 190 -and $lineNum -le 210) {
            Write-Host "Line ${lineNum}: OPEN div - Stack depth: $($divStack.Count)" -ForegroundColor Yellow
        }
    }
    
    # Count closing divs
    $closeDivMatches = [regex]::Matches($line, '</div>')
    foreach ($match in $closeDivMatches) {
        if ($divStack.Count -gt 0) {
            $removed = $divStack[-1]
            $divStack = $divStack[0..($divStack.Count - 2)]
            if ($lineNum -ge 1390 -and $lineNum -le 1410) {
                Write-Host "Line ${lineNum}: CLOSE div - Stack depth: $($divStack.Count)" -ForegroundColor Cyan
            }
        } else {
            Write-Host "Line ${lineNum}: ERROR - Closing div with no matching open!" -ForegroundColor Red
            Write-Host "  Content: $($line.Trim())" -ForegroundColor Gray
        }
    }
}

Write-Host "`n=== Final Analysis ===" -ForegroundColor Yellow
Write-Host "Unclosed divs remaining: $($divStack.Count)" -ForegroundColor $(if ($divStack.Count -eq 0) { 'Green' } else { 'Red' })

if ($divStack.Count -gt 0) {
    Write-Host "`nUnclosed divs:" -ForegroundColor Red
    foreach ($div in $divStack) {
        Write-Host "  Line $($div.Line): $($div.Content)" -ForegroundColor Gray
    }
}