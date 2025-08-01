@echo off
REM Run Product Licensing Migration for Fab.OS
REM This script applies the ProductLicensing migration to enable module-based architecture

echo ======================================
echo  Fab.OS Product Licensing Migration
echo ======================================
echo.

REM Check if PowerShell script exists
if not exist "%~dp0run-product-licensing-migration.ps1" (
    echo ERROR: PowerShell script not found!
    echo Expected location: %~dp0run-product-licensing-migration.ps1
    pause
    exit /b 1
)

REM Run the PowerShell script
echo Running Product Licensing migration...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0run-product-licensing-migration.ps1" -Environment Development

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Migration failed with error code %ERRORLEVEL%
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Migration completed successfully!
echo.
pause