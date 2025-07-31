@echo off
echo Running Database Migrations...
echo.

REM Run the PowerShell script
powershell.exe -ExecutionPolicy Bypass -File "%~dp0run-migration.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Migration failed! Please check the error messages above.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Migration completed successfully!
pause