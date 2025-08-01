@echo off
REM Direct SQL execution for Product Licensing Migration

echo ========================================
echo  Fab.OS Product Licensing Migration
echo  Direct SQL Execution
echo ========================================
echo.

REM Check if sqlcmd is available
where sqlcmd >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: sqlcmd is not installed or not in PATH
    echo Please install SQL Server Command Line Tools
    echo.
    echo Alternatively, you can run the migration manually:
    echo 1. Open SQL Server Management Studio or Azure Data Studio
    echo 2. Connect to: nwiapps.database.windows.net
    echo 3. Database: sqldb-steel-estimation-sandbox
    echo 4. Execute the script: SQL_Migrations\AddProductLicensing.sql
    pause
    exit /b 1
)

REM Connection parameters
set SERVER=tcp:nwiapps.database.windows.net,1433
set DATABASE=sqldb-steel-estimation-sandbox
set USERNAME=admin@nwi@nwiapps
set PASSWORD=Natweigh88

echo Connecting to Azure SQL Database...
echo Server: %SERVER%
echo Database: %DATABASE%
echo.

REM Execute the migration
sqlcmd -S %SERVER% -d %DATABASE% -U %USERNAME% -P %PASSWORD% -i SQL_Migrations\AddProductLicensing.sql -b

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Migration failed with error code %ERRORLEVEL%
    echo.
    echo Common issues:
    echo - Check your network connection
    echo - Verify Azure SQL firewall allows your IP
    echo - Ensure credentials are correct
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ========================================
echo  Migration completed successfully!
echo ========================================
echo.
echo Next steps:
echo 1. Restart the Docker container: docker-compose restart
echo 2. Log out and back in to get product access claims
echo 3. The module switcher will appear in the top bar
echo.
pause