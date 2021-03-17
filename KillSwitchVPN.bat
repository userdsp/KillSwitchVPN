@echo off

:: GetAdmin
:-------------------------------------
:: Verify permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

:: On Error No Admin
if '%errorlevel%' NEQ '0' (
    echo Getting administrative privileges...
    goto DoUAC
) else ( goto getAdmin )

:DoUAC
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:getAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------


@echo off
:: CHANGE DEFAULT GW IP BELOW
set defgw=127.0.0.1

:: DO NOT EDIT BELOW THIS LINE

set state=Off

@For /f "tokens=3" %%1 in (
   'route.exe print 0.0.0.0 ^|findstr "\<0.0.0.0.*0.0.0.0\>"') Do set defgw=%%1


cls
:start
cls
echo.
color 0F
echo MyVPN Kill Switch

if '%defgw%' EQU '127.0.0.1' (
    FOR /F %%a IN (%temp%\myvpnkillswitch.txt) DO set defgw=%%a
)
 
if '%defgw%' EQU '127.0.0.1' (
    echo Can NOT find your default gateway correctly, please edit the script and change it manually and run again...
    pause
    exit;
)

@echo %defgw% > %temp%\myvpnkillswitch.txt

echo.
echo MAKE SURE YOU ARE CONNECTED TO MyVPN FIRST
echo. 
echo KILL SWITCH IS CURRENTLY: %state%
echo.
echo USAGE: 
echo.
echo -Press "1" to Enable Kill Switch (IP "%defgw%")
echo -Press "2" to Disable Kill Switch (IP "%defgw%")
echo -Press "3" to Fix DNS leak and use google public DNS server     
echo -Press "x" to exit Kill Switch.
echo.
set /p option=Your option: 
if '%option%'=='1' goto :option1
if '%option%'=='2' goto :option2
if '%option%'=='3' goto :option3
if '%option%'=='x' goto :exit
echo Insert 1, 2, 3 or x
timeout 3
goto start
:option1
route delete 0.0.0.0 %defgw%     
echo Default gateway "%defgw%" removed
set state=On
timeout 3
goto start
:option2
route add 0.0.0.0 mask 0.0.0.0 %defgw%
echo Default gateway "%defgw%" restored
set state=Off
timeout 3
goto start
:option3
ipconfig /flushdns
@for /f "tokens=3* delims= " %%a in ('netsh interface show interface ^| findstr "Connected."') do netsh interface IPv4 set dnsserver "%%b" static 8.8.8.8 both & ipconfig /flushdns
timeout 3
goto start

:exit
exit
