@echo off
REM Run Multi-Tenant Migration Script
REM This script applies the multi-tenant database changes

echo =========================================
echo Multi-Tenant Migration Script
echo =========================================
echo.

REM Set database connection parameters
set SERVER=(localdb)\MSSQLLocalDB
set DATABASE=SteelEstimationDb

REM Test database connection
echo Testing database connection...
sqlcmd -S %SERVER% -d %DATABASE% -Q "SELECT 1" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Failed to connect to database
    echo Make sure SQL Server is running and the database exists
    pause
    exit /b 1
)
echo Database connection successful
echo.

REM Navigate to migration directory
cd /d "%~dp0SteelEstimation.Infrastructure\Migrations"

REM Check if migration file exists
if not exist "RunMultiTenantMigration_Simple.sql" (
    echo ERROR: Migration file not found
    pause
    exit /b 1
)

echo Running multi-tenant migration...
echo Server: %SERVER%
echo Database: %DATABASE%
echo.

REM Execute the migration
sqlcmd -S %SERVER% -d %DATABASE% -i RunMultiTenantMigration_Simple.sql

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Migration failed!
    pause
    exit /b 1
)

echo.
echo =========================================
echo Migration Complete!
echo =========================================
echo.
echo Next steps:
echo 1. Run the application using: run-local.bat
echo 2. Login as admin@steelestimation.com
echo 3. Navigate to Admin - Material Settings
echo 4. Configure material types and mappings for your company
echo.
pause