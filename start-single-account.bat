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
set "GITHUB_REPO=router-for-me/CLIProxyAPI"
set "UPDATE_TMP=%TEMP%\clipa-update"

:: ================================================================
:: BUOC 0: Kiem tra phien ban moi nhat tren GitHub
:: ================================================================
echo.
echo [UPDATE] Dang kiem tra phien ban moi nhat tu GitHub...
echo.

:: Lay current local version (parse tu stderr cua exe)
set "LOCAL_VER=unknown"
if exist "%EXE%" (
  for /f "tokens=3 delims=: ," %%V in ('"%EXE%" --version 2^>^&1 ^| findstr /i "Version:"') do (
    set "LOCAL_VER=%%V"
    goto :got_local_ver
  )
)
:got_local_ver
set "LOCAL_VER=!LOCAL_VER: =!"

:: Lay latest version tu GitHub API (dung PowerShell)
set "LATEST_VER="
for /f "delims=" %%T in ('powershell -NoProfile -Command ^
  "try{(Invoke-RestMethod 'https://api.github.com/repos/%GITHUB_REPO%/releases/latest').tag_name}catch{'ERROR'}" ^
  2^>nul') do set "LATEST_VER=%%T"

if not defined LATEST_VER set "LATEST_VER=ERROR"
if "!LATEST_VER!"=="ERROR" (
  echo [WARN] Khong ket noi duoc GitHub. Bo qua kiem tra update.
  echo.
  goto :skip_update
)

echo   Local   : !LOCAL_VER!
echo   Latest  : !LATEST_VER!
echo.

:: So sanh version (bo prefix "v")
set "LATEST_CLEAN=!LATEST_VER:v=!"
set "LOCAL_CLEAN=!LOCAL_VER:v=!"

if "!LOCAL_CLEAN!"=="!LATEST_CLEAN!" (
  echo [OK] Ban dang dung phien ban moi nhat.
  echo.
  goto :skip_update
)

echo ================================================================
echo   CO PHIEN BAN MOI: !LATEST_VER!  ^(hien tai: !LOCAL_VER!^)
echo ================================================================
echo.
choice /c YN /n /m "Tai va cap nhat ngay? [Y=Co / N=Bo qua]: "
if errorlevel 2 (
  echo [INFO] Bo qua cap nhat. Tiep tuc voi phien ban cu.
  echo.
  goto :skip_update
)

:: Tien hanh download va giai nen
echo.
echo [UPDATE] Dang tai !LATEST_VER! ...
if not exist "%UPDATE_TMP%" mkdir "%UPDATE_TMP%"
set "ZIP_NAME=CLIProxyAPI_!LATEST_CLEAN!_windows_amd64.zip"
set "ZIP_URL=https://github.com/%GITHUB_REPO%/releases/download/!LATEST_VER!/!ZIP_NAME!"
set "ZIP_PATH=%UPDATE_TMP%\!ZIP_NAME!"

powershell -NoProfile -Command ^
  "try{ Invoke-WebRequest -Uri '!ZIP_URL!' -OutFile '!ZIP_PATH!' -UseBasicParsing; Write-Host 'DOWNLOAD_OK' }catch{ Write-Host ('DOWNLOAD_FAIL:'+$_.Exception.Message) }" > "%UPDATE_TMP%\dl_result.txt" 2>&1
set /p DL_RESULT=<"%UPDATE_TMP%\dl_result.txt"

if not "!DL_RESULT!"=="DOWNLOAD_OK" (
  echo [ERROR] Tai that bai: !DL_RESULT!
  echo [INFO] Tiep tuc voi phien ban cu.
  echo.
  goto :skip_update
)

echo [UPDATE] Dang giai nen...
powershell -NoProfile -Command ^
  "Expand-Archive -Path '!ZIP_PATH!' -DestinationPath '!ZIP_PATH!.extracted' -Force" 2>nul

:: Tim cli-proxy-api.exe trong thu muc giai nen
set "NEW_EXE="
for /r "%ZIP_PATH%.extracted" %%F in (cli-proxy-api.exe) do set "NEW_EXE=%%F"

if not defined NEW_EXE (
  echo [ERROR] Khong tim thay cli-proxy-api.exe trong zip.
  echo [INFO] Tiep tuc voi phien ban cu.
  goto :skip_update
)

:: Backup exe cu va thay the
copy /y "%EXE%" "%EXE%.backup" >nul 2>&1
copy /y "!NEW_EXE!" "%EXE%" >nul
if errorlevel 1 (
  echo [ERROR] Khong the ghi de exe. Thu chay bat nay voi quyen Admin.
  goto :skip_update
)

:: Don dep file tam
rd /s /q "%ZIP_PATH%.extracted" >nul 2>&1
del /q "%ZIP_PATH%" >nul 2>&1
del /q "%UPDATE_TMP%\dl_result.txt" >nul 2>&1

echo [OK] Da cap nhat thanh cong: !LOCAL_VER! --^> !LATEST_VER!
echo.

:skip_update
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
