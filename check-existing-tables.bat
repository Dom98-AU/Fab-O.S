@echo off
echo ======================================
echo Checking Existing Database Tables
echo ======================================
echo.

REM Connection details
set SERVER=nwiapps.database.windows.net
set DATABASE=sqldb-steel-estimation-sandbox
set USERNAME=admin@nwi@nwiapps
set PASSWORD=Natweigh88

REM Check for all tables
sqlcmd -S %SERVER% -d %DATABASE% -U %USERNAME% -P %PASSWORD% -Q "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME"

echo.
echo ======================================
echo Checking for specific feature tables:
echo ======================================
echo.

REM Check for Time Tracking tables
echo Checking Time Tracking tables...
sqlcmd -S %SERVER% -d %DATABASE% -U %USERNAME% -P %PASSWORD% -Q "SELECT COUNT(*) as 'EstimationTimeLogs exists' FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'EstimationTimeLogs'"
sqlcmd -S %SERVER% -d %DATABASE% -U %USERNAME% -P %PASSWORD% -Q "SELECT COUNT(*) as 'WeldingItemConnections exists' FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'WeldingItemConnections'"

REM Check for Efficiency Rates
echo.
echo Checking Efficiency Rates table...
sqlcmd -S %SERVER% -d %DATABASE% -U %USERNAME% -P %PASSWORD% -Q "SELECT COUNT(*) as 'EfficiencyRates exists' FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'EfficiencyRates'"

REM Check for Pack Bundles
echo.
echo Checking Pack Bundles table...
sqlcmd -S %SERVER% -d %DATABASE% -U %USERNAME% -P %PASSWORD% -Q "SELECT COUNT(*) as 'PackBundles exists' FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'PackBundles'"

REM Check for User Profile System tables
echo.
echo Checking User Profile System tables...
sqlcmd -S %SERVER% -d %DATABASE% -U %USERNAME% -P %PASSWORD% -Q "SELECT COUNT(*) as 'UserProfiles exists' FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'UserProfiles'"
sqlcmd -S %SERVER% -d %DATABASE% -U %USERNAME% -P %PASSWORD% -Q "SELECT COUNT(*) as 'Comments exists' FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Comments'"
sqlcmd -S %SERVER% -d %DATABASE% -U %USERNAME% -P %PASSWORD% -Q "SELECT COUNT(*) as 'Notifications exists' FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Notifications'"

echo.
pause