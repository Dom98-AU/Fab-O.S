@echo off
echo Running Worksheet Template Migrations...
echo.

cd SteelEstimation.Infrastructure\Migrations

echo 1. Executing AddWorksheetTemplates.sql...
sqlcmd -S localhost -d SteelEstimationDb -E -i AddWorksheetTemplates.sql

if %ERRORLEVEL% EQU 0 (
    echo    Worksheet templates created successfully!
) else (
    echo    Error: Worksheet templates migration failed!
    cd ..\..
    pause
    exit /b 1
)

echo.
echo 2. Executing AddUserWorksheetPreferences.sql...
sqlcmd -S localhost -d SteelEstimationDb -E -i AddUserWorksheetPreferences.sql

if %ERRORLEVEL% EQU 0 (
    echo    User preferences table created successfully!
) else (
    echo    Error: User preferences migration failed!
    cd ..\..
    pause
    exit /b 1
)

echo.
echo All migrations completed successfully!
cd ..\..
pause