@echo off
setlocal enabledelayedexpansion

set "switch=%1"
set "pass=%2"
set "user=%USERNAME%"



:: Device discovery
echo Building device discovery list
if exist targetDevice.lst del /f targetDevice.lst
echo %switch%   !subnet!   telnet >> targetDevice.lst
echo.
echo ************************************************************
echo.
echo Starting Meili to collect MAC addresses
echo.
rmdir /s /q %cd%\log\
call meili.exe -u %user% -p %pass% -d targetDevice.lst -i shmacLO.cmd
echo.
echo Port Discovery complete.
echo.
echo ************************************************************
echo.
echo Cleaning MAC Address List.
echo.

:: Treat the rawMacList for any NUL characters, which are show stoppers
IF EXIST rawMacList1.txt del /F rawMacList1.txt
if exist %cd%\log\%1.txt findstr ^[0-9] %cd%\log\%1.txt > rawMacList1.txt

:: Treat for CRCRLF
IF EXIST rawMacList2.txt del /F rawMacList2.txt
call crlf2lf.bat
echo Carriage Returns fixed
echo.

:: Treat for LF
IF EXIST rawMacList3.txt del /F rawMacList3.txt
more rawMacList2.txt >rawMacList3.txt
echo Line Feeds fixed
echo.

:: Remove leading ::
IF EXIST rawMacList4.txt del /F rawMacList4.txt
for /f "tokens=* delims=" %%a in (rawMacList3.txt) do (
	set "str="
	set "str=%%a"
	set "str1=!str:::=!"
	echo !str1!>>rawMacList4.txt
	)
echo Created rawMacList4 file.
echo.

:: Remove leading * and strip down to "vlan,mac,mod/port"
IF EXIST rawMacList5.txt del /F rawMacList5.txt
for /f "tokens=1,2,3,4,5,6,7 delims= " %%A in (rawMacList4.txt) do (
	set "str="
	set "str=%%A"
	if "!str!" == "*" echo %%B,%%C,%%G>>rawMacList5.txt
	if NOT "!str!" == "*" echo %%A,%%B,%%F>>rawMacList5.txt
	)
echo Created rawMacList5 file.
echo.

:: If raw list line starts with a digit, send it to cleaned list
IF EXIST macCleaned.txt del /F macCleaned.txt
for /f "tokens=* delims=" %%s in (rawMacList5.txt) do (
	set "str="
	set "str=%%s"
	set "str=!str:~0,1!"
	if "!str!"=="1" echo.%%s>>macCleaned.txt
	if "!str!"=="2" echo.%%s>>macCleaned.txt
	if "!str!"=="3" echo.%%s>>macCleaned.txt
	if "!str!"=="4" echo.%%s>>macCleaned.txt
	if "!str!"=="5" echo.%%s>>macCleaned.txt
	if "!str!"=="6" echo.%%s>>macCleaned.txt
	if "!str!"=="7" echo.%%s>>macCleaned.txt
	if "!str!"=="8" echo.%%s>>macCleaned.txt
	if "!str!"=="9" echo.%%s>>macCleaned.txt
	)
echo Created macCleaned file.
echo.

:: Split mod/port notation into mod,port  
set "str="
IF EXIST macCleaned-Split.txt del /F macCleaned-Split.txt
for /f "tokens=1,2,3 delims=," %%A in (macCleaned.txt) do (
	set "vlan=%%A"
	set "mac=%%B"
	set "interface=%%C"
	:: Convert / into ,
	set "str=!interface:/=,!"
	:: Remove ,0
	set "str1=!str:,0=!"
	echo.!vlan!,!str1!,!mac!>>macCleaned-Split.txt
	)
echo Split mods and ports.
echo Created macCleaned-Split file.

:: Remove Port Channel entries
IF EXIST macCleaned-PO.txt del /F macCleaned-PO.txt
set /a i = 0
echo Pre-looped: !i!
for /f "tokens=1,2,3,4 delims=," %%A in (macCleaned-Split.txt) do (
	set "interface=%%B"
	if NOT "!interface:~0,1!" == "P" (
		echo %%A,%%B,%%C,%%D>>macCleaned-PO.txt
		set /a i=i+1
	)
)
echo Removed Port Channels.
echo Created macCleaned-PO file.
echo !i! MAC Addresses found.


echo.
echo ************************************************************
echo.
echo Welcome to IP ARP Discovery
echo.
echo Building ARP Discovery List

:: Build list of MAC addresses for searchArp.bat
set "str="
IF EXIST arpList.txt del /F arpList.txt
for /f "tokens=4 delims=," %%M in (macCleaned4.txt) do (
	set "str=sh ip arp | i "
	echo !str! %%M>>arpList.txt
)

echo Created ARP List file.
echo.

:: Gather subnet info
echo ************************************************************
echo.
echo Starting Meili to collect subnet info
echo.
rmdir /s /q %cd%\log\
call meili.exe -u %user% -p %pass% -d targetDevice.lst -i shvlanLO.cmd
echo.
echo Subnet Discovery complete.
echo.
echo ************************************************************
echo.

:: Treat the rawMacList for any NUL characters, which are show stoppers
IF EXIST rawVlanList.txt del /F rawVlanList.txt
if exist %cd%\log\%1.txt findstr ^[0-9] %cd%\log\%1.txt > rawVlanList.txt

:: If line starts with a digit, send it to cleaned list
IF EXIST vlanCleaned.txt del /F vlanCleaned.txt
for /f "tokens=* delims=" %%s in (rawVlanList.txt) do (
	set "str="
	set "str=!str!%%s"
	set "str=!str:~0,1!"
	if "!str!"=="1" echo.%%s>>vlanCleaned.txt
	if "!str!"=="2" echo.%%s>>vlanCleaned.txt
	if "!str!"=="3" echo.%%s>>vlanCleaned.txt
	if "!str!"=="4" echo.%%s>>vlanCleaned.txt
	if "!str!"=="5" echo.%%s>>vlanCleaned.txt
	if "!str!"=="6" echo.%%s>>vlanCleaned.txt
	if "!str!"=="7" echo.%%s>>vlanCleaned.txt
	if "!str!"=="8" echo.%%s>>vlanCleaned.txt
	if "!str!"=="9" echo.%%s>>vlanCleaned.txt
	)
echo Created vlanCleaned file.
echo.

:: Extract subnet info
IF EXIST vlanCleaned1.txt del /F vlanCleaned1.txt
for /f "tokens=2 delims= " %%s in (vlanCleaned.txt) do (
	set "str="
	set "str=!str!%%s"
	set "str=!str:~0,1!"
	if "!str!"=="1" echo.%%s>>vlanCleaned1.txt
	if "!str!"=="2" echo.%%s>>vlanCleaned1.txt
	if "!str!"=="3" echo.%%s>>vlanCleaned1.txt
	if "!str!"=="4" echo.%%s>>vlanCleaned1.txt
	if "!str!"=="5" echo.%%s>>vlanCleaned1.txt
	if "!str!"=="6" echo.%%s>>vlanCleaned1.txt
	if "!str!"=="7" echo.%%s>>vlanCleaned1.txt
	if "!str!"=="8" echo.%%s>>vlanCleaned1.txt
	if "!str!"=="9" echo.%%s>>vlanCleaned1.txt
	)
echo Created vlanCleaned1 file.
echo.

:: Further refine of subnet info
IF EXIST vlanCleaned2.txt del /F vlanCleaned2.txt
for /f "tokens=1 delims=/" %%s in (vlanCleaned1.txt) do (
	set "str="
	set "str=%%s"
	echo !str!>>vlanCleaned2.txt
	)
echo Created vlanCleaned2 file.
echo.

:: Final extract of subnet info
IF EXIST vlanCleaned3.txt del /F vlanCleaned3.txt
for /f "tokens=* delims=" %%s in (vlanCleaned2.txt) do (
	set "str=%%s"
	set "str=!str:~0,-2!"
	echo !str!>>vlanCleaned3.txt
	)
echo Created vlanCleaned3 file.
echo.

:: The short ping
IF EXIST cleanedPingScanResults.txt del /F cleanedPingScanResults.txt
for /f "tokens=* delims=" %%s in (vlanCleaned3.txt) do (
	set "subnet=%%s"
	echo Pinging broadcast address of subnet !subnet!.0.
	call pingNet.bat !subnet!
	)

	
echo ************************************************************
echo.
echo Collecting IP ARP details.
echo.

:: Build routerDevice.lst file
IF EXIST routerDevice.lst del /F routerDevice.lst
IF EXIST routerName.txt del /F routerName.txt
echo What router are we hanging off of?
echo.
set "routerIP=!subnet!.250"
echo !routerIP!
echo.

:: Looking for ports labeled with UPLINK
echo ************************************************************
echo.
echo Starting Meili to collect router info
echo.
rmdir /s /q %cd%\log\
call meili.exe -u %user% -p %pass% -d targetDevice.lst -i routerLookupLO.cmd
echo.

:: Extract Router Name
if exist routerName.txt del /F routerName.txt
if exist %cd%\log\%1.txt findstr ^[0-9] %cd%\log\%1.txt > routerName.txt
if exist routerName1.txt del /F routerName1.txt
for /f "tokens=* delims=" %%r in (routerName.txt) do (
	set "str=%%r"
	set "str1=!str:~0,1!"
	if "!str1!"==" " echo.%%r>>routerName1.txt
)
echo routerName1 created.
echo.

:: Remove leading spaces
if exist routerName2.txt del /F routerName2.txt
for /f "tokens=* delims= " %%a in (routerName1.txt) do (
	set "str="
	set "str=%%a"
	echo !str!>>routerName2.txt
	)
echo Created routerName2 file.
echo.

:: Isolate router name and create routerDevice.lst
if exist routerDevice.lst del /f routerDevice.lst
set /p var=<routerName2.txt
rem echo %var%
set "router="
for /f "tokens=4 delims= " %%r in ("%var%") do (
    set "router=%%r"
 	echo !router!   !routerIP!   ssh>>routerDevice.lst
)
echo Created routerDevice.lst
echo.
echo Router is: !router!
echo.

echo About to start involving routers.
echo.
pause

:: Check router name and take action if NOBOFCDV02A
if "!router!" == "NOBOFCDV02A" goto :plink

:: Connect to .250 router and gather ip ARP info
echo.
echo ************************************************************
echo.
echo Starting Meili to collect IP addresses via arpList.txt
echo.
rmdir /s /q %cd%\log\
call meili.exe -u %user% -p %pass% -d routerDevice.lst -i arpList.txt
echo.
echo IP ARP Discovery complete.
echo.
goto :resume


:plink
echo.
echo !router! is known to give a rough time with the meili script,
echo so we are going to kick it old school with plink.
echo.
echo Z>>arpList.txt
echo Z>>arpList.txt
echo Z>>arpList.txt
echo Z>>arpList.txt
echo Z>>arpList.txt
echo Z>>arpList.txt
echo exit>>arpList.txt
echo First, we need to make sure the ssh key is set, so we need to log
echo into !router!, accept the key if needed, and exit back out.
echo.
echo Press Enter to do this now.
pause
start plink -ssh %router% -l %user% -pw %pass%
echo.
echo Welcome back. Now we will use plink to connect to !router! and
echo run the IP ARP discovery. Ready?
echo.

if exist rawIPARPList.txt del /f rawIPARPList.txt
plink -ssh %user%@!router! -pw %pass% < arpList.txt > rawIPARPList.txt
echo.
echo Plink complete. Old school FTW!
echo rawIPARPList created.
echo.
goto :resume

:resume
:: Clean null characters from log file
if exist arpList1.txt del /F arpList1.txt
if exist rawIPARPList.txt findstr ^[0-9] rawIPARPList.txt > arpList1.txt
if exist %cd%\log\!router!.txt findstr ^[0-9] %cd%\log\!router!.txt > arpList1.txt

:: Remove sh from beginning of each line
IF EXIST arpCleaned.txt del /F arpCleaned.txt
for /f "tokens=* delims=" %%s in (arpList1.txt) do (
	set "str="
	set "str=%%s"
	if "!str:~0,2!"=="sh" set "str=!str:sh =!"
	echo.!str!>>arpCleaned.txt
	)
echo Created arpCleaned file.
echo.

:: If line starts #, send it on (fix file names here) 
IF EXIST arpCleaned1.txt del /F arpCleaned1.txt
for /f "tokens=* delims=" %%s in (arpCleaned.txt) do (
	set "str="
	set "str=!str!%%s"
	set "str=!str:~0,1!"
	if "!str!"=="1" >> arpCleaned1.txt echo.%%s
	if "!str!"=="2" >> arpCleaned1.txt echo.%%s
	if "!str!"=="3" >> arpCleaned1.txt echo.%%s
	if "!str!"=="4" >> arpCleaned1.txt echo.%%s
	if "!str!"=="5" >> arpCleaned1.txt echo.%%s
	if "!str!"=="6" >> arpCleaned1.txt echo.%%s
	if "!str!"=="7" >> arpCleaned1.txt echo.%%s
	if "!str!"=="8" >> arpCleaned1.txt echo.%%s
	if "!str!"=="9" >> arpCleaned1.txt echo.%%s
	)
echo arpCleaned1 created.
echo.

:: Remove spaces	
set "str="
IF EXIST arpCleaned2.txt del /F arpCleaned2.txt
for /f "tokens=* delims=" %%A in (arpCleaned1.txt) do (
	set "str=%%A"
	set "str=!str:          =,!"
	set "str=!str:         =,!"
	set "str=!str:        =,!"
	set "str=!str:       =,!"
	set "str=!str:      =,!"
	set "str=!str:     =,!"
	set "str=!str:    =,!"
	set "str=!str:   =,!"
	set "str=!str:  =,!"
	set "str=!str: =,!"
	echo !str!>>arpCleaned2.txt
	)	
echo Spaces removed and replaced with commas.
echo arpCleaned2 created.
echo.

:: Pull out the IP addresses and MAC addresses on ports only	
set "str="
IF EXIST readyIPList.txt del /F readyIPList.txt
for /f "tokens=1,3 delims=," %%A in (arpCleaned2.txt) do (
rem	set "str="
rem	set "str=%%C"
	echo %%B,%%A>>readyIPList.txt
)	
echo Cleaned up list.
echo readyIPList created.
echo.

:: Merge readyIPList.txt with macCleaned3
echo Adding IP addresses to MAC report.
if exist macIP.txt del /f macIP.txt
set "str=No IP found"
for /f "tokens=1-4 delims=," %%A in (macCleaned4.txt) do (
	set "found="
	for /f "tokens=1,2 delims=," %%H in (readyIPList.txt) do (
		if "%%D"=="%%H" (
			echo %%A,%%B,%%C,%%D,%%I>>macIP.txt
			set "found=1"
		) 
	)	
	if not defined found echo %%A,%%B,%%C,%%D,!str!>>macIP.txt
)
echo macIP created.
echo.

echo ************************************************************
echo.
echo Welcome to DNS Discovery.
echo.
echo Building Hostname List (dnsList.txt)
echo This might take a little while...

:: Build list of IP addresses for tracert
IF EXIST dnsList.txt del /F dnsList.txt
for /f "tokens=2 delims=," %%A in (readyIPList.txt) do (
	set "str="
	set "str=%%A"
	tracert !str! >> dnsList.txt 2>&1
	)
echo Created dnsList file.
echo dnsList created.

:: Parse name and IP address
set "str="
IF EXIST readyDNSList.txt del /F readyDNSList.txt
for /f "tokens=1,4,5 delims= " %%A in (dnsList.txt) do (
	set "str=%%A"
	set "name=%%B"
	set "ip=%%C"
	set "ip=!ip:~1,-1!"
if "!str!"=="Tracing" echo !ip!,!name!>>readyDNSList.txt  
)
echo Cleaning complete.
echo readyDNSList created.
echo.
echo DNS Discovery Complete
echo.

echo ************************************************************
echo.
echo Final report creation.
echo.

:: Merge readyDNSList.txt with final2.txt
echo Adding DNS hostnames to final report.
if exist final3.txt del /f final3.txt
set "str=No DNS record found"
for /f "tokens=1-5 delims=," %%A in (macIP.txt) do (
	set "found="
	for /f "tokens=1,2 delims=," %%H in (readyDNSList.txt) do (
		if "%%E"=="%%H" (
			echo %%A,%%B,%%C,%%D,%%E,%%I>>final3.txt
			set "found=1"
		) 
	)	
	if not defined found echo %%A,%%B,%%C,%%D,%%E,!str!>>final3.txt
)
echo final3 created.
echo.

:: Final report generation
echo Creating csv file.
if exist !switch!.csv del /f !switch!.csv
echo Switch,VLAN,Slot,Port,MAC Address,IP Address,Hostname>>!switch!.csv
for /f "tokens=1-7 delims=," %%A in (final3.txt) do (
	echo !switch!,%%A,%%B,%%C,%%D,%%E,%%F,%%G>>!switch!.csv
)
echo !switch!.csv created.
echo.
echo Process complete.
echo.
echo ************************************************************
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

:comment1
