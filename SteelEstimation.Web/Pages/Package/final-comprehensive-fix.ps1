# Final comprehensive fix for PackageWorksheets.razor

$file = "PackageWorksheets.razor"
Write-Host "Applying final comprehensive fix to $file..." -ForegroundColor Cyan

# Read all lines
$lines = Get-Content $file

# Find key line numbers
$elseLine = -1
$codeLine = -1

for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -eq 'else') {
        $elseLine = $i
    }
    if ($lines[$i] -eq '@code {') {
        $codeLine = $i
    }
}

Write-Host "Found else at line $($elseLine + 1)" -ForegroundColor Yellow
Write-Host "Found @code at line $($codeLine + 1)" -ForegroundColor Yellow

# Fix the structure before @code block
# We need exactly 3 closing divs and 1 closing brace before @code
if ($codeLine -gt 5) {
    # Check what's currently there
    Write-Host "`nCurrent structure before @code:" -ForegroundColor Yellow
    for ($i = $codeLine - 5; $i -lt $codeLine; $i++) {
        Write-Host "  Line $($i + 1): $($lines[$i])" -ForegroundColor Gray
    }
    
    # Clear any empty lines and set proper structure
    $properClosing = @(
        "            </div>",     # Close toast div
        "        </div>",         # Close toast-container
        "    </div>",            # Close worksheet-content-wrapper
        "</div>",                # Close worksheet-page-container
        "}"                      # Close else block
    )
    
    # Replace the lines before @code
    $j = 0
    for ($i = $codeLine - 5; $i -lt $codeLine; $i++) {
        if ($j -lt $properClosing.Count) {
            $lines[$i] = $properClosing[$j]
            $j++
        } else {
            $lines[$i] = ""
        }
    }
    
    Write-Host "`nFixed structure before @code:" -ForegroundColor Green
    for ($i = $codeLine - 5; $i -lt $codeLine; $i++) {
        Write-Host "  Line $($i + 1): $($lines[$i])" -ForegroundColor Gray
    }
}

# Save the fixed file
$lines | Set-Content $file

Write-Host "`nComprehensive fix applied!" -ForegroundColor Green
Write-Host "The file should now compile correctly." -ForegroundColor Cyan