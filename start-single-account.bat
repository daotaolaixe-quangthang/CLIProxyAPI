@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title CLIProxyAPI - Custom Account Mode

set "EXE=%~dp0CLIProxyAPI\cli-proxy-api.exe"
set "FILTER_JS=%~dp0CLIProxyAPI\schema-filter.js"
set "INSPECTOR=%~dp0CLIProxyAPI-Quota-Inspector\cpa-quota-inspector.exe"
set "OAUTH_PS1=%~dp0CLIProxyAPI\oauth-clipboard.ps1"
set "BASE_CONFIG=%USERPROFILE%\.cli-proxy-api\config.yaml"
set "AUTH_DIR=%USERPROFILE%\.cli-proxy-api"
set "TEMP_DIR=%USERPROFILE%\.cli-proxy-api-single"
set "TEMP_CONFIG=%USERPROFILE%\.cli-proxy-api-single\config-single.yaml"
set "KEY_FILE=%USERPROFILE%\.cli-proxy-api\management.key"
set "BASE_URL=http://127.0.0.1:8317"
set "GITHUB_REPO=router-for-me/CLIProxyAPI"
set "UPDATE_TMP=%TEMP%\clipa-update"
set "FILTER_PORT=8317"
set "USE_PORT=8318"
set "CLI_PID="
set "FILTER_PID="
set "MANAGEMENT_KEY="
set "QUOTA_KEY_PROMPTED=0"

:: ================================================================
:: BUOC 0: Kiem tra phien ban moi nhat tren GitHub
:: ================================================================
echo.
echo [UPDATE] Dang kiem tra phien ban moi nhat tu GitHub...
echo.

:: Tao thu muc tam neu chua co
if not exist "%UPDATE_TMP%" mkdir "%UPDATE_TMP%"

:: Lay current local version (dung ps1 helper tranh loi escape quotes)
set "GET_VER_PS1=%~dp0CLIProxyAPI\get-local-version.ps1"
set "LOCAL_VER=unknown"
if exist "%EXE%" (
  if exist "%GET_VER_PS1%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%GET_VER_PS1%" -ExePath "%EXE%" > "%UPDATE_TMP%\local_ver.txt" 2>nul
    if exist "%UPDATE_TMP%\local_ver.txt" set /p LOCAL_VER=<"%UPDATE_TMP%\local_ver.txt"
  )
)

:: Lay latest version tu GitHub API (ghi ra file temp tranh loi escape quotes)
set "LATEST_VER="
powershell -NoProfile -Command "try{(Invoke-RestMethod 'https://api.github.com/repos/%GITHUB_REPO%/releases/latest').tag_name}catch{'ERROR'}" > "%UPDATE_TMP%\latest_ver.txt" 2>nul
if exist "%UPDATE_TMP%\latest_ver.txt" set /p LATEST_VER=<"%UPDATE_TMP%\latest_ver.txt"

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
:: BUOC 0b: Kiem tra va giai phong port 8317 va 8318 truoc khi chay
:: ================================================================
call :force_free_start_ports

set "CLI_LOG=%TEMP_DIR%\cli-proxy-api.out.log"
set "CLI_ERR=%TEMP_DIR%\cli-proxy-api.err.log"
set "FILTER_LOG=%TEMP_DIR%\schema-filter.out.log"
set "FILTER_ERR=%TEMP_DIR%\schema-filter.err.log"
set "CLI_PID_FILE=%TEMP_DIR%\cli-proxy-api.pid"
set "FILTER_PID_FILE=%TEMP_DIR%\schema-filter.pid"
call :load_tracked_pids

:: ================================================================
:: BUOC 1: Quet TEMP_DIR xem co *.json de dung lai config cu khong
:: ================================================================
set "PREV_COUNT=0"
for /f "delims=" %%F in ('dir /b /a-d "%TEMP_DIR%\*.json" 2^>nul') do set /a PREV_COUNT+=1

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
for /f "delims=" %%F in ('dir /b /a-d "%TEMP_DIR%\*.json" 2^>nul') do echo   [*] %%F
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
call :stop_owned_processes
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
for /f "delims=" %%F in ('dir /b /a-d "%AUTH_DIR%\*.json" 2^>nul') do (
  set /a COUNT+=1
  set "FILE_!COUNT!=%%F"
  echo   [!COUNT!] %%F
)
if "!COUNT!"=="0" (
  echo [WARN] Chua co file JSON nao trong %AUTH_DIR%
  echo        Bam A de them account OAuth moi hoac Q de thoat.
)
echo ----------------------------------------------------------------
echo.
echo Huong dan:
echo   Nhap SO + Enter : chon / bo chon account do
echo   Nhap A  + Enter : them account OAuth moi
echo   Nhap S  + Enter : xac nhan va bat dau chay
echo   Nhap Q  + Enter : thoat
echo.
for /l %%I in (1,1,99) do set "SEL_%%I="
set "SEL_COUNT=0"

:input_loop
echo Da chon: !SEL_COUNT! account(s)
set "INPUT="
set /p "INPUT=  > Nhap so, A, S hoac Q: "
if not defined INPUT goto input_loop
if /i "!INPUT!"=="Q" exit /b 0
if /i "!INPUT!"=="A" goto add_account_from_pick
if /i "!INPUT!"=="S" goto confirm_selection

set "VALID=0"
for /l %%I in (1,1,!COUNT!) do if "%%I"=="!INPUT!" set "VALID=1"
if "!VALID!"=="0" (
  if "!COUNT!"=="0" (
    echo   [WARN] Chua co account nao de chon. Nhap A de them account OAuth moi.
  ) else (
    echo   [WARN] "!INPUT!" khong hop le. Nhap so 1 den !COUNT!.
  )
  goto input_loop
)

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

:add_account_from_pick
call :oauth_account_menu
cls
goto pick

:confirm_selection
if "!SEL_COUNT!"=="0" ( echo. & echo   [WARN] Chua chon account nao. & goto input_loop )
echo.
echo ================================================================
echo   Cac account se duoc su dung:
echo ================================================================
for /l %%I in (1,1,!COUNT!) do if defined SEL_%%I echo   [*] !FILE_%%I!
echo ================================================================
echo.
choice /c YN /n /m "Xac nhan bat dau chay? [Y=Yes / N=Chon lai]: "
if errorlevel 2 goto pick

call :stop_owned_processes
del /q "%TEMP_DIR%\*.json" >nul 2>&1
for /l %%I in (1,1,!COUNT!) do (
  if defined SEL_%%I (
    copy /y "%AUTH_DIR%\!FILE_%%I!" "%TEMP_DIR%\!FILE_%%I!" >nul
    echo   [COPY] !FILE_%%I!
  )
)

:: ================================================================
:: BUOC 3: Tao config tam va start server nen co PID tracking
:: ================================================================
:start_proxy
call :create_temp_config
if errorlevel 1 (
  echo [ERROR] Khong tao duoc config-single.yaml.
  pause
  goto pick
)

set "ACT_COUNT=0"
for /f "delims=" %%F in ('dir /b /a-d "%TEMP_DIR%\*.json" 2^>nul') do set /a ACT_COUNT+=1
if "!ACT_COUNT!"=="0" (
  echo [ERROR] Khong co account nao trong %TEMP_DIR%.
  pause
  goto pick
)

call :assert_ports_available
if errorlevel 1 (
  echo.
  echo [ERROR] Khong the start vi port dang ban. Script nay se khong kill process khac.
  echo [INFO] Hay dung server hien tai thu cong truoc, neu ban muon doi account.
  pause
  goto pick
)

call :start_server_processes
if errorlevel 1 (
  echo.
  echo [ERROR] Start server that bai. Xem log:
  echo   CLI    : %CLI_ERR%
  echo   Filter : %FILTER_ERR%
  pause
  goto pick
)

call :load_management_key

goto tui_loop

:tui_loop
cls
call :refresh_runtime_status
echo.
echo ================================================================
echo   CLIProxyAPI - Custom Account Mode TUI
echo ================================================================
echo   So account   : !ACT_COUNT!
echo   Claude Code  : port !FILTER_PORT! ^(schema-filter^)
echo   CLIProxyAPI  : port !USE_PORT!
echo   CLI PID      : !CLI_STATUS!
echo   Filter PID   : !FILTER_STATUS!
echo   Auto refresh : 15 phut / lan
echo ================================================================
echo.
call :render_quota
echo.
echo ================================================================
echo   MENU
echo ================================================================
echo   [R] Reload server voi account hien tai
echo   [B] Tat server va quay lai chon account
echo   [A] Them account OAuth moi
echo   [S] Refresh quota ngay
echo   [Q] Tat server va thoat hoan toan
echo ================================================================
echo.
choice /c RBASQ /n /t 900 /d S /m "  [R/B/A/S/Q]: "
set "TUI_CHOICE=!ERRORLEVEL!"
if "!TUI_CHOICE!"=="5" goto tui_quit
if "!TUI_CHOICE!"=="4" goto tui_loop
if "!TUI_CHOICE!"=="3" goto tui_add_account
if "!TUI_CHOICE!"=="2" goto tui_back
if "!TUI_CHOICE!"=="1" goto tui_reload
goto tui_loop

:tui_reload
echo.
echo [INFO] Dang reload server voi account hien tai...
call :stop_owned_processes
call :create_temp_config
if errorlevel 1 (
  echo [ERROR] Khong tao duoc config-single.yaml.
  pause
  goto pick
)
call :assert_ports_available
if errorlevel 1 (
  echo [ERROR] Port dang ban sau khi reload.
  pause
  goto pick
)
call :start_server_processes
if errorlevel 1 (
  echo [ERROR] Reload server that bai.
  pause
  goto pick
)
goto tui_loop

:tui_back
echo.
echo [INFO] Dang tat server va quay lai chon account...
call :stop_owned_processes
goto clear_and_pick

:tui_add_account
echo.
echo [INFO] Dang tat server hien tai de them account OAuth moi...
call :stop_owned_processes
call :oauth_account_menu
cls
goto pick

:tui_quit
echo.
echo [INFO] Dang tat server va thoat...
call :stop_owned_processes
echo [OK] Da tat cac process do script nay start.
exit /b 0

:shutdown_clean
echo.
echo [INFO] Dang don dep...
call :stop_owned_processes
del /q "%TEMP_DIR%\*.json" >nul 2>&1
del /q "%TEMP_CONFIG%" >nul 2>&1
del /q "%CLI_PID_FILE%" >nul 2>&1
del /q "%FILTER_PID_FILE%" >nul 2>&1
echo [OK] Da xoa: JSON session, config-single.yaml, PID temp.
echo [OK] Files goc tai %AUTH_DIR% KHONG bi thay doi.
exit /b 0

:create_temp_config
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$c=[IO.File]::ReadAllText($env:BASE_CONFIG);" ^
  "$auth='auth-dir: '+[char]34+'~/.cli-proxy-api-single'+[char]34;" ^
  "$c=[regex]::Replace($c,'(?m)^auth-dir:\s*.*$',$auth);" ^
  "if([regex]::IsMatch($c,'(?m)^port:\s*.*$')){$c=[regex]::Replace($c,'(?m)^port:\s*.*$','port: 8318',1)}else{$c='port: 8318'+[Environment]::NewLine+$c};" ^
  "[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($env:TEMP_CONFIG))>$null;" ^
  "[IO.File]::WriteAllText($env:TEMP_CONFIG,$c,[Text.UTF8Encoding]::new($false))" >nul 2>&1
if errorlevel 1 exit /b 1
if not exist "%TEMP_CONFIG%" exit /b 1
exit /b 0

:assert_ports_available
call :force_free_start_ports
exit /b 0

:force_free_start_ports
echo [INFO] Kiem tra port 8317 va 8318...
powershell -NoProfile -Command ^
  "$ports=@(8317,8318);$busy=$false;" ^
  "foreach($p in $ports){" ^
  "  $pids=(netstat -ano|Select-String (':'+$p+' ')|ForEach-Object{($_ -split '\s+')[-1]}|Sort-Object -Unique);" ^
  "  if($pids){$busy=$true;Write-Host ('  [WARN] Port '+$p+' bi chiem. Dang giai phong...');" ^
  "    $pids|ForEach-Object{try{Stop-Process -Id $_ -Force -EA Stop;Write-Host ('    -> Killed PID '+$_)}catch{}}}" ^
  "  else{Write-Host ('  [OK] Port '+$p+' san sang.')}" ^
  "}" ^
  "if($busy){Start-Sleep -Seconds 1;Write-Host '[OK] Da giai phong xong.'}" ^
  "else{Write-Host '[OK] Ca 2 port san sang.'}"
echo.
exit /b 0

:start_server_processes
set "CLI_PID="
set "FILTER_PID="
del /q "%CLI_PID_FILE%" "%FILTER_PID_FILE%" >nul 2>&1

echo [INFO] Khoi dong CLIProxyAPI tren port !USE_PORT!...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';try{$wd=Split-Path -Parent $env:EXE;$p=Start-Process -FilePath $env:EXE -ArgumentList @('--config',$env:TEMP_CONFIG) -WorkingDirectory $wd -WindowStyle Hidden -RedirectStandardOutput $env:CLI_LOG -RedirectStandardError $env:CLI_ERR -PassThru;[Console]::Out.WriteLine($p.Id)}catch{[Console]::Error.WriteLine($_.Exception.Message);exit 1}" > "%CLI_PID_FILE%" 2> "%TEMP_DIR%\cli-start.err"
if errorlevel 1 exit /b 1
if not exist "%CLI_PID_FILE%" exit /b 1
set /p CLI_PID=<"%CLI_PID_FILE%"
if not defined CLI_PID exit /b 1

call :wait_port "%USE_PORT%" 25
if errorlevel 1 (
  echo [ERROR] CLIProxyAPI khong san sang tren port !USE_PORT!.
  call :stop_owned_processes
  exit /b 1
)

echo [INFO] Khoi dong Schema Filter tren port !FILTER_PORT! -^> !USE_PORT!...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';try{$wd=Split-Path -Parent $env:FILTER_JS;$p=Start-Process -FilePath 'node' -ArgumentList @($env:FILTER_JS,$env:FILTER_PORT,$env:USE_PORT) -WorkingDirectory $wd -WindowStyle Hidden -RedirectStandardOutput $env:FILTER_LOG -RedirectStandardError $env:FILTER_ERR -PassThru;[Console]::Out.WriteLine($p.Id)}catch{[Console]::Error.WriteLine($_.Exception.Message);exit 1}" > "%FILTER_PID_FILE%" 2> "%TEMP_DIR%\filter-start.err"
if errorlevel 1 (
  call :stop_owned_processes
  exit /b 1
)
if not exist "%FILTER_PID_FILE%" (
  call :stop_owned_processes
  exit /b 1
)
set /p FILTER_PID=<"%FILTER_PID_FILE%"
if not defined FILTER_PID (
  call :stop_owned_processes
  exit /b 1
)

call :wait_http_head "%FILTER_PORT%" 25
if errorlevel 1 (
  echo [ERROR] Schema Filter khong san sang tren port !FILTER_PORT!.
  call :stop_owned_processes
  exit /b 1
)

echo [OK] Server da chay nen. CLI PID=!CLI_PID!, Filter PID=!FILTER_PID!.
exit /b 0

:wait_port
set "WAIT_PORT=%~1"
set "WAIT_SECONDS=%~2"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$deadline=(Get-Date).AddSeconds([int]$env:WAIT_SECONDS);" ^
  "do{" ^
  "  try{" ^
  "    $client=New-Object Net.Sockets.TcpClient;" ^
  "    $async=$client.BeginConnect('127.0.0.1',[int]$env:WAIT_PORT,$null,$null);" ^
  "    if($async.AsyncWaitHandle.WaitOne(500)){$client.EndConnect($async);$client.Close();exit 0}" ^
  "    $client.Close();" ^
  "  }catch{}" ^
  "  Start-Sleep -Milliseconds 500;" ^
  "}while((Get-Date) -lt $deadline);exit 1" >nul 2>&1
exit /b %ERRORLEVEL%

:wait_http_head
set "WAIT_PORT=%~1"
set "WAIT_SECONDS=%~2"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$deadline=(Get-Date).AddSeconds([int]$env:WAIT_SECONDS);" ^
  "do{" ^
  "  try{" ^
  "    $r=Invoke-WebRequest -Uri ('http://127.0.0.1:'+$env:WAIT_PORT+'/') -Method Head -TimeoutSec 2 -UseBasicParsing;" ^
  "    if([int]$r.StatusCode -ge 200 -and [int]$r.StatusCode -lt 500){exit 0}" ^
  "  }catch{}" ^
  "  Start-Sleep -Milliseconds 500;" ^
  "}while((Get-Date) -lt $deadline);exit 1" >nul 2>&1
exit /b %ERRORLEVEL%

:wait_port_free
set "WAIT_PORT=%~1"
set "WAIT_SECONDS=%~2"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$deadline=(Get-Date).AddSeconds([int]$env:WAIT_SECONDS);" ^
  "do{" ^
  "  $items=Get-NetTCPConnection -LocalPort ([int]$env:WAIT_PORT) -State Listen -ErrorAction SilentlyContinue;" ^
  "  if(-not $items){exit 0}" ^
  "  Start-Sleep -Milliseconds 500;" ^
  "}while((Get-Date) -lt $deadline);exit 1" >nul 2>&1
exit /b %ERRORLEVEL%

:stop_owned_processes
call :load_tracked_pids
set "KEEP_FILTER_PID="
set "KEEP_CLI_PID="
set "DID_STOP_FILTER="
set "DID_STOP_CLI="
if defined FILTER_PID (
  call :stop_schema_filter
  if errorlevel 1 (
    set "KEEP_FILTER_PID=1"
  ) else (
    set "DID_STOP_FILTER=1"
  )
)
if defined CLI_PID (
  call :stop_cli_proxy
  if errorlevel 1 (
    set "KEEP_CLI_PID=1"
  ) else (
    set "DID_STOP_CLI=1"
  )
)
call :kill_filter_port_legacy
if defined DID_STOP_CLI if defined USE_PORT call :wait_port_free "%USE_PORT%" 5
set "FILTER_PID="
set "CLI_PID="
if not defined KEEP_FILTER_PID del /q "%FILTER_PID_FILE%" >nul 2>&1
if not defined KEEP_CLI_PID del /q "%CLI_PID_FILE%" >nul 2>&1
exit /b 0

:kill_filter_port_legacy
echo [INFO] Proxy da dung. Dung Schema Filter (port !FILTER_PORT!)...
for /f "tokens=5" %%P in ('netstat -ano 2^>nul ^| findstr ":!FILTER_PORT! "') do taskkill /f /pid %%P >nul 2>&1
exit /b 0

:load_tracked_pids
if not defined CLI_PID if exist "%CLI_PID_FILE%" set /p CLI_PID=<"%CLI_PID_FILE%"
if not defined FILTER_PID if exist "%FILTER_PID_FILE%" set /p FILTER_PID=<"%FILTER_PID_FILE%"
exit /b 0

:stop_schema_filter
if not defined FILTER_PID exit /b 0
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$pidText=$env:FILTER_PID;if([string]::IsNullOrWhiteSpace($pidText)){exit 0};" ^
  "$proc=Get-CimInstance Win32_Process -Filter ('ProcessId='+$pidText) -ErrorAction SilentlyContinue;" ^
  "if(-not $proc){exit 0};" ^
  "$cmd=[string]$proc.CommandLine;" ^
  "$ok=($cmd -like '*schema-filter.js*' -and $cmd -like ('*'+$env:FILTER_PORT+'*') -and $cmd -like ('*'+$env:USE_PORT+'*'));" ^
  "if(-not $ok){Write-Host ('[WARN] Bo qua PID '+$pidText+' vi khong khop schema-filter da start.');exit 2};" ^
  "Stop-Process -Id ([int]$pidText) -Force;exit 0"
exit /b %ERRORLEVEL%

:stop_cli_proxy
if not defined CLI_PID exit /b 0
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$pidText=$env:CLI_PID;if([string]::IsNullOrWhiteSpace($pidText)){exit 0};" ^
  "$proc=Get-CimInstance Win32_Process -Filter ('ProcessId='+$pidText) -ErrorAction SilentlyContinue;" ^
  "if(-not $proc){exit 0};" ^
  "$cmd=[string]$proc.CommandLine;" ^
  "$ok=($cmd -like '*cli-proxy-api.exe*' -and $cmd -like ('*'+$env:TEMP_CONFIG+'*'));" ^
  "if(-not $ok){Write-Host ('[WARN] Bo qua PID '+$pidText+' vi khong khop CLIProxyAPI da start.');exit 2};" ^
  "Stop-Process -Id ([int]$pidText) -Force;exit 0"
exit /b %ERRORLEVEL%

:is_tracked_cli_pid
if not defined CLI_PID exit /b 1
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$pidText=$env:CLI_PID;$proc=Get-CimInstance Win32_Process -Filter ('ProcessId='+$pidText) -ErrorAction SilentlyContinue;" ^
  "if(-not $proc){exit 1};" ^
  "$cmd=[string]$proc.CommandLine;" ^
  "if($cmd -like '*cli-proxy-api.exe*' -and $cmd -like ('*'+$env:TEMP_CONFIG+'*')){exit 0}else{exit 1}" >nul 2>&1
exit /b %ERRORLEVEL%

:is_tracked_filter_pid
if not defined FILTER_PID exit /b 1
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$pidText=$env:FILTER_PID;$proc=Get-CimInstance Win32_Process -Filter ('ProcessId='+$pidText) -ErrorAction SilentlyContinue;" ^
  "if(-not $proc){exit 1};" ^
  "$cmd=[string]$proc.CommandLine;" ^
  "if($cmd -like '*schema-filter.js*' -and $cmd -like ('*'+$env:FILTER_PORT+'*') -and $cmd -like ('*'+$env:USE_PORT+'*')){exit 0}else{exit 1}" >nul 2>&1
exit /b %ERRORLEVEL%

:refresh_runtime_status
set "CLI_STATUS=not running"
set "FILTER_STATUS=not running"
call :is_tracked_cli_pid
if not errorlevel 1 set "CLI_STATUS=!CLI_PID! (running)"
call :is_tracked_filter_pid
if not errorlevel 1 set "FILTER_STATUS=!FILTER_PID! (running)"
exit /b 0

:load_management_key
set "MANAGEMENT_KEY="
if exist "%KEY_FILE%" set /p MANAGEMENT_KEY=<"%KEY_FILE%"
if defined MANAGEMENT_KEY exit /b 0
if "%QUOTA_KEY_PROMPTED%"=="1" exit /b 0
set "QUOTA_KEY_PROMPTED=1"
echo.
echo [INFO] Chua tim thay management key tai: %KEY_FILE%
set /p "MANAGEMENT_KEY=Nhap management key de hien thi quota, hoac Enter de bo qua: "
if not defined MANAGEMENT_KEY exit /b 0
echo.
choice /c YN /n /m "Luu key vao file de lan sau dung lai? [Y/N]: "
if errorlevel 2 exit /b 0
powershell -NoProfile -ExecutionPolicy Bypass -Command "[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($env:KEY_FILE))>$null;[IO.File]::WriteAllText($env:KEY_FILE,$env:MANAGEMENT_KEY,[Text.UTF8Encoding]::new($false))" >nul 2>&1
echo [OK] Da luu key.
exit /b 0

:oauth_account_menu
set "OAUTH_NAME="
set "OAUTH_MODE="
set "OAUTH_FLAG="
set "OAUTH_EXIT=0"
cls
echo.
echo ================================================================
echo   THEM ACCOUNT OAUTH MOI
echo ================================================================
echo   [1] Antigravity
echo   [2] Codex
echo   [3] Gemini CLI
echo   [4] Grok / xAI
echo   [B] Quay lai
echo ================================================================
echo.
choice /c 1234B /n /m "Chon loai account OAuth [1-4/B]: "
set "OAUTH_CHOICE=!ERRORLEVEL!"
if "!OAUTH_CHOICE!"=="5" exit /b 0
if "!OAUTH_CHOICE!"=="1" (
  set "OAUTH_NAME=Antigravity"
  set "OAUTH_MODE=PS1"
  set "OAUTH_FLAG=--antigravity-login"
)
if "!OAUTH_CHOICE!"=="2" (
  set "OAUTH_NAME=Codex"
  set "OAUTH_MODE=CODEX"
)
if "!OAUTH_CHOICE!"=="3" (
  set "OAUTH_NAME=Gemini CLI"
  set "OAUTH_MODE=PS1"
  set "OAUTH_FLAG=--login"
)
if "!OAUTH_CHOICE!"=="4" (
  set "OAUTH_NAME=Grok / xAI"
  set "OAUTH_MODE=PS1"
  set "OAUTH_FLAG=--xai-login"
)
if not defined OAUTH_NAME exit /b 1
cls
echo.
echo ================================================================
echo   !OAUTH_NAME! OAuth Login
echo ================================================================
echo.
if /i "!OAUTH_MODE!"=="CODEX" (
  if not exist "%OAUTH_PS1%" (
    echo [ERROR] Khong tim thay OAuth helper:
    echo        %OAUTH_PS1%
    set "OAUTH_EXIT=1"
  ) else (
    echo [INFO] URL OAuth se hien thi va tu dong copy vao Clipboard
    echo [INFO] Dang nhap vao tai khoan OpenAI cua ban
    echo [INFO] OAuth callback dung port 1455
    echo [INFO] Neu browser o may khac va khong dung SSH tunnel, paste callback URL vao terminal khi duoc hoi
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%OAUTH_PS1%" -LoginFlag "--codex-login" -Config "%BASE_CONFIG%" -InteractiveRelay
    set "OAUTH_EXIT=!ERRORLEVEL!"
  )
) else (
  if not exist "%OAUTH_PS1%" (
    echo [ERROR] Khong tim thay OAuth helper:
    echo        %OAUTH_PS1%
    set "OAUTH_EXIT=1"
  ) else (
    echo [INFO] URL OAuth se hien thi va tu dong copy vao Clipboard
    echo [INFO] Hay paste vao browser profile ban muon
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%OAUTH_PS1%" -LoginFlag "!OAUTH_FLAG!"
    set "OAUTH_EXIT=!ERRORLEVEL!"
  )
)
echo.
if "!OAUTH_EXIT!"=="0" (
  echo [OK] OAuth !OAUTH_NAME! da hoan tat.
) else (
  echo [WARN] OAuth !OAUTH_NAME! chua hoan tat hoac da bi huy. Ma loi: !OAUTH_EXIT!
)
echo.
echo Nhan Enter de quay lai man hinh chon account.
pause >nul
exit /b 0

:render_quota
echo ================================================================
echo   QUOTA DASHBOARD - refresh thu cong bang phim S
echo ================================================================
if not exist "%INSPECTOR%" (
  echo [WARN] Khong tim thay Quota Inspector:
  echo        %INSPECTOR%
  exit /b 0
)
if not defined MANAGEMENT_KEY (
  echo [WARN] Chua co management key, bo qua hien thi quota.
  exit /b 0
)
call :is_tracked_filter_pid
if errorlevel 1 (
  echo [WARN] Schema Filter khong chay, chua the lay quota tu %BASE_URL%.
  exit /b 0
)
echo [INFO] Dang tai quota live, co the mat 20-30 giay...
echo.
"%INSPECTOR%" --cpa-base-url "%BASE_URL%" -k "%MANAGEMENT_KEY%"
set "QUOTA_EXIT=!ERRORLEVEL!"
if not "!QUOTA_EXIT!"=="0" (
  echo.
  echo [WARN] Khong the lay quota luc nay. Server van duoc giu nguyen.
)
exit /b 0
