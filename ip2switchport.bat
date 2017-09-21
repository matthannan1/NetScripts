@echo off
setlocal enabledelayedexpansion

rem Created by Matt Hannan on 21 Sep 2017
rem This version requires local access to plink.exe
rem         and meili.exe.

set "user=%USERNAME%"
set "routerIP="
set "routerName="
set "mac="
set "vlan="
set "routerPort="
set "switchName="
set "switchIP="
set "switchPort="

cls
echo ************************************************************
echo.
echo Welcome to IP to Switch Port Discovery
echo.
set /P ip_addr=IP Address to find? 
set /P pass=What is your password? 
cls
echo.
echo Here we go!
echo.
echo ************************************************************

rem ************************************************************
rem 147.141.164.35 - done
rem ip_addr to router_ip(.250) - Done
rem plink router
rem 	"sh ip arp ip_addr" to get mac and vlan - Done
rem 	grab routerName for meili - Done
rem plink router - Done
rem		"sh mac add add !mac!" looking for port on downlink to switch - Done
rem trim down to "Te2/14" - Done
rem plink router  - Done
rem 	"sh int !routerPort!" - Done
rem trim down to switch name - Done
rem plink switch	- Done
rem 	sh mac add add %mac% -Done
rem extract switchPort -Done
rem display switchPort -Done
rem ************************************************************

rem Extract router interface IP address
for /f "tokens=1,2,3 delims=." %%A in ("!ip_addr!") do (
	set "routerIP=%%A.%%B.%%C.250"
	)
rem echo %routerIP%	

rem plink to routerIP to set ssh key
echo.
echo This is to verify that you have accepted the ssh key,
echo which will be required later in the discovery process.
echo.
echo *** Not performing this step _WILL_ result in failure. ***
echo.
echo To prevent this, a new CMD window will now be opened.
echo Simply enter y to accept the ssh key. 
echo You will then automatically log into the router.
echo At this point, you should simply enter "exit" 
echo to leave the router and continue on.
echo.
echo We are about to connect to the %routerIP% interface.
pause
start plink -ssh %routerIP% -l %user% -pw %pass%
echo.
echo Welcome back. 
echo.
echo When you are ready to continue, hit Enter.
echo.
pause

rem Build sharp.txt file
IF EXIST sharp.txt del /F sharp.txt
echo sh ip arp %ip_addr% >> sharp.txt

rem Make call to router
IF EXIST rawArp.txt del /F rawArp.txt
call plink -ssh %user%@%routerIP% -pw %pass%  < sharp.txt > rawArp.txt

rem Extract router name
for /f "tokens=* delims=" %%s in (rawArp.txt) do (
	set "str="
	set "str=%%s"
	if "!str:~0,1!" == "D" (
		for /f "tokens=3 delims= " %%A in ("!str!") do (
			set "routerName=%%A"
			)
		)
	if "!str:~0,1!" == "I" (
		for /f "tokens=4,6 delims= " %%A in ("!str!") do (
			set "mac=%%A"
			set "vlan=%%B"
			set "vlan=!vlan:Vlan=!"
			)
		)
)
rem echo Router Name: !routerName!
rem echo MAC: !mac!
rem echo VLAN: !vlan!
rem echo.

rem Build shmacaddadd.txt
IF EXIST shmacaddadd.txt del /F shmacaddadd.txt
echo sh mac add add !mac! >> shmacaddadd.txt

rem Make call to router
IF EXIST rawMac.txt del /F rawMac.txt
call plink -ssh %user%@%routerIP% -pw %pass%  < shmacaddadd.txt > rawMac.txt

rem Extract downlink port
for /f "tokens=* delims=" %%s in (rawMac.txt) do (
	set "str="
	set "str=%%s"
	if "!str:~0,1!" == "*" (
		for /f "tokens=7 delims= " %%A in ("!str!") do (
			set "routerPort=%%A"
		)
	)
)
rem echo Router Port: !routerPort!

rem Build shint.txt
IF EXIST shint.txt del /F shint.txt
echo sh int !routerPort! >> shint.txt

rem Make call to router
IF EXIST rawInt.txt del /F rawInt.txt
call plink -ssh %user%@%routerIP% -pw %pass%  < shint.txt > rawInt.txt


rem Remove leading space
if exist rawInt1.txt del /f rawInt1.txt
for /f "tokens=* delims=" %%s in (rawInt.txt) do (
	set "str="
	set "str=%%s"
	for /f "tokens=* delims= " %%t in ("!str!") do (
		set "str=%%t"
		echo !str!>>rawInt1.txt
	)
)

rem Extract switch name
for /f "tokens=1,4 delims= " %%A in (rawInt1.txt) do (
	set "str="
	set "str=%%A"
	if "!str!" == "Description:" (
		set "switchName=%%B"
	)
)
rem echo Switch Name: !switchName!

if exist pingScanResults.txt del /f pingScanResults.txt
ping !switchName! -n 1 -w 100 | find /i "Reply">>pingScanResults.txt

:: Extracting IP address from pingScanResults.txt file
for /f "tokens=3 delims= " %%a in (pingScanResults.txt) do (
	set "switchIP=%%a"
rem echo !switchIP!
	:: remove trailing :
	set "switchIP=!switchIP:~0,-1!"
	)
rem echo.
rem echo !switchName! IP is !switchIP!

rem Build targetSwitch file
if exist targetSwitch.txt del /f targetSwitch.txt
echo !switchName! !switchIP! ssh >> targetSwitch.txt
echo.
echo Starting Meili to find port on !switchName!
echo.
rmdir /s /q %cd%\log\
call H:\meili.exe -u %user% -p %pass% -d targetSwitch.txt -i shmacaddadd.txt

:: Treat the rawMacList for any NUL characters, which are show stoppers
IF EXIST rawSwint.txt del /F rawSwint.txt
if exist %cd%\log\!switchName!.txt findstr ^[0-9] %cd%\log\!switchName!.txt > rawSwint.txt

rem Remove leading space
if exist rawSwint1.txt del /f rawSwint1.txt
for /f "tokens=* delims=" %%s in (rawSwint.txt) do (
	set "str="
	set "str=%%s"
	for /f "tokens=* delims= " %%t in ("!str!") do (
		set "str=%%t"
		echo !str!>>rawSwint1.txt
	)
)

rem Extract switch port
for /f "tokens=2,5 delims= " %%A in (rawSwint1.txt) do (
	set "str="
	set "str=%%A"
	if "!str!" == "!mac!" (
		set "switchPort=%%B"
	)
)
echo.
echo.
echo *****************************************
echo.
echo IP Address !ip_addr! is on
echo.
echo Switch: !switchName!
echo.
echo Switch Port: !switchPort!
echo.
echo *****************************************
echo.
echo.
echo.
set /p cleanup= Delete discovery files? (y/n)
set "answer="
if "%cleanup%"=="y" set answer=1
if "%cleanup%"=="Y" set answer=1
if %answer% EQU 1 del /f *.txt
echo.
if %answer% EQU 1 echo Cleanup complete.
echo.
echo ************************************************************





































	
	
	

