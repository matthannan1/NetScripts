@echo off
setlocal enabledelayedexpansion

cls
echo ************************************************************
echo.
echo Welcome to Host Discovery
echo.
set /P switch=Access switch to investigate? 
set /P comm= Enter 1 for ssh or 2 for telnet. 
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

:: Build targetDevice.txt file
echo ************************************************************
echo.
echo Building target device discovery file
if exist targetDevice.txt del /f targetDevice.txt
if "%comm%" == "1" echo %switch% %switchIP% ssh >> targetDevice.txt
if "%comm%" == "2" goto :oldMac
echo.

echo ************************************************************
echo.
echo Starting Meili to collect MAC addresses
echo.
rmdir /s /q %cd%\log\
call meili.exe -u %user% -p %pass% -d targetDevice.txt -i shmacLI.cmd
echo.
echo Port Discovery complete.
echo.
echo ************************************************************
echo.
echo Cleaning MAC Address List.
echo.
goto :skipOldMac

:oldMac

:: Build command list for plink
if exist plinkMac.cmd del /f plinkMac.cmd
if exist %cd%\log\%switch%.txt del /f %cd%\log\%switch%.txt
echo %user%>>plinkMac.cmd
echo %pass%>>plinkMac.cmd
echo sh cam dynamic>>plinkMac.cmd
echo exit>>plinkMac.cmd
:: this is not working on GA DEV switches
plink -telnet %switch% < plinkMac.cmd > %cd%\log\%switch%.txt

:skipOldMac

:: Treat the rawMacList for any NUL characters, which are show stoppers
IF EXIST rawMacList1.txt del /F rawMacList1.txt
if exist %cd%\log\%switch%.txt findstr ^[0-9] %cd%\log\%switch%.txt > rawMacList1.txt

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

:: Gather subnet info
echo ************************************************************
echo.
echo Starting Meili to collect subnet info
echo.
rmdir /s /q %cd%\log\
call meili.exe -u %user% -p %pass% -d targetDevice.txt -i shvlanLI.cmd
echo.
echo Subnet Discovery complete.
echo.
echo ************************************************************
echo.

:: Treat the rawMacList for any NUL characters, which are show stoppers
IF EXIST rawVlanList.txt del /F rawVlanList.txt
if exist %cd%\log\%switch%.txt findstr ^[0-9] %cd%\log\%switch%.txt > rawVlanList.txt

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

:: Extract subnet info. This only works if the vlan name is the subnet (ex: "10.1.200.0/22")
IF EXIST vlanCleaned1.txt del /F vlanCleaned1.txt
for /f "tokens=2 delims= " %%s in (vlanCleaned.txt) do (
	set "subnet="
	set "subnet=%%s"
	set "subnet=!subnet:~0,-5!"
	if "!subnet:~0,1!"=="1" echo.!subnet!>>vlanCleaned1.txt
	if "!subnet:~0,1!"=="2" echo.!subnet!>>vlanCleaned1.txt
	if "!subnet:~0,1!"=="3" echo.!subnet!>>vlanCleaned1.txt
	if "!subnet:~0,1!"=="4" echo.!subnet!>>vlanCleaned1.txt
	if "!subnet:~0,1!"=="5" echo.!subnet!>>vlanCleaned1.txt
	if "!subnet:~0,1!"=="6" echo.!subnet!>>vlanCleaned1.txt
	if "!subnet:~0,1!"=="7" echo.!subnet!>>vlanCleaned1.txt
	if "!subnet:~0,1!"=="8" echo.!subnet!>>vlanCleaned1.txt
	if "!subnet:~0,1!"=="9" echo.!subnet!>>vlanCleaned1.txt
	)
echo Created vlanCleaned1 file.

:: The short ping
IF EXIST cleanedPingScanResults.txt del /F cleanedPingScanResults.txt
for /f "tokens=* delims=" %%s in (vlanCleaned1.txt) do (
	set "subnet="
	set "subnet=%%s"
	echo Pinging broadcast address of subnet !subnet!.0.
	call pingNet.bat !subnet!
	)

echo ************************************************************
echo.
echo Router Name Discovery.
echo.
echo Router interface IP is %routerIP%.
echo.
echo We will log into this router twice.
echo The first time sets the ssh key, should it need setting.
echo The second time gathers the host name.
:: Plink for key
start plink -ssh %routerIP% -l %user% -pw %pass% > testRouterName.txt
echo.
echo Ready to continue?
pause
:: Find router name from the targetDevice file
if exist rawRouterName.txt del /f rawRouterName.txt
plink -ssh %user%@%routerIP% -pw %pass% < shmodLI.cmd > rawRouterName.txt

:: Carve off everything but router name
set "mod=sh mod"
set "routerName="
for /f "tokens=* delims=" %%s in (rawRouterName.txt) do (
	set "str="
	set "str=%%s"
	set "str1=!str:~-6!"
	if "!str1!"=="!mod!" set "routerName=!str:~0,-7!"
)
echo Router Name is !routerName!
echo.

echo ************************************************************
echo.
echo Host ARP Discovery.
echo.

:: This is a gigantic loop
:: Creating ARP List
IF EXIST arpList*.txt del /F arpList*.txt
IF EXIST rawIPARPList*.txt del /F rawIPARPList*.txt
set "str="
set "str=sh ip arp | i"
for /L %%G in (1,1,10) do (
	set "count=%%G"
	for /f "tokens=2,4 delims=," %%A in (macCleaned-PO.txt) do (
		if "%%A" EQU "Gi!count!" echo !str! %%B>>arpList!count!.txt
	)
	echo exit>>arpList!count!.txt
	echo Created arpList!count! file.
	set "inFile=arpList!count!.txt"
	set "outFile=rawIPARPList!count!.txt"
 	plink -ssh %user%@%routerName% -pw %pass% < !inFile! > !outFile!
	echo !outFile! created.
	echo.
)

:: Merge the multiple rawIPARPList files
if exist rawARPList.txt del /f rawARPList.txt
for %%f in (rawIPARPList*.txt) do type "%%f">>rawARPList.txt
echo Merged all the arp files into rawARPList.txt.
echo.

:: Clean log file
if exist rawARPList1.txt del /F rawARPList1.txt
if exist rawARPList.txt findstr ^[0-9] rawARPList.txt > rawARPList1.txt
:: If raw list line starts with Internet, send it to cleaned list
IF EXIST arpCleaned.txt del /F arpCleaned.txt
for /f "tokens=* delims=" %%s in (rawARPList1.txt) do (
	set "str="
	set "str=%%s"
	if "!str:~0,1!"=="1" echo.%%s>>arpCleaned.txt
	if "!str:~0,1!"=="2" echo.%%s>>arpCleaned.txt
	if "!str:~0,1!"=="3" echo.%%s>>arpCleaned.txt
	if "!str:~0,1!"=="4" echo.%%s>>arpCleaned.txt
	if "!str:~0,1!"=="5" echo.%%s>>arpCleaned.txt
	if "!str:~0,1!"=="6" echo.%%s>>arpCleaned.txt
	if "!str:~0,1!"=="7" echo.%%s>>arpCleaned.txt
	if "!str:~0,1!"=="8" echo.%%s>>arpCleaned.txt
	if "!str:~0,1!"=="9" echo.%%s>>arpCleaned.txt
	if "!str:~0,1!"=="I" echo.%%s>>arpCleaned.txt
	)
echo Created arpCleaned file.
echo.

:: Pull out the IP addresses and MAC addresses on ports only
:: Depending on the router, the tokens may need to be adjusted.	
set "str="
IF EXIST readyIPList.txt del /F readyIPList.txt
for /f "tokens=2,4 delims= " %%A in (arpCleaned.txt) do (
	set "str="
rem	set "str=%%C"
	echo %%B,%%A>>readyIPList.txt
)	
echo Cleaned up list.
echo Created readyIPList file.
echo.

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
echo Created macIP.txt.
echo.

echo ************************************************************
echo.
echo Welcome to DNS Discovery.
echo.
echo Building Hostname List (dnsList.txt)
echo This might take a little while...

:: Build list of IP addresses for ping -a
IF EXIST dnsList.txt del /F dnsList.txt
for /f "tokens=2 delims=," %%A in (readyIPList.txt) do (
	set "str="
	set "str=%%A"
	ping -a -n 1 !str! >> dnsList.txt 2>&1
	)
echo Created dnsList file.
echo Cleaning dnsList File.

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
echo Cleaning complete.
echo Created readyDNSList file
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
echo Created final3.txt.
echo.

:: Final report generation
echo Creating csv file.
if exist !switch!.csv del /f !switch!.csv
echo Switch,VLAN,Slot,Port,MAC Address,IP Address,Hostname>>!switch!.csv
for /f "tokens=1-7 delims=," %%A in (final3.txt) do (
	echo !switch!,%%A,%%B,%%C,%%D,%%E,%%F,%%G>>!switch!.csv
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

:comment1




