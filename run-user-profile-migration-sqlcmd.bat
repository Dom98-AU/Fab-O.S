@echo off
echo ======================================
echo Running User Profile System Migration
echo ======================================
echo.

REM Connection details
set SERVER=nwiapps.database.windows.net
set DATABASE=sqldb-steel-estimation-sandbox
set USERNAME=admin@nwi@nwiapps
set PASSWORD=Natweigh88

REM Run the migration
echo Executing migration: SQL_Migrations\AddUserProfileSystem.sql
sqlcmd -S %SERVER% -d %DATABASE% -U %USERNAME% -P %PASSWORD% -i SQL_Migrations\AddUserProfileSystem.sql

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Migration failed with error code %ERRORLEVEL%
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Migration completed successfully!
echo.
echo Created tables:
echo   - UserProfiles
echo   - UserPreferences
echo   - Comments
echo   - CommentMentions
echo   - CommentReactions
echo   - Notifications
echo   - UserActivities

REM Check results
echo.
echo Checking migration results...
sqlcmd -S %SERVER% -d %DATABASE% -U %USERNAME% -P %PASSWORD% -Q "SELECT 'User Profiles: ' + CAST(COUNT(*) AS VARCHAR) FROM UserProfiles"
sqlcmd -S %SERVER% -d %DATABASE% -U %USERNAME% -P %PASSWORD% -Q "SELECT 'User Preferences: ' + CAST(COUNT(*) AS VARCHAR) FROM UserPreferences"
sqlcmd -S %SERVER% -d %DATABASE% -U %USERNAME% -P %PASSWORD% -Q "SELECT 'Notifications: ' + CAST(COUNT(*) AS VARCHAR) FROM Notifications"

echo.
pause