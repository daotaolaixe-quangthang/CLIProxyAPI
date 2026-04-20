@echo off
title CLIProxyAPI Server - Ashley
color 0A
echo ============================================
echo   CLIProxyAPI Server - Ashley Nguyen
echo   Port: 8317 / Config: .cli-proxy-api
echo ============================================
echo.
echo [INFO] Khoi dong proxy server...
echo [INFO] Nhan Ctrl+C de dung server
echo.

E:\CLIProxyAPI\cli-proxy-api.exe --config "C:\Users\Admin\.cli-proxy-api\config.yaml"

echo.
echo [INFO] Server da dung.
pause
