@echo off
setlocal EnableExtensions
chcp 65001 >nul
title CLIProxyAPI - Quota Dashboard

set "INSPECTOR=%~dp0CLIProxyAPI-Quota-Inspector\cpa-quota-inspector.exe"
set "BASE_URL=http://127.0.0.1:8317"
set "KEY_FILE=%USERPROFILE%\.cli-proxy-api\management.key"
set "MANAGEMENT_KEY="

if not exist "%INSPECTOR%" (
  echo.
  echo [ERROR] Khong tim thay Quota Inspector:
  echo         %INSPECTOR%
  echo.
  pause
  exit /b 1
)

if exist "%KEY_FILE%" (
  set /p MANAGEMENT_KEY=<"%KEY_FILE%"
)

if not defined MANAGEMENT_KEY (
  echo.
  echo [INFO] Chua tim thay management key tai: %KEY_FILE%
  echo.
  set /p "MANAGEMENT_KEY=Nhap management key: "
  if not defined MANAGEMENT_KEY (
    echo.
    echo [ERROR] Ban chua nhap management key.
    pause
    exit /b 1
  )
  echo.
  choice /c YN /n /m "Luu key vao file de lan sau bam 1 click? [Y/N]: "
  if not errorlevel 2 (
    powershell -NoProfile -Command "[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($env:KEY_FILE))>$null;[IO.File]::WriteAllText($env:KEY_FILE,$env:MANAGEMENT_KEY)"
    echo [OK] Da luu key.
    echo.
  )
)

:menu
cls
echo.
echo ================================================================
echo   CLIProxyAPI - Quota Dashboard
echo   Base URL : %BASE_URL%
echo ================================================================
echo   [1] TAT CA providers  (Codex + Gemini CLI + Antigravity)
echo   [2] Codex only
echo   [3] Gemini CLI only
echo   [4] Antigravity only
echo   ---------------------------------------------------------------
echo   [5] Summary only  (tong quan, khong chi tiet tung account)
echo   [6] Export JSON   (Desktop\quota-export.json)
echo   ---------------------------------------------------------------
echo   [Q] Thoat
echo ================================================================
echo.
choice /c 123456Q /n /m "Chon che do [1-6/Q]: "
set "CHO=%ERRORLEVEL%"

if "%CHO%"=="1" goto run_all
if "%CHO%"=="2" goto run_codex
if "%CHO%"=="3" goto run_gemini
if "%CHO%"=="4" goto run_antigravity
if "%CHO%"=="5" goto run_summary
if "%CHO%"=="6" goto run_json
if "%CHO%"=="7" exit /b 0
goto menu

:run_all
cls
echo.
echo [ALL] Dang tai quota toan bo providers...
echo.
"%INSPECTOR%" --cpa-base-url "%BASE_URL%" -k "%MANAGEMENT_KEY%"
goto done

:run_codex
cls
echo.
echo [CODEX] Dang tai quota Codex...
echo.
"%INSPECTOR%" --cpa-base-url "%BASE_URL%" -k "%MANAGEMENT_KEY%" --filter-provider codex
goto done

:run_gemini
cls
echo.
echo [GEMINI CLI] Dang tai quota Gemini CLI...
echo.
"%INSPECTOR%" --cpa-base-url "%BASE_URL%" -k "%MANAGEMENT_KEY%" --filter-provider gemini-cli
goto done

:run_antigravity
cls
echo.
echo [ANTIGRAVITY] Dang tai quota Antigravity...
echo.
"%INSPECTOR%" --cpa-base-url "%BASE_URL%" -k "%MANAGEMENT_KEY%" --filter-provider antigravity
goto done

:run_summary
cls
echo.
echo [SUMMARY] Tong quan tat ca providers...
echo.
"%INSPECTOR%" --cpa-base-url "%BASE_URL%" -k "%MANAGEMENT_KEY%" --summary-only
goto done

:run_json
set "JSON_OUT=%USERPROFILE%\Desktop\quota-export.json"
echo.
echo [JSON] Dang xuat du lieu ra: %JSON_OUT%
echo.
"%INSPECTOR%" --cpa-base-url "%BASE_URL%" -k "%MANAGEMENT_KEY%" --json > "%JSON_OUT%"
set "EXITCODE=%ERRORLEVEL%"
if exist "%JSON_OUT%" (
  echo [OK] Da luu: %JSON_OUT%
  start notepad "%JSON_OUT%"
) else (
  echo [ERROR] Khong the tao file JSON.
)
goto after_done

:done
set "EXITCODE=%ERRORLEVEL%"

:after_done
echo.
if not "%EXITCODE%"=="0" (
  echo [ERROR] Khong the lay du lieu. Kiem tra:
  echo         - CLIProxyAPI dang chay tai %BASE_URL%
  echo         - Management key chinh xac
  echo.
)
choice /c RQ /n /m "  [R] Quay lai menu   [Q] Thoat: "
if errorlevel 2 exit /b 0
goto menu
