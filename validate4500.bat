@echo off
setlocal enabledelayedexpansion


rem  validate4500.bat by Matt Hannan on 20 Sep 2017
rem  Depends on meili.exe, crlf2lf.bat, and pingNet.bat 
rem       to be two directories above here.
rem  That is, H:\meili.exe if this batch file is in 
rem       H:\Validate\4500\ directory.

cls
echo ************************************************************
echo.
echo Welcome to Host Discovery
echo.
set /P switch=Access switch to investigate? 
set /P pass=What is your password? 
set "user=%USERNAME%"
cls
echo.
echo Here we go!
echo.
echo ************************************************************
echo.
echo         Welcome to Switch Discovery
echo.
echo Pinging switch %switch% to discover IP address
if exist pingScanResults.txt del /f pingScanResults.txt
ping %switch% -n 1 -w 100 | find /i "Reply">>pingScanResults.txt

:: Extracting IP address from pingScanResults.txt file
for /f "tokens=3 delims= " %%a in (pingScanResults.txt) do (
	set "switchIP=%%a"
	echo !switchIP!
	:: remove trailing :
	set "switchIP=!switchIP:~0,-1!"
	)
echo.
echo %switch% IP is !switchIP!
set "routerIP=!switchIP:~0,-3!250"
echo Router IP is !routerIP!
echo.

:: Build targetSwitch.txt file
echo ************************************************************
echo.
echo Building target switch device discovery file
echo.
if exist targetSwitch.txt del /f targetSwitch.txt
echo %switch% %switchIP% ssh >> targetSwitch.txt
rem echo Created targetSwitch file
rem echo.
if exist shmac.txt del /f shmac.txt
echo sh mac address-table dynamic >> shmac.txt
rem echo Created shmac.txt file
echo ************************************************************
echo.
echo Starting Meili to collect MAC addresses from %switch%
echo.
rmdir /s /q %cd%\log\
call H:\meili.exe -u %user% -p %pass% -d targetSwitch.txt -i shmac.txt
rem echo.
echo Port Discovery complete.
echo.
echo ************************************************************
echo.
echo Cleaning MAC Address List.
echo.

:: Treat the rawMacList for any NUL characters, which are show stoppers
IF EXIST rawMacList1.txt del /F rawMacList1.txt
if exist %cd%\log\%switch%.txt findstr ^[0-9] %cd%\log\%switch%.txt > rawMacList1.txt

:: Treat for CRCRLF
IF EXIST rawMacList2.txt del /F rawMacList2.txt
call H:\crlf2lf.bat
rem echo Carriage Returns fixed

:: Treat for LF
IF EXIST rawMacList3.txt del /F rawMacList3.txt
more rawMacList2.txt >rawMacList3.txt
rem echo Line Feeds fixed
rem echo Created rawMacList3 file
rem echo.

:: Remove leading ::
IF EXIST rawMacList4.txt del /F rawMacList4.txt
for /f "tokens=* delims=" %%a in (rawMacList3.txt) do (
	set "str="
	set "str=%%a"
	set "str1=!str:::=!"
	echo !str1!>>rawMacList4.txt
	)
rem echo Created rawMacList4 file.
rem echo.

:: Remove leading * and strip down to "vlan,mac,mod/port"
IF EXIST rawMacList5.txt del /F rawMacList5.txt
for /f "tokens=1,2,3,4,5 delims= " %%A in (rawMacList4.txt) do (
	set "str="
	set "str=%%A"
	echo %%A,%%B,%%E>>rawMacList5.txt
	)
rem echo Created rawMacList5 file.
rem echo.

:: If raw list line starts with a digit, send it to cleaned list
IF EXIST macCleaned.txt del /F macCleaned.txt
for /f "tokens=* delims=" %%s in (rawMacList5.txt) do (
	set "str="
	set "str=%%s"
	if "!str:~0,1!" LEQ "9" echo.%%s>>macCleaned.txt
	)
rem echo Created macCleaned file.
rem echo.

:: Bulk remove TenGigabitEthernet entries
:: Remove GigabitEthernet from string
:: 4500 specific
IF EXIST macCleaned1.txt del /F macCleaned1.txt
for /f "tokens=1,2,3 delims=," %%A in (macCleaned.txt) do (
	set "str="
	set "mod="
	set "mod=%%C"
	set "str=%%A"
	if NOT "!mod:~0,1!" == "T" (
		echo %%A,%%B,!mod:GigabitEthernet=!>>macCleaned1.txt
	)
)
rem echo Created macCleaned1 file.
rem echo.

:: Split mod/port notation into mod,port  
set "str="
IF EXIST macCleaned-Split.txt del /F macCleaned-Split.txt
for /f "tokens=1,2,3 delims=," %%A in (macCleaned1.txt) do (
	set "vlan=%%A"
	set "mac=%%B"
	set "interface=%%C"
	:: Convert / into ,
	set "str=!interface:/=,!"
	:: Remove ,0
	set "str1=!str:,0=!"
	echo.!vlan!,!str1!,!mac!>>macCleaned-Split.txt
	)
rem echo Split mods and ports.
rem echo Created macCleaned-Split file.
rem echo.

:: Remove Port Channel entries
IF EXIST macCleaned-PO.txt del /F macCleaned-PO.txt
set /a i = 0
rem echo Pre-looped: !i!
for /f "tokens=1,2,3,4 delims=," %%A in (macCleaned-Split.txt) do (
	set "interface=%%B"
	if NOT "!interface:~0,1!" == "P" (
		echo %%A,%%B,%%C,%%D>>macCleaned-PO.txt
		set /a i=i+1
	)
)
rem echo Removed Port Channels.
rem echo Created macCleaned-PO file.
echo !i! MAC Addresses found.
echo.

:: Gather subnet info
echo ************************************************************
echo.
echo Starting Meili to collect subnet info from %switch%
echo.
rmdir /s /q %cd%\log\
if exist shvlan.txt del /f shvlan.txt
echo sh vlan brief >> shvlan.txt
rem echo Created shvlan.txt file
rem echo.
call H:\meili.exe -u %user% -p %pass% -d targetSwitch.txt -i shvlan.txt 
rem echo.
echo Subnet Discovery complete.
echo.
echo ************************************************************
echo.
echo Starting IP Address Discovery
echo.
:: Treat the rawMacList for any NUL characters, which are show stoppers
IF EXIST rawVlanList.txt del /F rawVlanList.txt
if exist %cd%\log\%switch%.txt findstr ^[0-9] %cd%\log\%switch%.txt > rawVlanList.txt

:: If line starts with a digit, send it to cleaned list
IF EXIST vlanCleaned.txt del /F vlanCleaned.txt
for /f "tokens=* delims=" %%s in (rawVlanList.txt) do (
	set "str="
	set "str=%%s"
	if "!str:~0,1!" LEQ "9" echo.%%s>>vlanCleaned.txt
	)
rem echo Created vlanCleaned file.
rem echo.

:: Find subnet info. 
IF EXIST vlanCleaned1.txt del /F vlanCleaned1.txt
rem Pulls out vlan decscription
for /f "tokens=2 delims= " %%s in (vlanCleaned.txt) do (
	set "subnet="
	set "subnet=%%s"
rem Wile E. Coyote - Super Genius
rem Checks that first character is a digit
	if "!subnet:~0,1!" LEQ "9" (
		for /f "delims=/" %%t in ("!subnet!") do (
			set "sub="
			set "sub=%%t"
			set "sub=!sub:~0,-2!"
rem Sends just the first three octets to the file
			for /f "tokens=1,2,3 delims=." %%A in ("!sub!") do (
				echo %%A.%%B.%%C>>vlanCleaned1.txt
			)	
		)	
	)
)	
rem echo Created vlanCleaned1 file.	
rem echo.

:: The short ping
IF EXIST cleanedPingScanResults.txt del /F cleanedPingScanResults.txt
for /f "tokens=* delims=" %%s in (vlanCleaned1.txt) do (
	set "subnet="
	set "subnet=%%s"
	echo Pinging broadcast address of subnet !subnet!.0.
	call H:\pingNet.bat !subnet! 
	)
echo.
echo ************************************************************
echo.
echo Router Name Discovery.
echo.
rem echo Router interface IP is %routerIP%.
rem echo.
echo Starting Meili to collect router hostname from %switch%
echo.
set "routerName="
rmdir /s /q %cd%\log\
if exist shuplink.txt del /f shuplink.txt
echo sh conf ^| i UPLINK >> shuplink.txt
rem echo Created shuplink.txt file
rem echo.
call H:\meili.exe -u %user% -p %pass% -d targetSwitch.txt -i shuplink.txt 
echo.

:: Find router name from the targetSwitch file
if exist rawRouterName.txt del /f rawRouterName.txt
if exist %cd%\log\%switch%.txt findstr ^[0-9] %cd%\log\%switch%.txt > rawRouterName.txt
rem echo Created rawRouterName file.
rem echo.

:: Remove leading space
if exist rawRouterName1.txt del /f rawRouterName1.txt
for /f "tokens=* delims=" %%s in (rawRouterName.txt) do (
	set "str="
	set "str=%%s"
	for /f "tokens=* delims= " %%t in ("!str!") do (
		set "str=%%t"
		echo !str!>>rawRouterName1.txt
	)
)
rem echo Created rawRouterName1 file.
rem echo.

:: Pull out Router name
if exist routerNames.txt del /f routerNames.txt
for /f "tokens=4 delims= " %%s in (rawRouterName1.txt) do (
	echo %%s>> routerNames.txt
)	
rem echo Created routerNames file.
rem echo.

:: Read just the first entry
set /p texte=< routerNames.txt
set "routerName=%texte%" 
echo Router Name is !routerName!
echo.

echo ************************************************************
echo.
echo Host ARP Discovery.
echo.

:: Creating ARP List
IF EXIST arpList*.txt del /F arpList*.txt
IF EXIST rawIPARPList*.txt del /F rawIPARPList*.txt
set "str="
set "str=sh ip arp | i"
for /f "tokens=4 delims=," %%A in (macCleaned-PO.txt) do (
	echo !str! %%A>>arpList.txt
)
rem echo Created arpList file.
rem echo.

if exist targetRouter.txt del /F targetRouter.txt
echo !routerName!   !routerip!    ssh >>targetRouter.txt
rem echo Created targetRouter file.
rem echo.
echo.
echo Starting Meili to collect IP addresses from !routerName!
echo.
rmdir /s /q %cd%\log\
call H:\meili.exe -u %user% -p %pass% -d targetRouter.txt -i arpList.txt 
echo.
:: Clean log file
if exist rawIPARPList.txt del /f rawIPARPList.txt
if exist %cd%\log\%routerName%.txt findstr ^[0-9] %cd%\log\%routerName%.txt > rawIPARPList.txt
rem echo Created rawIPARPList file.
rem echo.

:: If raw list line starts with Internet, send it to cleaned list
IF EXIST arpCleaned.txt del /F arpCleaned.txt
for /f "tokens=* delims=" %%s in (rawIPARPList.txt) do (
	set "str="
	set "str=%%s"
	if "!str:~0,1!" EQU "I" echo.%%s>>arpCleaned.txt
	)
rem echo Created arpCleaned file.
rem echo.


:: Pull out the IP addresses and MAC addresses on ports only
:: Depending on the router, the tokens may need to be adjusted.	
set "str="
IF EXIST readyIPList.txt del /F readyIPList.txt
for /f "tokens=2,4 delims= " %%A in (arpCleaned.txt) do (
	set "str="
rem	set "str=%%C"
	echo %%B,%%A>>readyIPList.txt
)	
rem echo Cleaned up list.
rem echo Created readyIPList file.
rem echo.

:: Merge readyIPList.txt with macCleaned3
echo Adding IP addresses to MAC report.
if exist macIP.txt del /f macIP.txt
set "str=No IP found"
for /f "tokens=1-4 delims=," %%A in (macCleaned-PO.txt) do (
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

echo ************************************************************
echo.
echo Welcome to DNS Discovery.
echo.
echo Building Hostname List (dnsList.txt)
echo This might take a little while...
echo.

:: Build list of IP addresses for ping -a
IF EXIST dnsList.txt del /F dnsList.txt
for /f "tokens=2 delims=," %%A in (readyIPList.txt) do (
	set "str="
	set "str=%%A"
	ping -a -n 1 !str! >> dnsList.txt 2>&1
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
rem echo Cleaning complete.
rem echo Created readyDNSList file
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
rem echo Created final3.txt.
rem echo.

:: Final report generation
rem echo Creating csv file.
:: Create validated subdirectory, if it doesn't already exist
if not exist %cd%\validated mkdir %cd%\validated
:: Create the final csv file in validated subdirectory
if exist validated\!switch!.csv del /f validated\!switch!.csv
echo Switch,VLAN,Slot,Port,MAC Address,IP Address,Hostname>>validated\!switch!.csv
for /f "tokens=1-7 delims=," %%A in (final3.txt) do (
	echo !switch!,%%A,%%B,%%C,%%D,%%E,%%F,%%G>>validated\!switch!.csv
)
echo Created !switch!.csv
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





