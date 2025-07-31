# Fix Missing Microsoft.DataTransformationServices.ScaleHelper.dll
Write-Host "=== Fixing Missing DLL for Import/Export Wizard ===" -ForegroundColor Cyan

# The specific missing file
$missingDll = "Microsoft.DataTransformationServices.ScaleHelper.dll"
$requiredVersion = "16.0.0.0"

Write-Host "`nSearching for $missingDll..." -ForegroundColor Yellow

# Search in all possible locations
$searchPaths = @(
    "C:\Program Files\Microsoft Visual Studio",
    "C:\Program Files (x86)\Microsoft Visual Studio",
    "C:\Program Files\Microsoft SQL Server",
    "C:\Program Files (x86)\Microsoft SQL Server",
    "C:\Windows\Microsoft.NET\assembly\GAC_MSIL"
)

$foundDlls = @()
foreach ($searchPath in $searchPaths) {
    if (Test-Path $searchPath) {
        Write-Host "Searching in: $searchPath" -ForegroundColor Gray
        $found = Get-ChildItem -Path $searchPath -Recurse -Filter $missingDll -ErrorAction SilentlyContinue
        if ($found) {
            $foundDlls += $found
        }
    }
}

Write-Host "`nFound $($foundDlls.Count) instances of the DLL:" -ForegroundColor Green
foreach ($dll in $foundDlls) {
    Write-Host "  - $($dll.FullName)" -ForegroundColor Gray
    $version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($dll.FullName).FileVersion
    Write-Host "    Version: $version" -ForegroundColor Gray
}

# Target locations where the DLL needs to be
$targetLocations = @(
    "C:\Program Files\Microsoft SQL Server\160\DTS\Binn",
    "C:\Program Files (x86)\Microsoft SQL Server\160\DTS\Binn",
    "C:\Windows\Microsoft.NET\assembly\GAC_MSIL\Microsoft.DataTransformationServices.ScaleHelper\v4.0_16.0.0.0__89845dcd8080cc91"
)

# If we found the DLL, copy it to where it's needed
if ($foundDlls.Count -gt 0) {
    Write-Host "`nCopying DLL to required locations..." -ForegroundColor Yellow
    
    $sourceDll = $foundDlls[0]
    foreach ($target in $targetLocations) {
        $targetDir = Split-Path $target -Parent
        if (-not $targetDir) {
            $targetDir = $target
        }
        if (Test-Path $targetDir) {
            try {
                Copy-Item -Path $sourceDll.FullName -Destination "$targetDir\$missingDll" -Force
                Write-Host "  ✓ Copied to: $targetDir" -ForegroundColor Green
            } catch {
                Write-Host "  ✗ Failed to copy to: $targetDir (may need admin rights)" -ForegroundColor Red
            }
        }
    }
} else {
    Write-Host "`nDLL not found locally. Downloading from NuGet..." -ForegroundColor Yellow
    
    # Download the NuGet package that contains this DLL
    $nugetUrl = "https://www.nuget.org/api/v2/package/Microsoft.SqlServer.IntegrationServices.Server/16.0.5"
    $tempPath = "$env:TEMP\ssis-temp"
    New-Item -ItemType Directory -Path $tempPath -Force | Out-Null
    
    Write-Host "Downloading SSIS package..." -ForegroundColor Gray
    Invoke-WebRequest -Uri $nugetUrl -OutFile "$tempPath\ssis.zip"
    
    Write-Host "Extracting..." -ForegroundColor Gray
    Expand-Archive -Path "$tempPath\ssis.zip" -DestinationPath "$tempPath\ssis" -Force
    
    # Search for the DLL in the package
    $packageDll = Get-ChildItem -Path "$tempPath\ssis" -Recurse -Filter $missingDll -ErrorAction SilentlyContinue
    
    if ($packageDll) {
        Write-Host "Found DLL in package!" -ForegroundColor Green
        
        foreach ($target in $targetLocations) {
            $targetDir = Split-Path $target -Parent
            if (-not $targetDir) {
                $targetDir = $target
            }
            if (Test-Path $targetDir) {
                try {
                    Copy-Item -Path $packageDll[0].FullName -Destination "$targetDir\$missingDll" -Force
                    Write-Host "  ✓ Copied to: $targetDir" -ForegroundColor Green
                } catch {
                    Write-Host "  ✗ Failed to copy to: $targetDir" -ForegroundColor Red
                }
            }
        }
    }
    
    # Cleanup
    Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
}

# Register the DLL in GAC
Write-Host "`nRegistering DLL in Global Assembly Cache..." -ForegroundColor Yellow

$gacutilPath = "C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\gacutil.exe"
if (Test-Path $gacutilPath) {
    $dllPath = "C:\Program Files\Microsoft SQL Server\160\DTS\Binn\$missingDll"
    if (Test-Path $dllPath) {
        & $gacutilPath /i $dllPath /f
        Write-Host "DLL registered in GAC" -ForegroundColor Green
    }
} else {
    Write-Host "gacutil.exe not found - manual registration required" -ForegroundColor Yellow
}

Write-Host "`n=== Fix Complete ===" -ForegroundColor Cyan
Write-Host "Try running the Import/Export Wizard again!" -ForegroundColor Green
Write-Host "`nIf it still fails, you need to:" -ForegroundColor Yellow
Write-Host "1. Run SQL Server 2022 installer" -ForegroundColor White
Write-Host "2. Add 'Integration Services' feature" -ForegroundColor White
Write-Host "3. This will properly install all required DLLs" -ForegroundColor White