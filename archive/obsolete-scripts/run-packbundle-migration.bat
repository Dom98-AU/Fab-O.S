@echo off
echo Running Pack Bundle Migration...
echo.

set SERVER=localhost
set DATABASE=SteelEstimationDb_CloudDev
set MIGRATION_FILE=SteelEstimation.Infrastructure\Migrations\SQL\AddPackBundles.sql

echo Connecting to database: %DATABASE% on server: %SERVER%
echo.

sqlcmd -S %SERVER% -d %DATABASE% -E -i "%MIGRATION_FILE%"

if %ERRORLEVEL% == 0 (
    echo.
    echo Pack Bundle migration completed successfully!
    echo.
    echo New features added:
    echo - PackBundles table for grouping processing items
    echo - Pack bundle fields in ProcessingItems table  
    echo - Pack bundle parent/child relationship support
    echo.
    echo You can now use pack bundles to group items for handling operations.
) else (
    echo.
    echo Error running migration. Please check the error messages above.
    exit /b 1
)

pause