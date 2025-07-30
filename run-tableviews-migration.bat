@echo off
echo Running TableViews migration...
powershell -Command "Invoke-Sqlcmd -ServerInstance localhost -Database SteelEstimationDb_CloudDev -InputFile 'Migrations\AddTableViews.sql'"
echo.
echo Migration completed!
pause