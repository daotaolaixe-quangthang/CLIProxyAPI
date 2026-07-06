@echo off
title CLIProxyAPI - Login OpenAI Codex OAuth
color 0B
echo ============================================
echo   OpenAI Codex OAuth Login
echo ============================================
echo.
echo [INFO] URL OAuth se hien thi ben duoi, hay copy vao browser ban muon
echo [INFO] Dang nhap vao tai khoan OpenAI cua ban
echo [INFO] OAuth callback dung port 1455
echo [INFO] Neu browser o may khac va khong dung SSH tunnel, copy URL callback ve day roi bam Enter
echo.

set "EXE=%~dp0cli-proxy-api.exe"
set "CONFIG=%USERPROFILE%\.cli-proxy-api\config.yaml"

"%EXE%" --config "%CONFIG%" --codex-login --no-browser
if errorlevel 1 goto oauth_failed

echo.
echo [SUCCESS] OAuth Codex hoan tat!
echo [INFO] Ban co the tat cua so nay va chay start-proxy.bat
pause
exit /b 0

:oauth_failed
echo.
echo [ERROR] OAuth Codex chua hoan tat hoac da bi huy.
echo [INFO] Hay chay lai login-codex.bat va paste callback URL khi duoc hoi.
pause
exit /b 1
