@echo off
echo ======================================
echo Running All Pending Migrations
echo ======================================
echo.

REM Connection details
set SERVER=nwiapps.database.windows.net
set DATABASE=sqldb-steel-estimation-sandbox
set USERNAME=admin@nwi@nwiapps
set PASSWORD=Natweigh88

REM Migration 1: Time Tracking and Efficiency
echo.
echo [1/3] Running Time Tracking and Efficiency Migration...
echo -------------------------------------------------------
sqlcmd -S %SERVER% -d %DATABASE% -U %USERNAME% -P %PASSWORD% -i "SteelEstimation.Infrastructure\Migrations\AddTimeTrackingAndEfficiency.sql"
if %ERRORLEVEL% NEQ 0 (
    echo Time Tracking migration failed!
    pause
    exit /b %ERRORLEVEL%
)
echo Time Tracking and Efficiency migration completed!

REM Migration 2: Efficiency Rates
echo.
echo [2/3] Running Efficiency Rates Migration...
echo ------------------------------------------
sqlcmd -S %SERVER% -d %DATABASE% -U %USERNAME% -P %PASSWORD% -i "SteelEstimation.Infrastructure\Migrations\AddEfficiencyRates.sql"
if %ERRORLEVEL% NEQ 0 (
    echo Efficiency Rates migration failed!
    pause
    exit /b %ERRORLEVEL%
)
echo Efficiency Rates migration completed!

REM Migration 3: Pack Bundles
echo.
echo [3/3] Running Pack Bundles Migration...
echo ---------------------------------------
sqlcmd -S %SERVER% -d %DATABASE% -U %USERNAME% -P %PASSWORD% -i "SteelEstimation.Infrastructure\Migrations\SQL\AddPackBundles.sql"
if %ERRORLEVEL% NEQ 0 (
    echo Pack Bundles migration failed!
    pause
    exit /b %ERRORLEVEL%
)
echo Pack Bundles migration completed!

echo.
echo ======================================
echo All migrations completed successfully!
echo ======================================
echo.
echo Summary of new features:
echo - Time Tracking: Track time spent on estimations
echo - Multiple Welding Connections: Support for multiple connection types per item
echo - Processing Efficiency: Filter processing hours by efficiency percentage
echo - Efficiency Rates: Admin-managed efficiency presets
echo - Pack Bundles: Group processing items for handling operations
echo - User Profiles: Complete user profile system with comments and notifications
echo.
pause