Write-Host "Getting first compilation error..." -ForegroundColor Cyan
cd SteelEstimation.Web

$output = dotnet build --no-restore 2>&1 | Out-String
$lines = $output -split "`n"

# Find the first RZ error
$firstError = $lines | Where-Object { $_ -match "error RZ" } | Select-Object -First 1

if ($firstError) {
    Write-Host "`nFirst Razor error:" -ForegroundColor Yellow
    Write-Host $firstError -ForegroundColor Red
    
    # Extract line number
    if ($firstError -match '\((\d+),\d+\)') {
        $lineNum = [int]$matches[1]
        Write-Host "`nError is at line $lineNum" -ForegroundColor Yellow
        
        # Read that line from the file
        $fileLines = Get-Content "Pages\Package\PackageWorksheets.razor"
        if ($lineNum -le $fileLines.Count) {
            Write-Host "`nContext around line $lineNum`:" -ForegroundColor Cyan
            for ($i = [Math]::Max(0, $lineNum - 3); $i -lt [Math]::Min($fileLines.Count, $lineNum + 2); $i++) {
                $prefix = if ($i -eq $lineNum - 1) { ">>> " } else { "    " }
                Write-Host "$prefix$($i + 1): $($fileLines[$i])" -ForegroundColor Gray
            }
        }
    }
}

cd ..