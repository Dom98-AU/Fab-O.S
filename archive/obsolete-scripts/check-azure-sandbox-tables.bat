@echo off
echo Checking Azure SQL Database Tables...
echo.
echo Choose authentication method:
echo 1. Azure AD Authentication (default)
echo 2. SQL Authentication
echo.
set /p choice="Enter your choice (1 or 2): "

if "%choice%"=="2" (
    powershell -ExecutionPolicy Bypass -File "%~dp0check-azure-sandbox-tables.ps1" -UseSqlAuth
) else (
    powershell -ExecutionPolicy Bypass -File "%~dp0check-azure-sandbox-tables.ps1"
)

pause