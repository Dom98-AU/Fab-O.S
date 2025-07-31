@echo off
echo Testing compilation of PackageWorksheets.razor...
cd SteelEstimation.Web
dotnet build --no-restore 2>&1 | findstr /i "error warning CS RZ"
if %ERRORLEVEL% == 0 (
    echo.
    echo Compilation FAILED - errors found above
) else (
    echo.
    echo Compilation SUCCESSFUL - no errors found
)
pause