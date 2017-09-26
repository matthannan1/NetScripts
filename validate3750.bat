@echo off
setlocal enabledelayedexpansion

rem Created by Matt Hannan on 26 Sep 2017
rem  Depends on meili.exe, crlf2lf.bat, and pingNet.bat 
rem       to be in the same directory.
rem  This is specific to a Cisco 3750 switch.

cls
set "user=%USERNAME%"

echo ************************************************************
echo.
echo                Welcome to 3750 Host Discovery
echo.
set /P switch=Access switch to investigate? 
set /P pass=What is your password? 
cls

echo.
echo                          Here we go!
echo.
echo ************************************************************
echo.
echo                     Switch Port Discovery
echo.
echo Pinging switch %switch% to discover IP address
if exist pingScanResults.txt del /f pingScanResults.txt
ping %switch% -n 1 -w 100 | find /i "Reply">>pingScanResults.txt

:: Extracting IP address from pingScanResults.txt file
for /f "tokens=3 delims= " %%a in (pingScanResults.txt) do (
	set "switchIP=%%a"
	:: remove trailing :
	set "switchIP=!switchIP:~0,-1!"
	)
echo.
echo %switch% IP is !switchIP!
echo.

rem echo Building switch discovery list
if exist targetSwitch.txt del /f targetSwitch.txt
echo %switch%   !switchIP!   ssh >> targetSwitch.txt
rem echo Building sh mac command file
if exist shmac.txt del /f shmac.txt
echo sh mac address-table dynamic >> shmac.txt
echo.
echo ************************************************************
echo.
echo Starting Meili to collect MAC addresses from !switch!
echo.
rmdir /s /q "P:\Datacomm\MA Data Centers\Tools\log\"
call meili.exe -u %user% -p %pass% -d targetSwitch.txt -i shmac.txt
echo.
echo                   Mac Discovery complete.
echo.
echo ************************************************************
echo.
echo                  Cleaning MAC Address List
echo.

:: Treat the rawMacList for any NUL characters, which are show stoppers
IF EXIST rawMacList1.txt del /F rawMacList1.txt
if exist "P:\Datacomm\MA Data Centers\Tools\log\%switch%.txt" findstr ^[0-9] "P:\Datacomm\MA Data Centers\Tools\log\%switch%.txt" > rawMacList1.txt

:: Treat for CRCRLF
IF EXIST rawMacList2.txt del /F rawMacList2.txt
call crlf2lf.bat
rem echo Carriage Returns fixed
rem echo.

:: Treat for LF
IF EXIST rawMacList3.txt del /F rawMacList3.txt
more rawMacList2.txt >rawMacList3.txt
rem echo Line Feeds fixed
rem echo.

:: Remove leading ::
IF EXIST subMacCleaned.txt del /F subMacCleaned.txt
for /f "tokens=* delims=" %%a in (rawMacList3.txt) do (
	set "str="
	set "str=%%a"
	set "str1=!str:::=!"
	echo !str1!>>subMacCleaned.txt
	)
rem echo Created subMacCleaned file.
rem echo.

:: If raw list line starts with a digit, send it to cleaned list
IF EXIST macCleaned.txt del /F macCleaned.txt
for /f "tokens=* delims=" %%s in (subMacCleaned.txt) do (
	set "str="
	set "str=%%s"
	if "!str:~0,1!" LEQ "9" echo.%%s>>macCleaned.txt
	)
rem echo Created macCleaned file.
rem echo.

:: Remove spaces	
set "str="
IF EXIST macCleaned1.txt del /F macCleaned1.txt
for /f "tokens=* delims=" %%A in (macCleaned.txt) do (
	set "str=%%A"
	set "str=!str:     =,!"
	set "str=!str:    =,!"
	echo !str!>>macCleaned1.txt
	)	
rem echo Spaces removed and replaced with commas.
rem echo Created macCleaned1 file.
rem echo.

:: Remove "DYNAMIC" from cleaned file and output to converted file :26 to 37
set "str="
IF EXIST macCleaned2.txt del /f macCleaned2.txt
for /f "tokens=1,2,4 delims=," %%A in (macCleaned1.txt) do (
	echo %%A,%%B,%%C>>macCleaned2.txt
	)
rem echo Striped out "DYNAMIC".
rem echo Created macCleaned2 file.
rem echo.

:: Split mod/port notation into mod,port  
set "str="
IF EXIST macCleaned3.txt del /F macCleaned3.txt
for /f "tokens=1,2,3 delims=," %%A in (macCleaned2.txt) do (
	set "vlan=%%A"
	set "mac=%%B"
	set "interface=%%C"
	:: Convert / into ,
	set "str=!interface:/=,!"
	:: Remove ,0
	set "str1=!str:,0=!"
	echo.!vlan!,!str1!,!mac!>>macCleaned3.txt
	)
rem echo Split mods and ports.
rem echo Created macCleaned3 file.

:: Remove Port Channel entries
IF EXIST macCleaned4.txt del /F macCleaned4.txt
for /f "tokens=1,2,3,4,5 delims=," %%A in (macCleaned3.txt) do (
	set "interface=%%B"
if NOT "!interface:~0,1!" == "P" echo %%A,%%B,%%C,%%D,%%E>>macCleaned4.txt
)

:: Remove Gi#/1/# info
if exist macCleaned5.txt del /f macCleaned5.txt
for /f "tokens=1,2,3,4,5 delims=," %%A in (macCleaned4.txt) do (
	set "valid=1"
	set "interface=%%D"
	if !interface! EQU 1 set valid=0
	if !interface! EQU 2 set valid=0
	if !valid! EQU 1 echo %%A,%%B,%%C,%%D>>macCleaned5.txt
)
echo.
echo                 MAC address list cleaned
echo.
echo ************************************************************
echo.
echo                   Starting IP Discovery
echo.
echo Building ARP Discovery List
echo.

:: Build list of MAC addresses for searchArp.bat
set "str="
IF EXIST arpList.txt del /F arpList.txt
for /f "tokens=4 delims=," %%M in (macCleaned5.txt) do (
	set "str=sh ip arp | i"
	echo !str! %%M>>arpList.txt
)
rem echo.
rem echo Created ARP List file.
rem echo.

:: Connect to 3750 switch and gather ip ARP info
echo The 3750 handles its own ARP info
echo.
echo Starting Meili to collect IP addresses from !switch!
echo.
rmdir /s /q "P:\Datacomm\MA Data Centers\Tools\log\"
call meili.exe -u %user% -p %pass% -d targetSwitch.txt -i arpList.txt
echo.

:: Clean log file
if exist arpList1.txt del /F arpList1.txt
if exist "P:\Datacomm\MA Data Centers\Tools\log\!switch!.txt" findstr ^[0-9] "P:\Datacomm\MA Data Centers\Tools\log\!switch!.txt" > arpList1.txt
:: If raw list line starts with Internet, send it to cleaned list
IF EXIST arpCleaned.txt del /F arpCleaned.txt
for /f "tokens=* delims=" %%s in (arpList1.txt) do (
	set "str="
	set "str=%%s"
	set "str=!str:~0,1!"
	if "!str:~0,1!"=="I" echo.%%s>>arpCleaned.txt
	)
rem echo Created arpCleaned file.
rem echo.

:: Pull out the IP addresses and MAC addresses on ports only	
set "str="
IF EXIST readyIPList.txt del /F readyIPList.txt
for /f "tokens=2,4 delims= " %%A in (arpCleaned.txt) do (
	echo %%B,%%A>>readyIPList.txt
	)	
rem echo Cleaned up list.
rem echo Created readyIPList file.
rem echo.

:: Merge readyIPList.txt with macCleaned3
rem echo Adding IP addresses to MAC report.
if exist macIP.txt del /f macIP.txt
set "str=No IP found"
for /f "tokens=1-4 delims=," %%A in (macCleaned5.txt) do (
	set "found="
	for /f "tokens=1,2 delims=," %%H in (readyIPList.txt) do (
		if "%%D"=="%%H" (
			echo %%A,%%B,%%C,%%D,%%I>>macIP.txt
			set "found=1"
		) 
	)	
	if not defined found echo %%A,%%B,%%C,%%D,!str!>>macIP.txt
)
rem echo Created macIP.txt.
rem echo.
echo                  IP ARP discovery complete
echo.
echo ************************************************************
echo.
echo                   Starting DNS Discovery.
echo.
echo Building Hostname List (dnsList.txt)
echo This might take a little while...
echo.

:: Build list of IP addresses for ping -a
IF EXIST dnsList.txt del /F dnsList.txt
for /f "tokens=2 delims=," %%A in (readyIPList.txt) do (
	set "str="
	set "str=%%A"
	ping -n 1 -a !str! >> dnsList.txt 2>&1
	)
rem echo Created dnsList file.
rem echo Cleaning dnsList File.

:: Parse name and IP address
set "str="
IF EXIST readyDNSList.txt del /F readyDNSList.txt
for /f "tokens=1,2,3 delims= " %%A in (dnsList.txt) do (
	set "str=%%A"
	set "name=%%B"
	set "ip=%%C"
	set "ip=!ip:~1,-1!"
if "!str!"=="Pinging" echo !ip!,!name!>>readyDNSList.txt  
)
pause
rem echo Cleaning complete.
rem echo Created readyDNSList file
echo.
echo                DNS Discovery Complete
echo.
echo ************************************************************
echo.
echo                 Final report creation.
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
rem echo Created final3.txt.
rem echo.

:: Final report generation
rem echo Creating csv file.
:: Create validated subdirectory, if it doesn't already exist
if not exist "P:\Datacomm\MA Data Centers\Tools\validated" mkdir "P:\Datacomm\MA Data Centers\Tools\validated"
:: Create the final csv file in validated subdirectory
if exist validated\!switch!.csv del /f validated\!switch!.csv
echo Switch,VLAN,Slot,Port,MAC Address,IP Address,Hostname>>validated\!switch!.csv
for /f "tokens=1-7 delims=," %%A in (final3.txt) do (
	echo !switch!,%%A,%%B,%%C,%%D,%%E,%%F,%%G>>validated\!switch!.csv
)
echo Created !switch!.csv
echo.
echo                    Process complete.
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
echo.
pause>nul




