@echo off
title CLIProxyAPI Server
color 0A
echo ============================================
echo   CLIProxyAPI Server
echo   Port: 8317 / Config: %USERPROFILE%\.cli-proxy-api
echo ============================================
echo.
echo [INFO] Khoi dong proxy server...
echo [INFO] Nhan Ctrl+C de dung server
echo.

"%~dp0cli-proxy-api.exe" --config "%USERPROFILE%\.cli-proxy-api\config.yaml"

echo.
echo [INFO] Server da dung.
pause
