@echo off
title Windows System Repair Tool
color 0A

:: Thin launcher: elevate if needed, then hand off to RepairWindows.ps1
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0RepairWindows.ps1"
if errorlevel 1 (
    echo.
    echo The PowerShell repair tool exited with an error.
    pause
)
