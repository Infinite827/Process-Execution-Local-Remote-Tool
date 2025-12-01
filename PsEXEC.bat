@echo off
title Process Execution Local Remote Tool Console
cd files >nul 2>&1
mode 100, 30
color 0B
rem color 0B = black background, bright aqua text (your preference)
set success=[92m[+][0m
set warning=[91m[!][0m
set info=[94m[*][0m
set servicename=winrm%random%

:start
cls
call :banner
echo.
echo  ╔════════════╗
echo  ║  Computer  ║
echo  ╚════════════╝
set /p domain="[92m>>[0m "
echo.
echo  ╔════════════╗
echo  ║  Username  ║
echo  ╚════════════╝
set /p user="[92m>>[0m "
echo.
echo  ╔════════════╗
echo  ║  Password  ║
echo  ╚════════════╝
set /p pass="[92m>>[0m "
echo.

rem Keep original user input for display, but normalize domain for actions
set "orig_domain=%domain%"
if /I "%domain%"=="192.168.2.13" set "domain=localhost"
if /I "%domain%"=="127.0.0.1" set "domain=localhost"
if /I "%domain%"=="localhost" set "domain=localhost"

echo %info% Connecting to %orig_domain%...

rem Disconnect any existing connection for that target (best effort)
net use \\%domain% /d /y >nul 2>&1
net use \\%domain% /user:%user% %pass% >nul 2>&1

if %errorlevel% NEQ 0 (
    echo %warning% Invalid credentials or network issue
    pause
    goto start
)

echo %success% Connected!
call :winrm_check
goto menu

:winrm_check
rem If we're dealing with a local target, skip WinRM checks
if /I "%domain%"=="localhost" goto :eof
echo %info% Checking for WinRM on %orig_domain%...
chcp 437 >nul 2>&1
powershell -Command "Test-WSMan -ComputerName '%domain%'" >nul 2>&1
set errorcode=%errorlevel%
chcp 65001 >nul 2>&1

if %errorcode% NEQ 0 (
    echo %info% Enabling WinRM remotely...
    rem create a small service to run quickconfig, start it and remove it
    sc \\%domain% create %servicename% binPath= "cmd.exe /c winrm quickconfig -force" >nul 2>&1
    sc \\%domain% start %servicename% >nul 2>&1
    sc \\%domain% delete %servicename% >nul 2>&1
    echo %success% WinRM enabled on %orig_domain% (attempted).
) else (
    echo %success% WinRM already enabled on %orig_domain%!
)
timeout /t 2 >nul 2>&1
goto :eof

:menu
cls
call :banner
echo.
echo %info% Connected to %orig_domain%
echo.
echo [92m[1][0m » Shell
echo [92m[2][0m » Files
echo [92m[3][0m » Information
echo [92m[4][0m » Shutdown
echo [92m[5][0m » Processes
echo [92m[6][0m » Restart
echo [92m[7][0m » Services
echo [92m[8][0m » Network
echo [92m[9][0m » Users / Sessions
echo [92m[10][0m » Log Off User
echo [92m[11][0m » Lock Workstation
echo [92m[12][0m » Fix UI
echo [92m[13][0m » Open URL
echo [92m[14][0m » System User Management
echo [92m[15][0m » MsgBox
echo [92m[update][0m » Self Update
echo.
set /p menuopt="[92m>>[0m "

rem --- Menu option routing ---
if /I "%menuopt%"=="1" goto shell
if /I "%menuopt%"=="2" goto files
if /I "%menuopt%"=="3" goto info
if /I "%menuopt%"=="4" goto shutdown
if /I "%menuopt%"=="5" goto processes
if /I "%menuopt%"=="6" goto restart
if /I "%menuopt%"=="7" goto services
if /I "%menuopt%"=="8" goto network
if /I "%menuopt%"=="9" goto users
if /I "%menuopt%"=="10" goto logoff
if /I "%menuopt%"=="11" goto lock
if /I "%menuopt%"=="12" goto fix_ui
if /I "%menuopt%"=="13" goto open_url
if /I "%menuopt%"=="14" goto system_user
if /I "%menuopt%"=="15" goto msgbox
if /I "%menuopt%"=="update" goto update

goto menu

:shell
cls
call :banner
echo.
echo %info% Enter commands. Type return to go back.
echo.

if /I "%domain%"=="localhost" (
    rem localshell loop — no label text before prompt, no empty entries
    :localshell_loop
    set "cmdin="
    set /p "cmdin=[92m>>[0m "
    rem trim leading/trailing spaces
    for /f "tokens=* delims= " %%A in ("%cmdin%") do set "cmdin=%%A"
    if "%cmdin%"=="" goto localshell_loop
    if /I "%cmdin%"=="return" goto menu
    rem run the entered command locally
    cmd /c "%cmdin%"
    echo %success% Script Successfully Executed
    goto localshell_loop
) else (
    rem remote shell via WinRM — open interactive remote cmd session
    echo %info% Opening Remote Shell via WinRM on %orig_domain%...
    winrs -r:%domain% -u:%user% -p:%pass% cmd
    rem remote shell returns to menu automatically
)
pause >nul 2>&1
goto menu

:files
cls
call :banner
echo.
echo %info% Opening Files...
if /I "%domain%"=="localhost" (
    start "" "C:\"
) else (
    start "" "\\%domain%\C$"
)
goto menu

:info
cls
call :banner
echo.
echo %info% Gathering Information...
if /I "%domain%"=="localhost" (
    systeminfo
) else (
    rem copy & run info.bat remotely if you have it locally
    if exist "%~dp0info.bat" (
        copy "%~dp0info.bat" "\\%domain%\C$\ProgramData\info.bat" >nul 2>&1
        winrs -r:%domain% -u:%user% -p:%pass% C:\ProgramData\info.bat
        del "\\%domain%\C$\ProgramData\info.bat" >nul 2>&1
    ) else (
        echo %warning% info.bat not found in script folder. Place info.bat next to this script for remote execution.
    )
)
pause
goto menu

:shutdown
cls
call :banner
echo.
if /I "%domain%"=="localhost" (
    shutdown /s /f /t 0
) else (
    winrs -r:%domain% -u:%user% -p:%pass% "shutdown /s /f /t 0"
)
goto menu

:processes
cls
call :banner
echo.
echo %info% Fetching running processes...
if /I "%domain%"=="localhost" (
    tasklist
) else (
    winrs -r:%domain% -u:%user% -p:%pass% "tasklist"
)
pause
goto menu

:restart
cls
call :banner
echo.
if /I "%domain%"=="localhost" (
    shutdown /r /f /t 0
) else (
    winrs -r:%domain% -u:%user% -p:%pass% "shutdown /r /f /t 0"
)
goto menu

:services
cls
call :banner
echo.
echo %info% Listing services...
if /I "%domain%"=="localhost" (
    sc query state= all
    echo.
    echo %info% (Maintenance/Automation services shown above)
) else (
    winrs -r:%domain% -u:%user% -p:%pass% "sc query state= all"
)
pause
goto menu

:network
cls
call :banner
echo.
echo %info% Network information...
if /I "%domain%"=="localhost" (
    ipconfig /all
    echo.
    netstat -an
) else (
    winrs -r:%domain% -u:%user% -p:%pass% "ipconfig /all"
    winrs -r:%domain% -u:%user% -p:%pass% "netstat -an"
)
pause
goto menu

:users
cls
call :banner
echo.
echo %info% Users on %orig_domain%:
if /I "%domain%"=="localhost" (
    rem net user lists local user accounts; format output slightly
    net user
) else (
    winrs -r:%domain% -u:%user% -p:%pass% "net user"
)
pause
goto menu

:logoff
cls
call :banner
echo.
if /I "%domain%"=="localhost" (
    shutdown /l
) else (
    winrs -r:%domain% -u:%user% -p:%pass% "shutdown /l"
)
goto menu

:lock
cls
call :banner
echo.
if /I "%domain%"=="localhost" (
    rundll32.exe user32.dll,LockWorkStation
) else (
    winrs -r:%domain% -u:%user% -p:%pass% "rundll32.exe user32.dll,LockWorkStation"
)
pause
goto menu

:fix_ui
cls
call :banner
echo.
if /I "%domain%"=="localhost" (
    taskkill /f /im explorer.exe >nul 2>&1
    start explorer.exe
)
goto menu

:open_url
cls
call :banner
echo.
set /p url="Enter URL [92m>>[0m "
if /I "%domain%"=="localhost" (
    start "" "%url%"
) else (
    rem remote open via WinRM (best-effort)
    winrs -r:%domain% -u:%user% -p:%pass% "start \"\" \"%url%\"" >nul 2>&1
)
goto menu

:system_user
cls
call :banner
echo.
echo [1] Create User
echo [2] Delete User
set /p um="[92m>>[0m "

if "%um%"=="1" (
    set /p newuser="Username >> "
    set /p newpass="Password >> "
    net user "%newuser%" "%newpass%" /add
    echo %success% User %newuser% created.
    pause
    goto menu
)
if "%um%"=="2" (
    set /p del="User to delete >> "
    rem check existence using 'net user'
    net user "%del%" >nul 2>&1
    if %errorlevel% NEQ 0 (
        echo %warning% No matches found for %del%
        pause
        goto menu
    )
    set /p confirm="Are you sure you want to delete %del%? Y/N >> "
    if /I "%confirm%"=="Y" (
        net user "%del%" /delete
        echo %success% User %del% deleted.
        pause
    ) else (
        echo %info% Deletion cancelled.
        pause
    )
    goto menu
)
goto menu

:msgbox
cls
call :banner
echo.
echo %info% Local MsgBox Launcher
echo.
echo Types: ok, error, warn, info, question
set /p mtype="Type >> "
set /p mtext="Text >> "

rem Map type to PowerShell enums
set "mbutton=OK"
set "mimage=None"
if /I "%mtype%"=="ok" set "mbutton=OK" & set "mimage=None"
if /I "%mtype%"=="error" set "mbutton=OK" & set "mimage=Error"
if /I "%mtype%"=="warn" set "mbutton=OK" & set "mimage=Warning"
if /I "%mtype%"=="info" set "mbutton=OK" & set "mimage=Information"
if /I "%mtype%"=="question" set "mbutton=YesNo" & set "mimage=Question"

rem Escape double quotes in the message text
set "mtext=%mtext:"=`"%"

rem Call PowerShell safely
powershell -NoProfile -Command ^
"Add-Type -AssemblyName PresentationFramework; ^
[System.Windows.MessageBox]::Show(\"%mtext%\", 'Message', [System.Windows.MessageBoxButton]::%mbutton%, [System.Windows.MessageBoxImage]::%mimage%)"

goto menu

:update
cls
call :banner
echo.
rem Update routine: supports .bat and .exe hash comparison and restart
setlocal enabledelayedexpansion
set "hashfile=%~dp0version.dat"
set "scriptpath=%~f0"
set "scriptext=%~x0"

rem compute MD5 hash of the running file
certutil -hashfile "%scriptpath%" MD5 > "%temp%\script.hash" 2>nul
for /f "usebackq tokens=1,* delims= " %%A in ("%temp%\script.hash") do (
    rem skip lines that say 'MD5 hash of file'
    if /I "%%A"=="MD5" (
        rem nothing
    ) else (
        rem first non-header line likely contains the hash (line with hex groups)
        set "maybe=%%A %%B"
    )
)
rem fallback: try to read the second line produced by certutil explicitly
for /f "skip=1 tokens=1,*" %%H in ('type "%temp%\script.hash"') do if not defined newhash set "newhash=%%H"

del "%temp%\script.hash" 2>nul

rem If newhash still empty, try a different parsing
if not defined newhash (
    certutil -hashfile "%scriptpath%" MD5 > "%temp%\script2.hash" 2>nul
    for /f "tokens=1" %%H in ('findstr /r /v "^$" "%temp%\script2.hash" ^| findstr /v /i "hash" ^| findstr /v /i "MD5"') do (
        if not defined newhash set "newhash=%%H"
    )
    del "%temp%\script2.hash" 2>nul
)

if not defined newhash (
    echo %warning% Unable to compute file hash.
    endlocal
    pause
    goto menu
)

rem read old hash if exists
if exist "%hashfile%" (
    set /p "oldhash="<"%hashfile%"
) else (
    set "oldhash="
)

if "!newhash!"=="!oldhash!" (
    echo %info% No changes detected. Script is same version.
    endlocal
    pause
    goto menu
) else (
    echo %info% Changes detected. Restarting program...
    rem write new hash
    > "%hashfile%" echo !newhash!
    rem If we're a .exe or .bat, just start a new instance and exit current.
    if /I "%scriptext%"==".exe" (
        timeout /t 1 >nul
        start "" "%scriptpath%"
        endlocal
        exit /b
    ) else (
        rem .bat or other - restart
        timeout /t 1 >nul
        start "" "%scriptpath%"
        endlocal
        exit /b
    )
)
goto menu

:banner
echo.
echo.
echo [92m                         ██████╗ ███████╗███████╗██╗  ██╗███████╗ ██████╗  [0m
echo [92m                         ██╔══██╗██╔════╝██╔════╝╚██╗██╔╝██╔════╝██╔════╝  [0m
echo [92m                         ██████╔╝███████╗█████╗   ╚███╔╝ █████╗  ██║       [0m
echo [92m                         ██╔═══╝ ╚════██║██╔══╝   ██╔██╗ ██╔══╝  ██║       [0m
echo [92m                         ██║     ███████║███████╗██╔╝ ██╗███████╗╚██████╗  [0m
echo [92m                         ╚═╝     ╚══════╝╚══════╝╚═╝  ╚═╝╚══════╝ ╚═════╝  [0m
echo.
echo.
goto :eof
