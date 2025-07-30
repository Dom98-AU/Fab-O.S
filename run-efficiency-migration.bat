@echo off
echo Running EfficiencyRates migration...
echo.

REM Run the PowerShell script
powershell -ExecutionPolicy Bypass -File ".\run-efficiency-migration.ps1"

echo.
pause