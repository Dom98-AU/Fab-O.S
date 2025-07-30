# Simple fix for PackageWorksheets.razor

$file = "PackageWorksheets.razor"
Write-Host "Applying simple fix to $file..." -ForegroundColor Cyan

# Create backup
Copy-Item $file "$file.simple-backup"

# Read all lines
$lines = Get-Content $file

# Find the line with @code
$codeLineIndex = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -eq '@code {') {
        $codeLineIndex = $i
        break
    }
}

if ($codeLineIndex -eq -1) {
    Write-Host "Could not find @code block!" -ForegroundColor Red
    exit 1
}

Write-Host "Found @code at line $($codeLineIndex + 1)" -ForegroundColor Yellow

# Check the lines right before @code
Write-Host "`nLines before @code:" -ForegroundColor Yellow
for ($i = [Math]::Max(0, $codeLineIndex - 5); $i -lt $codeLineIndex; $i++) {
    Write-Host "$($i + 1): $($lines[$i])" -ForegroundColor Gray
}

# The correct structure should have these lines before @code:
#             </div>  (closes toast div)
#         </div>      (closes toast-container)  
#     </div>          (closes worksheet-content-wrapper)
# </div>              (closes worksheet-page-container)
# }                   (closes else block)
# 
# @code {

# Fix the indentation of the closing divs
if ($codeLineIndex -ge 5) {
    $lines[$codeLineIndex - 5] = "            </div>"
    $lines[$codeLineIndex - 4] = "        </div>"
    $lines[$codeLineIndex - 3] = "    </div>"
    $lines[$codeLineIndex - 2] = "</div>"
    $lines[$codeLineIndex - 1] = "}"
}

# Save the fixed file
$lines | Set-Content $file

Write-Host "`nFixed! The structure before @code is now:" -ForegroundColor Green
for ($i = [Math]::Max(0, $codeLineIndex - 5); $i -lt $codeLineIndex; $i++) {
    Write-Host "$($i + 1): $($lines[$i])" -ForegroundColor Gray
}