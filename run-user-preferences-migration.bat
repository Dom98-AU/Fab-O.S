@echo off
echo Running User Worksheet Preferences Migration...
echo.

cd SteelEstimation.Infrastructure\Migrations

echo Executing AddUserWorksheetPreferences.sql...
sqlcmd -S localhost -d SteelEstimationDb -E -i AddUserWorksheetPreferences.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Migration completed successfully!
) else (
    echo.
    echo Error: Migration failed!
)

cd ..\..
pause