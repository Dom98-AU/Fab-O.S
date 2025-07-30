@echo off
echo Starting Steel Estimation Platform...
cd SteelEstimation.Web
set ASPNETCORE_ENVIRONMENT=Development
set ASPNETCORE_URLS=https://localhost:5001;http://localhost:5000
dotnet run --urls "https://localhost:5001;http://localhost:5000"