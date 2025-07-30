@echo off
echo Fixing company data in database...

rem Get the directory where this batch file is located
set SCRIPT_DIR=%~dp0

rem Run the SQL script to fix company data
echo Running FixCompanyData.sql...
sqlcmd -S "localhost" -d "SteelEstimationDb" -E -i "%SCRIPT_DIR%FixCompanyData.sql"

if %ERRORLEVEL% neq 0 (
    echo.
    echo ERROR: Failed to fix company data. Please ensure:
    echo 1. SQL Server is running
    echo 2. The database "SteelEstimationDb" exists
    echo 3. You have the necessary permissions
    pause
    exit /b 1
)

echo.
echo Company data fixed successfully!
echo You should now be able to create customers.
pause