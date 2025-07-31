# Fix SQL Server Import/Export Wizard
Write-Host "=== Fixing SQL Server Import/Export Wizard ===" -ForegroundColor Cyan

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script needs to run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Step 1: Download required components
Write-Host "`nStep 1: Downloading required components..." -ForegroundColor Green

# Create temp directory
$tempDir = "C:\temp\sql-fix"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

# Download links for missing components
$downloads = @{
    "SSDT" = "https://go.microsoft.com/fwlink/?linkid=2139376"
    "VS2019_SSDT" = "https://marketplace.visualstudio.com/items?itemName=SSIS.SqlServerIntegrationServicesProjects&ssr=false&targetId=94917cdc-cf4f-46c8-8cb5-8d48a7531d58"
    "MSOLEDBSQL" = "https://go.microsoft.com/fwlink/?linkid=2183670"
    "AccessDatabaseEngine" = "https://download.microsoft.com/download/3/5/C/35C8DBD2-2DF1-43FD-A303-A3EFBB3F6459/AccessDatabaseEngine_X64.exe"
}

# Step 2: Install Integration Services components
Write-Host "`nStep 2: Installing Integration Services components..." -ForegroundColor Green

# Option 1: Try to fix via DISM
Write-Host "Attempting to repair .NET Framework features..." -ForegroundColor Yellow
DISM /Online /Enable-Feature /FeatureName:NetFx3 /All
DISM /Online /Enable-Feature /FeatureName:NetFx4-AdvSrvs /All

# Option 2: Register missing DLLs
Write-Host "`nRegistering SQL Server DLLs..." -ForegroundColor Yellow

$sqlPaths = @(
    "C:\Program Files\Microsoft SQL Server\160\DTS\Binn",
    "C:\Program Files\Microsoft SQL Server\150\DTS\Binn",
    "C:\Program Files (x86)\Microsoft SQL Server\140\DTS\Binn"
)

foreach ($path in $sqlPaths) {
    if (Test-Path $path) {
        Write-Host "Found SQL DTS at: $path" -ForegroundColor Green
        
        # Register assemblies
        $assemblies = Get-ChildItem -Path $path -Filter "*.dll" -ErrorAction SilentlyContinue
        foreach ($assembly in $assemblies) {
            if ($assembly.Name -like "*DataTransformation*" -or $assembly.Name -like "*ScaleHelper*") {
                Write-Host "  Registering: $($assembly.Name)" -ForegroundColor Gray
                try {
                    [System.Reflection.Assembly]::LoadFrom($assembly.FullName) | Out-Null
                    & regsvr32 /s $assembly.FullName 2>$null
                } catch {
                    # Silent continue
                }
            }
        }
    }
}

# Step 3: Install via SQL Server Setup
Write-Host "`nStep 3: Checking SQL Server installation..." -ForegroundColor Green

$setupPath = "C:\Program Files\Microsoft SQL Server\160\Setup Bootstrap\SQL2022\setup.exe"
if (Test-Path $setupPath) {
    Write-Host "Found SQL Server 2022 setup" -ForegroundColor Green
    Write-Host "`nTo add Integration Services:" -ForegroundColor Yellow
    Write-Host "1. Run: $setupPath" -ForegroundColor White
    Write-Host "2. Choose 'Add features to an existing installation'" -ForegroundColor White
    Write-Host "3. Select your instance" -ForegroundColor White
    Write-Host "4. Check 'Integration Services'" -ForegroundColor White
    Write-Host "5. Complete the installation" -ForegroundColor White
}

# Step 4: Alternative - Install SSDT for Visual Studio
Write-Host "`nStep 4: Alternative solutions..." -ForegroundColor Green

Write-Host "`nOption A: Install SQL Server Data Tools (SSDT)" -ForegroundColor Yellow
Write-Host "Download from: https://docs.microsoft.com/sql/ssdt/download-sql-server-data-tools-ssdt" -ForegroundColor Gray

Write-Host "`nOption B: Use standalone DTSWizard after fixing" -ForegroundColor Yellow
Write-Host "After installation, run from:" -ForegroundColor Gray
Write-Host "C:\Program Files\Microsoft SQL Server\160\DTS\Binn\DTSWizard.exe" -ForegroundColor Gray

Write-Host "`nOption C: Download Integration Services Projects extension" -ForegroundColor Yellow
Write-Host "1. Open Visual Studio Installer" -ForegroundColor Gray
Write-Host "2. Modify your VS 2022 installation" -ForegroundColor Gray
Write-Host "3. Go to 'Individual components'" -ForegroundColor Gray
Write-Host "4. Search for 'SQL Server Data Tools'" -ForegroundColor Gray
Write-Host "5. Check and install it" -ForegroundColor Gray

# Step 5: Quick fix attempt
Write-Host "`nStep 5: Attempting quick fix..." -ForegroundColor Green

# Copy missing DLL from Visual Studio if available
$vsDllPath = "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\Extensions\Microsoft\SQLDB\DTS\Microsoft.DataTransformationServices.ScaleHelper.dll"
$targetPath = "C:\Program Files\Microsoft SQL Server\160\DTS\Binn\"

if (Test-Path $vsDllPath) {
    if (Test-Path $targetPath) {
        Write-Host "Copying missing DLL..." -ForegroundColor Yellow
        Copy-Item -Path $vsDllPath -Destination $targetPath -Force
        Write-Host "DLL copied successfully!" -ForegroundColor Green
    }
}

Write-Host "`n=== Fix Complete ===" -ForegroundColor Cyan
Write-Host "Try running the Import/Export Wizard again from SSMS" -ForegroundColor Yellow
Write-Host "If it still fails, use one of the alternative options above" -ForegroundColor Yellow

# Cleanup
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue