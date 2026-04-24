@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title CLIProxyAPI - Custom Account Mode

set "EXE=%~dp0CLIProxyAPI\cli-proxy-api.exe"
set "FILTER_JS=%~dp0CLIProxyAPI\schema-filter.js"
set "BASE_CONFIG=%USERPROFILE%\.cli-proxy-api\config.yaml"
set "AUTH_DIR=%USERPROFILE%\.cli-proxy-api"
set "TEMP_DIR=%USERPROFILE%\.cli-proxy-api-single"
set "TEMP_CONFIG=%USERPROFILE%\.cli-proxy-api-single\config-single.yaml"

if not exist "%EXE%" ( echo [ERROR] Khong tim thay: %EXE% & pause & exit /b 1 )
if not exist "%BASE_CONFIG%" ( echo [ERROR] Khong tim thay config: %BASE_CONFIG% & pause & exit /b 1 )
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

:: ================================================================
:: BUOC 1: Quet TEMP_DIR xem co *.json -> detect config cu khong
:: ================================================================
set "PREV_COUNT=0"
for %%F in ("%TEMP_DIR%\*.json") do set /a PREV_COUNT+=1

if "!PREV_COUNT!"=="0" goto pick

cls
echo.
echo ================================================================
echo   CLIProxyAPI - Custom Account Mode
echo   FILES GOC KHONG BI THAY DOI - chi dung file tam
echo ================================================================
echo.
echo Da tim thay cau hinh cu (!PREV_COUNT! account):
echo   Thu muc : %TEMP_DIR%
echo ----------------------------------------------------------------
for %%F in ("%TEMP_DIR%\*.json") do echo   [*] %%~nxF
echo ----------------------------------------------------------------
echo.
choice /c YN /n /m "Dung lai cau hinh nay? [Y=Chay luon / N=Chon lai moi]: "
if errorlevel 2 goto clear_and_pick
echo.
echo [INFO] Dung lai cau hinh cu - files da san sang.
goto start_proxy

:clear_and_pick
echo.
echo [INFO] Xoa cau hinh cu, chuan bi chon moi...
del /q "%TEMP_DIR%\*.json" >nul 2>&1
del /q "%TEMP_CONFIG%" >nul 2>&1

:: ================================================================
:: BUOC 2: Hien thi danh sach account de chon moi
:: ================================================================
:pick
cls
echo.
echo ================================================================
echo   CLIProxyAPI - Custom Account Mode
echo   FILES GOC KHONG BI THAY DOI - chi dung file tam
echo ================================================================
echo.
echo Danh sach account OAuth:
echo ----------------------------------------------------------------
set "COUNT=0"
for %%F in ("%AUTH_DIR%\*.json") do (
  set /a COUNT+=1
  set "FILE_!COUNT!=%%~nxF"
  echo   [!COUNT!] %%~nxF
)
if "%COUNT%"=="0" ( echo [ERROR] Khong co file JSON nao trong %AUTH_DIR% & pause & exit /b 1 )
echo ----------------------------------------------------------------
echo.
echo Huong dan:
echo   Nhap SO + Enter : chon / bo chon account do
echo   Nhap S  + Enter : xac nhan va bat dau chay
echo   Nhap Q  + Enter : thoat
echo.
for /l %%I in (1,1,50) do set "SEL_%%I="
set "SEL_COUNT=0"

:input_loop
echo Da chon: !SEL_COUNT! account(s)
set "INPUT="
set /p "INPUT=  > Nhap so, S hoac Q: "
if not defined INPUT goto input_loop
if /i "!INPUT!"=="Q" exit /b 0
if /i "!INPUT!"=="S" goto confirm_selection

set "VALID=0"
for /l %%I in (1,1,%COUNT%) do if "%%I"=="!INPUT!" set "VALID=1"
if "!VALID!"=="0" ( echo   [WARN] "!INPUT!" khong hop le. Nhap so 1 den %COUNT%. & goto input_loop )

for /f "tokens=1" %%V in ("!INPUT!") do (
  if defined SEL_%%V (
    set "SEL_%%V="
    set /a SEL_COUNT-=1
    echo   [-] Bo chon  : !FILE_%%V!
  ) else (
    set "SEL_%%V=1"
    set /a SEL_COUNT+=1
    echo   [+] Da chon  : !FILE_%%V!
  )
)
goto input_loop

:confirm_selection
if "!SEL_COUNT!"=="0" ( echo. & echo   [WARN] Chua chon account nao. & goto input_loop )
echo.
echo ================================================================
echo   Cac account se duoc su dung:
echo ================================================================
for /l %%I in (1,1,%COUNT%) do if defined SEL_%%I echo   [*] !FILE_%%I!
echo ================================================================
echo.
choice /c YN /n /m "Xac nhan bat dau chay? [Y=Yes / N=Chon lai]: "
if errorlevel 2 goto pick

del /q "%TEMP_DIR%\*.json" >nul 2>&1
for /l %%I in (1,1,%COUNT%) do (
  if defined SEL_%%I (
    copy /y "%AUTH_DIR%\!FILE_%%I!" "%TEMP_DIR%\!FILE_%%I!" >nul
    echo   [COPY] !FILE_%%I!
  )
)

:: ================================================================
:: BUOC 3: Tao/cap nhat config-single.yaml tu BASE_CONFIG
:: ================================================================
:start_proxy
powershell -NoProfile -Command "$c=[IO.File]::ReadAllText($env:BASE_CONFIG);$c=$c -replace 'auth-dir:.*','auth-dir: """"~/.cli-proxy-api-single"""';[IO.File]::WriteAllText($env:TEMP_CONFIG,$c)"
if not exist "%TEMP_CONFIG%" ( echo [ERROR] Khong tao duoc config-single.yaml. & pause & exit /b 1 )

set "ACT_COUNT=0"
for %%F in ("%TEMP_DIR%\*.json") do set /a ACT_COUNT+=1

:: Schema-filter luon chay tren 8317, CLIProxyAPI luon tren 8318
set "FILTER_PORT=8317"
set "USE_PORT=8318"
:: Kill bat ky schema-filter cu nao dang chay (dung port check vi chay hidden)
for /f "tokens=5" %%P in ('netstat -ano 2^>nul ^| findstr ":!FILTER_PORT! "') do taskkill /f /pid %%P >nul 2>&1

:: Start schema-filter.js (port 8317 -^> 8318) HIDDEN - khong hien cua so
:: Dung wscript.exe voi window style 0 (giong start-proxy-hidden.vbs)
echo [INFO] Khoi dong Schema Filter (port !FILTER_PORT! -^> !USE_PORT! - hidden)...
set "VBS_TMP=%TEMP%\run-schema-filter.vbs"
echo Set oShell = CreateObject("WScript.Shell") > "!VBS_TMP!"
echo oShell.Run "node ""%FILTER_JS%"" !FILTER_PORT! !USE_PORT!", 0, False >> "!VBS_TMP!"
wscript //nologo "!VBS_TMP!"
ping -n 3 127.0.0.1 >nul
echo.
echo ================================================================
echo   CUSTOM ACCOUNT MODE RUNNING  [+schema-filter]
echo   So account   : !ACT_COUNT!
echo   Claude Code  : port !FILTER_PORT! (schema-filter)
echo   CLIProxyAPI  : port !USE_PORT!
echo   propertyNames: tu dong bi xoa truoc khi gui
echo   Files goc    : KHONG BI THAY DOI
echo   ^>^> Nhan Ctrl+C de dung proxy.
echo ================================================================
echo.
echo [TIP] Kiem tra models dang active (PowerShell):
echo   Invoke-RestMethod http://127.0.0.1:!FILTER_PORT!/v1/models -Headers @{Authorization="Bearer sk-my-secret-key"} ^| ConvertTo-Json
echo.
"%EXE%" --config "%TEMP_CONFIG%"

:: ================================================================
:: SAU KHI PROXY DUNG: GIU LAI ca *.json va config-single.yaml
:: Files goc AUTH_DIR: KHONG bi cham
:: ================================================================
echo.
echo [INFO] Proxy da dung. Dung Schema Filter (port !FILTER_PORT!)...
for /f "tokens=5" %%P in ('netstat -ano 2^>nul ^| findstr ":!FILTER_PORT! "') do taskkill /f /pid %%P >nul 2>&1
echo.
echo ================================================================
echo   SERVER DA DUNG HOAN TOAN
echo   Schema Filter  (port !FILTER_PORT!) : DA TAT
echo   CLIProxyAPI    (port !USE_PORT!)    : DA TAT
echo ================================================================
echo.
echo   [1]  Chay lai (hoi dung lai hay chon moi)
echo   [2]  Chay start-proxy.bat (full multi-account)
echo   [3]  Thoat + xoa sach file tam
echo.
choice /c 123 /n /m "  > Chon: "
if errorlevel 3 goto :shutdown_clean
if errorlevel 2 (
  start "" "%~dp0CLIProxyAPI\start-proxy.bat"
  exit /b 0
)
if errorlevel 1 goto :eof

:shutdown_clean
echo.
echo [INFO] Dang don dep...
del /q "%TEMP_DIR%\*.json"            >nul 2>&1
del /q "%TEMP_CONFIG%"                >nul 2>&1
del /q "%TEMP%\run-schema-filter.vbs" >nul 2>&1
echo [OK] Da xoa: JSON session, config-single.yaml, VBS temp.
echo [OK] Files goc tai %AUTH_DIR% KHONG bi thay doi.
exit /b 0
