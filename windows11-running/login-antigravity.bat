@echo off
title CLIProxyAPI - Antigravity OAuth Login
color 0E
echo ============================================
echo   Antigravity OAuth Login
echo   (Google AI - Gemini access)
echo ============================================
echo.
echo [INFO] Dang dung OAuth cua Antigravity IDE
echo [INFO] URL OAuth se hien thi VA tu dong copy vao Clipboard
echo [INFO] Dang nhap Google account dang active
echo [INFO] OAuth callback dung port 51121
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0oauth-clipboard.ps1" -LoginFlag "--antigravity-login"

echo.
echo [SUCCESS] Antigravity OAuth hoan tat!
echo [INFO] Khoi dong lai server: start-proxy.bat
pause
