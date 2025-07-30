@echo off
echo Running Worksheet Templates Migration...
echo.

cd SteelEstimation.Infrastructure\Migrations

echo Executing AddWorksheetTemplates.sql...
sqlcmd -S localhost -d SteelEstimationDb -E -i AddWorksheetTemplates.sql

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Migration completed successfully!
) else (
    echo.
    echo Error: Migration failed!
)

cd ..\..
pause