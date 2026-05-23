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
set STEP1_ERR=%errorLevel%
echo.

:: Step 2: ScanHealth
echo Step 2: Scanning for system issues...
DISM /Online /Cleanup-Image /ScanHealth
set STEP2_ERR=%errorLevel%
echo.

:: Step 3: RestoreHealth
echo Step 3: Attempting to repair system image...
DISM /Online /Cleanup-Image /RestoreHealth
set STEP3_ERR=%errorLevel%
echo.

:: Step 4: SFC Scan
echo Step 4: Scanning system files with SFC...
sfc /scannow
set STEP4_ERR=%errorLevel%
echo.

:: ── REPORT ────────────────────────────────────────
echo.
echo ==============================================
echo              REPAIR SUMMARY REPORT
echo ==============================================
echo.

:: Step 1 result
if %STEP1_ERR% EQU 0 (
    echo   [PASS] Step 1 - DISM CheckHealth     : No issues detected
) else (
    echo   [FAIL] Step 1 - DISM CheckHealth     : Error code %STEP1_ERR%
)

:: Step 2 result
if %STEP2_ERR% EQU 0 (
    echo   [PASS] Step 2 - DISM ScanHealth      : Component store is healthy
) else (
    echo   [WARN] Step 2 - DISM ScanHealth      : Issues found (code %STEP2_ERR%)
)

:: Step 3 result
if %STEP3_ERR% EQU 0 (
    echo   [PASS] Step 3 - DISM RestoreHealth   : Image repaired successfully
) else (
    echo   [FAIL] Step 3 - DISM RestoreHealth   : Repair failed (code %STEP3_ERR%)
)

:: Step 4 result
if %STEP4_ERR% EQU 0 (
    echo   [PASS] Step 4 - SFC /scannow         : No integrity violations found
) else if %STEP4_ERR% EQU 2 (
    echo   [DONE] Step 4 - SFC /scannow         : Violations found and repaired
) else (
    echo   [FAIL] Step 4 - SFC /scannow         : Could not repair all files (code %STEP4_ERR%)
)

echo.
echo ==============================================
echo.
echo Press Enter to close...
set /p DUMMY=
