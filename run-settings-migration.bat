@echo off
echo Running Settings table migration...

sqlcmd -S localhost -d SteelEstimationDb -E -i .\SteelEstimation.Infrastructure\Migrations\AddSettingsTable.sql

if %ERRORLEVEL% == 0 (
    echo Settings table migration completed successfully!
    echo.
    echo You can now run the application with: .\run-local.ps1
) else (
    echo Error running migration. Please check your SQL Server connection.
    echo Make sure:
    echo 1. SQL Server is running
    echo 2. You have access to the SteelEstimationDb database
    echo 3. You're running this as Administrator if needed
)

pause