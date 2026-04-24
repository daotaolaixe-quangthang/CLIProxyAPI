@echo off
setlocal EnableExtensions
chcp 65001 >nul
title Codex Quota Inspector

set "INSPECTOR=%~dp0CLIProxyAPI-Quota-Inspector\cpa-quota-inspector.exe"
set "BASE_URL=http://127.0.0.1:8317"
set "KEY_FILE=%USERPROFILE%\.cli-proxy-api\management.key"
set "MANAGEMENT_KEY="

if not exist "%INSPECTOR%" (
  echo [ERROR] Khong tim thay Quota Inspector:
  echo %INSPECTOR%
  echo.
  pause
  exit /b 1
)

if exist "%KEY_FILE%" (
  set /p MANAGEMENT_KEY=<"%KEY_FILE%"
)

if not defined MANAGEMENT_KEY (
  echo [INFO] Chua tim thay plaintext management key tai:
  echo %KEY_FILE%
  echo.
  set /p "MANAGEMENT_KEY=Nhap management key: "
  if not defined MANAGEMENT_KEY (
    echo.
    echo [ERROR] Ban chua nhap management key.
    pause
    exit /b 1
  )
  echo.
  choice /c YN /n /m "Luu key vao %KEY_FILE% de lan sau bam 1 click? [Y/N]: "
  if errorlevel 2 goto run
  powershell -NoProfile -Command "[System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($env:KEY_FILE)) > $null; [System.IO.File]::WriteAllText($env:KEY_FILE, $env:MANAGEMENT_KEY)"
  if errorlevel 1 (
    echo.
    echo [WARN] Khong luu duoc key vao %KEY_FILE%
  ) else (
    echo.
    echo [OK] Da luu key vao %KEY_FILE%
  )
)

:run
echo.
echo [INFO] Dang kiem tra Codex quota tren %BASE_URL%
echo.
"%INSPECTOR%" --cpa-base-url "%BASE_URL%" --filter-provider codex -k "%MANAGEMENT_KEY%"
set "EXITCODE=%ERRORLEVEL%"
echo.
if not "%EXITCODE%"=="0" (
  echo [ERROR] Khong the lay du lieu. Kiem tra management key va dam bao CLIProxyAPI dang chay.
)
pause
exit /b %EXITCODE%
