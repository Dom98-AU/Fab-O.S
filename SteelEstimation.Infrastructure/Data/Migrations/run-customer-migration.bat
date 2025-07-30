@echo off
REM Batch file to run Customer Management migration
REM This file calls the PowerShell script with appropriate permissions

echo Steel Estimation Platform - Customer Management Migration
echo ========================================================

REM Check for admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script must be run as Administrator.
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

REM Run the PowerShell script
powershell.exe -ExecutionPolicy Bypass -File "%~dp0run-customer-migration.ps1" %*

pause