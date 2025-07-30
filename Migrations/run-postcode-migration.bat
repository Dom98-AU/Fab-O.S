@echo off
echo Running postcode migration...

rem Get the directory where this batch file is located
set SCRIPT_DIR=%~dp0

rem Change to the solution root directory (parent of Migrations folder)
cd /d "%SCRIPT_DIR%\.."

rem Apply the migration using EF Core
echo Applying Entity Framework migrations...
cd SteelEstimation.Web
dotnet ef database update
cd ..

rem Run the SQL script to add sample data
echo Adding sample postcode data...
sqlcmd -S "localhost" -d "SteelEstimationDb" -E -i "%SCRIPT_DIR%AddPostcodes.sql"

if %ERRORLEVEL% neq 0 (
    echo.
    echo ERROR: Failed to run migration. Please ensure:
    echo 1. SQL Server LocalDB is running
    echo 2. The database "SteelEstimationPlatform" exists
    echo 3. You're running this from the correct directory
    pause
    exit /b 1
)

echo.
echo Postcode migration completed successfully!
echo The system now supports postcode lookup functionality.
pause