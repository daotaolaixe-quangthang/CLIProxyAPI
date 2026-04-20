@echo off
title CLIProxyAPI - Login OpenAI Codex OAuth
color 0B
echo ============================================
echo   OpenAI Codex OAuth Login
echo ============================================
echo.
echo [INFO] URL OAuth se hien thi VA tu dong copy vao Clipboard
echo [INFO] Dang nhap vao tai khoan OpenAI cua ban
echo [INFO] OAuth callback dung port 1455
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "E:\CLIProxyAPI\oauth-clipboard.ps1" -LoginFlag "--codex-login"

echo.
echo [SUCCESS] OAuth Codex hoan tat!
echo [INFO] Ban co the tat cua so nay va chay start-proxy.bat
pause
