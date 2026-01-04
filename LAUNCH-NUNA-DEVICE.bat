@echo off
REM ========================================
REM   NuNa Device Launcher
REM   Vivobook Go E1504GEB_E1504GA
REM ========================================
REM
REM This batch file launches the NuNa device automation
REM and opens the repository website
REM
REM Device: NuNa
REM Model: Vivobook Go E1504GEB_E1504GA
REM OS: Windows 11 Home Single Language 25H2
REM ========================================

echo.
echo ========================================
echo    NuNa Device Launcher
echo    Vivobook Go E1504GEB_E1504GA
echo ========================================
echo.
echo Starting NuNa device launcher...
echo.

REM Use environment variable for OneDrive path instead of hardcoded path
if defined OneDriveConsumer (
    cd /d "%OneDriveConsumer%"
) else if defined OneDrive (
    cd /d "%OneDrive%"
) else (
    cd /d "%USERPROFILE%\OneDrive"
)

REM Check if PowerShell script exists
if not exist "launch-nuna-device.ps1" (
    echo ERROR: launch-nuna-device.ps1 not found!
    echo Please ensure the script is in the OneDrive folder.
    echo Current directory: %CD%
    echo.
    pause
    exit /b 1
)

REM Execute PowerShell script with bypass policy
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "launch-nuna-device.ps1"

exit /b %ERRORLEVEL%
