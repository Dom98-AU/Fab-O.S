@echo off
echo Running Work Centers and Machine Centers Migration...
powershell -ExecutionPolicy Bypass -File "%~dp0run-workcenter-migration.ps1"
pause