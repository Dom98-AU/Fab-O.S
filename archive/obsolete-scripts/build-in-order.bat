@echo off
echo =========================================
echo Building Steel Estimation Solution
echo =========================================
echo.

echo Step 1: Cleaning solution...
dotnet clean
if %errorlevel% neq 0 goto :error

echo.
echo Step 2: Restoring packages...
dotnet restore
if %errorlevel% neq 0 goto :error

echo.
echo Step 3: Building Core project...
dotnet build SteelEstimation.Core\SteelEstimation.Core.csproj -c Debug
if %errorlevel% neq 0 goto :error

echo.
echo Step 4: Building Infrastructure project...
dotnet build SteelEstimation.Infrastructure\SteelEstimation.Infrastructure.csproj -c Debug
if %errorlevel% neq 0 goto :error

echo.
echo Step 5: Building Web project...
dotnet build SteelEstimation.Web\SteelEstimation.Web.csproj -c Debug
if %errorlevel% neq 0 goto :error

echo.
echo =========================================
echo Build completed successfully!
echo =========================================
echo.
echo Next steps:
echo 1. Run: run-local.bat
echo 2. Login as admin@steelestimation.com
echo 3. Go to Admin - Material Settings
goto :end

:error
echo.
echo =========================================
echo Build FAILED! Check errors above.
echo =========================================
exit /b 1

:end