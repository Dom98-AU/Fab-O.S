@echo off
echo Building Steel Estimation Solution...

echo Restoring NuGet packages...
dotnet restore

echo Building solution...
dotnet build --configuration Debug

if %errorlevel% equ 0 (
    echo Build completed successfully!
) else (
    echo Build failed with errors.
    exit /b 1
)