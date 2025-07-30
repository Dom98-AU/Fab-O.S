@echo off
echo ========================================
echo Fixing Company Setup for Steel Estimation
echo ========================================
echo.

rem Get the directory where this batch file is located
set SCRIPT_DIR=%~dp0

rem Run the comprehensive setup script
echo Running company setup script...
echo.
sqlcmd -S "localhost" -d "SteelEstimationDb" -E -i "%SCRIPT_DIR%EnsureCompanySetup.sql"

if %ERRORLEVEL% neq 0 (
    echo.
    echo ========================================
    echo ERROR: Failed to fix company setup.
    echo ========================================
    echo.
    echo Please check:
    echo 1. SQL Server is running
    echo 2. The database "SteelEstimationDb" exists
    echo 3. You have the necessary permissions
    echo.
    echo If the database doesn't exist, run:
    echo   cd SteelEstimation.Web
    echo   dotnet ef database update
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Company setup completed successfully!
echo ========================================
echo.
echo You should now be able to:
echo - Log in as admin@steelestimation.com
echo - Create new customers
echo - All users now have a valid company assigned
echo.
pause