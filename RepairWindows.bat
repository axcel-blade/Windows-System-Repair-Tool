@echo off
title Windows System Repair Tool
color 0A

echo ==============================================
echo     Windows System Repair via DISM & SFC
echo ==============================================
echo.
echo Running as Administrator is required...
echo.

:: Auto-elevate to administrator if not already
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Step 1: CheckHealth
echo.
echo Step 1: Checking system health...
DISM /Online /Cleanup-Image /CheckHealth
echo.

:: Step 2: ScanHealth
echo Step 2: Scanning for system issues...
DISM /Online /Cleanup-Image /ScanHealth
echo.

:: Step 3: RestoreHealth
echo Step 3: Attempting to repair system image...
DISM /Online /Cleanup-Image /RestoreHealth
echo.

:: Step 4: SFC Scan
echo Step 4: Scanning system files with SFC...
sfc /scannow
echo.

echo ==============================================
echo     System Repair Completed. Check above logs.
echo ==============================================
pause