# PowerShell script to fix div structure in PackageWorksheets.razor

$file = "PackageWorksheets.razor"
Write-Host "Fixing div structure in $file..." -ForegroundColor Cyan

# Read the file
$content = Get-Content $file -Raw

# Fix the indentation and structure around line 1399-1401
# The issue is that there's an extra </div> at line 1400

# Replace the problematic section
$oldPattern = @"
                </div>
            </div>
        }
    </div>
    </div>
}

@code {
"@

$newPattern = @"
                </div>
            </div>
        }
    </div>
        </div>
    </div>
}

@code {
"@

# Perform the replacement
$content = $content.Replace($oldPattern, $newPattern)

# Save the fixed file
$content | Set-Content $file -NoNewline

Write-Host "Fixed div structure. The closing divs now properly close:" -ForegroundColor Green
Write-Host "  - toast-container" -ForegroundColor Gray
Write-Host "  - worksheet-content-wrapper" -ForegroundColor Gray  
Write-Host "  - worksheet-page-container" -ForegroundColor Gray
Write-Host "`nRun test-compile.bat to verify the fix." -ForegroundColor Yellow