# Fix complete structure of PackageWorksheets.razor

$file = "PackageWorksheets.razor"
Write-Host "Fixing complete structure of $file..." -ForegroundColor Cyan

# Read all lines
$lines = Get-Content $file

# The structure should be:
# else {
#     <div class="worksheet-page-container">
#         <div class="worksheet-content-wrapper">
#             ... (breadcrumb, tabs, etc.)
#             <div class="tab-content">
#                 @if (activeWorksheet != null) {
#                     ... (worksheet content)
#                 }
#             </div>
#             @* Toast notifications *@
#             <div class="toast-container">
#                 ... (toast content)
#             </div>
#         </div>
#     </div>
# }

# Find the lines to fix
$toastStartLine = -1
$codeBlockLine = -1

for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '@\* Toast notifications for field changes \*@') {
        $toastStartLine = $i
    }
    if ($lines[$i] -eq '@code {') {
        $codeBlockLine = $i
    }
}

Write-Host "Found toast notifications at line $($toastStartLine + 1)" -ForegroundColor Yellow
Write-Host "Found @code block at line $($codeBlockLine + 1)" -ForegroundColor Yellow

# Fix the structure
if ($toastStartLine -gt 0) {
    # Remove the extra closing tags before toast container
    # Line 1372 should close the @if block
    # Line 1373 should close the tab-content div
    # Then toast container should be inside worksheet-content-wrapper
    
    # Fix line before toast notifications
    if ($toastStartLine -gt 2) {
        $lines[$toastStartLine - 2] = "        }"  # Close @if block
        $lines[$toastStartLine - 1] = "    </div>"  # Close tab-content
    }
}

# Fix the closing structure before @code
if ($codeBlockLine -gt 5) {
    # The proper closing should be:
    $lines[$codeBlockLine - 5] = "            </div>"  # Close last toast div
    $lines[$codeBlockLine - 4] = "        }"           # Close foreach
    $lines[$codeBlockLine - 3] = "    </div>"          # Close toast-container
    $lines[$codeBlockLine - 2] = "    </div>"          # Close worksheet-content-wrapper
    $lines[$codeBlockLine - 1] = "</div>"              # Close worksheet-page-container
    
    # Add closing brace for else on next line
    $updatedLines = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $updatedLines += $lines[$i]
        if ($i -eq $codeBlockLine - 1) {
            $updatedLines += "}"  # Close else block
            $updatedLines += ""   # Empty line before @code
        }
    }
    $lines = $updatedLines
}

# Save the fixed file
$lines | Set-Content $file

Write-Host "`nStructure fixed!" -ForegroundColor Green
Write-Host "The file should now have proper nesting." -ForegroundColor Cyan