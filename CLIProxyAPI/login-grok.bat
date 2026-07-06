@echo off
title CLIProxyAPI - Grok xAI OAuth Login
color 0A
echo ============================================
echo   Grok / xAI OAuth Login
echo ============================================
echo.
echo [INFO] Dang dung OAuth cua xAI / Grok
echo [INFO] URL OAuth se hien thi VA tu dong copy vao Clipboard
echo [INFO] Dang nhap vao tai khoan xAI / Grok cua ban
echo [INFO] OAuth callback dung port mac dinh cua CLIProxyAPI
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0oauth-clipboard.ps1" -LoginFlag "--xai-login"

echo.
echo [SUCCESS] OAuth Grok / xAI hoan tat!
echo [INFO] Ban co the tat cua so nay va chay start-proxy.bat
pause
