@echo off
setlocal enabledelayedexpansion


echo ========================================
echo set region kvdata: 
echo ========================================

REM check params

set "show_help=0"
set "param_file=%1"

if "%param_file%"=="" (
    echo "useage:"
    echo "    batch_set_kvdata.bat xxxx.json"
    goto :eof
)

if not exist "%param_file%" (
    echo param json file NOT found.
    goto :eof
)

set "title_id=4ntzr"
set "server_key=AARL-N9SG-NYO4-4F5D-4591"
echo GSTMTitleID = %title_id% , ServerKey = %server_key%

REM read all regions
set "region_cfg=title_regions.txt"
if not exist "%region_cfg%" (
    echo title_regions.txt NOT found!
    pause
    goto :eof
)

REM set server key
pgos_cli.exe set-secret-key %server_key%


REM set all region kvdata 
for /f "usebackq tokens=1,* delims==" %%a in ("%region_cfg%") do (
    set "name=%%a"
    set "region=%%b"

    echo. 
    echo "==== title_region(!name!) = !region! ===="
    
    REM set title region
    pgos_cli.exe set-title-region !region!
    
    
    REM set-player-kv-data-tpl
    pgos_cli.exe set-player-kv-data-tpl --cli-load-json "../%param_file%"
)


echo ========================================
echo pgos_cli.exe set-player-kv-data-tpl %1 all OK
echo ========================================
