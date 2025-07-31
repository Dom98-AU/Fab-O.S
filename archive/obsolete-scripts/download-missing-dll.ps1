# Download and Install Missing DLL for Import/Export Wizard
Write-Host "=== Downloading Missing DLL ===" -ForegroundColor Cyan

# Create temp directory
$tempPath = "$env:TEMP\ssis-fix"
New-Item -ItemType Directory -Path $tempPath -Force | Out-Null

# Download the Integration Services NuGet package
Write-Host "Downloading SQL Server Integration Services package..." -ForegroundColor Yellow
$downloadUrl = "https://www.nuget.org/api/v2/package/Microsoft.SqlServer.IntegrationServices.Server/15.0.2000.5"
$zipPath = "$tempPath\ssis.zip"

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath
    Write-Host "Download complete!" -ForegroundColor Green
} catch {
    Write-Host "Download failed. Trying alternative source..." -ForegroundColor Yellow
    # Try alternative download
    $altUrl = "https://www.nuget.org/api/v2/package/Microsoft.SqlServer.Dts.Design/16.0.948"
    Invoke-WebRequest -Uri $altUrl -OutFile $zipPath
}

# Extract the package
Write-Host "Extracting package..." -ForegroundColor Yellow
Expand-Archive -Path $zipPath -DestinationPath "$tempPath\ssis" -Force

# Search for ScaleHelper.dll
Write-Host "Searching for Microsoft.DataTransformationServices.ScaleHelper.dll..." -ForegroundColor Yellow
$foundDlls = Get-ChildItem -Path "$tempPath\ssis" -Recurse -Filter "*ScaleHelper.dll" -ErrorAction SilentlyContinue

if ($foundDlls.Count -gt 0) {
    Write-Host "Found $($foundDlls.Count) DLL(s)!" -ForegroundColor Green
    
    # Copy to SQL Server DTS directory
    $targetPath = "C:\Program Files\Microsoft SQL Server\160\DTS\Binn"
    if (Test-Path $targetPath) {
        Write-Host "Copying to SQL Server directory..." -ForegroundColor Yellow
        foreach ($dll in $foundDlls) {
            try {
                Copy-Item -Path $dll.FullName -Destination "$targetPath\Microsoft.DataTransformationServices.ScaleHelper.dll" -Force
                Write-Host "Copied successfully to: $targetPath" -ForegroundColor Green
            } catch {
                Write-Host "Failed to copy. Run PowerShell as Administrator!" -ForegroundColor Red
            }
        }
    }
} else {
    Write-Host "DLL not found in package." -ForegroundColor Red
}

# Alternative: Direct download of the specific DLL
Write-Host "`nTrying direct DLL download..." -ForegroundColor Yellow
$dllUrl = "https://github.com/microsoft/sql-server-samples/raw/master/samples/features/sql-data-sync/DataSyncAgent/libs/Microsoft.DataTransformationServices.ScaleHelper.dll"
$dllPath = "$tempPath\Microsoft.DataTransformationServices.ScaleHelper.dll"

try {
    Invoke-WebRequest -Uri $dllUrl -OutFile $dllPath
    
    # Copy to required locations
    $targets = @(
        "C:\Program Files\Microsoft SQL Server\160\DTS\Binn",
        "C:\Program Files (x86)\Microsoft SQL Server\160\DTS\Binn"
    )
    
    foreach ($target in $targets) {
        if (Test-Path $target) {
            Copy-Item -Path $dllPath -Destination "$target\Microsoft.DataTransformationServices.ScaleHelper.dll" -Force -ErrorAction SilentlyContinue
            Write-Host "Copied to: $target" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "Direct download failed." -ForegroundColor Red
}

# Cleanup
Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`n=== Process Complete ===" -ForegroundColor Cyan
Write-Host "Try the Import/Export Wizard again!" -ForegroundColor Green
Write-Host "`nIf it still doesn't work:" -ForegroundColor Yellow
Write-Host "1. You MUST install Integration Services from SQL Server installer" -ForegroundColor White
Write-Host "2. Or use the migrate-to-azure.ps1 script instead" -ForegroundColor White