@echo off
title CLIProxyAPI - Login Gemini CLI OAuth (Google)
color 0B
echo ============================================
echo   Gemini CLI OAuth Login - Google Account
echo ============================================
echo.
echo [INFO] Link OAuth se hien thi duoi day - Copy va Paste vao trinh duyet ban muon
echo [INFO] Dang nhap vao tai khoan Google cua ban
echo [INFO] OAuth callback dung port 8085
echo.
echo [LUU Y] Day la provider MIEN PHI voi quota cao
echo         Gemini 2.5 Pro / Flash / Flash-Lite
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0oauth-clipboard.ps1" -LoginFlag "--login"

echo.
echo [SUCCESS] OAuth Gemini CLI hoan tat!
echo [INFO] Khoi dong lai server: start-proxy.bat
pause
