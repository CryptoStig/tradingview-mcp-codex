@echo off
setlocal

set "SCRIPT_DIR=%~dp0"

echo TradingView MCP Jackson - Codex Windows Setup
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%scripts\setup_codex_windows.ps1"
set "EXIT_CODE=%ERRORLEVEL%"

echo.
if %EXIT_CODE% neq 0 (
    echo Setup did not complete successfully. Review the messages above, then press any key to close.
    pause >nul
    exit /b %EXIT_CODE%
)

echo Setup finished. Press any key to close this window.
pause >nul
exit /b 0
