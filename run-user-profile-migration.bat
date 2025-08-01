@echo off
echo ======================================
echo Running User Profile System Migration
echo ======================================
echo.

REM Run the migration using PowerShell
powershell -ExecutionPolicy Bypass -File run-migration-userprofile.ps1

echo.
echo Migration completed.
pause