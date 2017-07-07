@echo off
setlocal enabledelayedexpansion
 
set "switch=%1"
set "pass=%2"
set "user=%USERNAME%"
 
echo ************************************************************
echo.
echo Welcome to Switch Port Discovery
echo.
echo Pinging switch %switch% to discovery IP address
if exist pingScanResults.txt del /f pingScanResults.txt
ping %switch% -n 1 -w 100 | find /i "Reply">>pingScanResults.txt
 
:: Extracting IP address from pingScanResults.txt file
for /f "tokens=3 delims= " %%a in (pingScanResults.txt) do (
        set S=%%a
        set S=!S:~0,-1!
        )
del /F pingScanResults.txt
echo.
echo %switch% is !S!
echo.
 
 
 
echo Building device discovery list
if exist targetDevice.lst del /f targetDevice.lst
echo %switch%   !S!   ssh >> targetDevice.lst
echo.
echo ************************************************************
echo.
echo Starting Meili to collect MAC addresses
echo.
rmdir /s /q %cd%\log\
call meili.exe -u %user% -p %pass% -d targetDevice.lst -i shmac.cmd
echo.
echo Port Discovery complete.
echo.
echo ************************************************************
echo.
echo Cleaning MAC Address List.
echo.
 
:: Treat the rawMacList for any NUL characters, which are show stoppers
IF EXIST rawMacList1.txt del /F rawMacList1.txt
if exist %cd%\log\%switch%.txt findstr ^[0-9] %cd%\log\%switch%.txt > 
rawMacList1.txt
 
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
IF EXIST subMacCleaned.txt del /F subMacCleaned.txt
for /f "tokens=* delims=" %%a in (rawMacList3.txt) do (
        set "str="
        set "str=%%a"
        set "str1=!str:::=!"
        echo !str1!>>subMacCleaned.txt
        )
echo Created subMacCleaned file.
echo.
 
:: If raw list line starts with a digit, send it to cleaned list
IF EXIST macCleaned.txt del /F macCleaned.txt
for /f "tokens=* delims=" %%s in (subMacCleaned.txt) do (
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
 
:: Remove spaces        
set "str="
IF EXIST macCleaned1.txt del /F macCleaned1.txt
for /f "tokens=* delims=" %%A in (macCleaned.txt) do (
        set "str=%%A"
        set "str=!str:     =,!"
        set "str=!str:    =,!"
        echo !str!>>macCleaned1.txt
        )       
echo Spaces removed and replaced with commas.
echo Created macCleaned1 file.
echo.
 
:: Remove "DYNAMIC" from cleaned file and output to converted file :26 to 37
set "str="
IF EXIST macCleaned2.txt del /f macCleaned2.txt
for /f "tokens=1,2,4 delims=," %%A in (macCleaned1.txt) do (
        echo %%A,%%B,%%C>>macCleaned2.txt
        )
echo Striped out "DYNAMIC".
echo Created macCleaned2 file.
echo.
 
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
echo Split mods and ports.
echo Created macCleaned3 file.
 
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
echo ************************************************************
echo.
echo Welcome to IP ARP Discovery
echo.
echo Building ARP Discovery List
 
:: Build list of MAC addresses for searchArp.bat
set "str="
IF EXIST arpList.txt del /F arpList.txt
for /f "tokens=4 delims=," %%M in (macCleaned5.txt) do (
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
call meili.exe -u %user% -p %pass% -d targetDevice.lst -i shvlan.cmd
echo.
echo Subnet Discovery complete.
echo.
echo ************************************************************
echo.
 
:: Treat the rawMacList for any NUL characters, which are show stoppers
IF EXIST rawVlanList.txt del /F rawVlanList.txt
if exist %cd%\log\%switch%.txt findstr ^[0-9] %cd%\log\%switch%.txt > 
rawVlanList.txt
 
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
        set "str=%%s"
        echo Pinging broadcast address of subnet !str!.0.
        call pingNet.bat !str!
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
set "routerIP=!str!.250"
echo !routerIP!
echo.
 
:: Find router name via "sh cdp n"
echo ************************************************************
echo.
echo Starting Meili to collect router info
echo.
rmdir /s /q %cd%\log\
call meili.exe -u %user% -p %pass% -d targetDevice.lst -i routerLookup.cmd
echo.
 
:: Router Name - clean out null characters
if exist routerName.txt del /F routerName.txt
if exist %cd%\log\%switch%.txt findstr ^[0-9] %cd%\log\%switch%.txt > 
routerName.txt
 
:: Router Name - Extract name
if exist routerName1.txt del /F routerName1.txt
set /A i=0
for /f "tokens=1 delims= " %%r in (routerName.txt) do (
        set /A i=!i!+1
        if !i! EQU 2 echo.%%r>>routerName1.txt
)
 
:: Remove leading spaces, should they exist
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
for /f "tokens=* delims=" %%r in ("%var%") do (
    set "router=%%r"
         echo %%r   !routerIP!   ssh>>routerDevice.lst
)
echo Created routerDevice.lst
echo.
echo Router is: !router!
echo.
 
:: Connect to .250 router and gather ip ARP info
echo ************************************************************
echo.
echo Starting Meili to collect IP addresses
echo.
rmdir /s /q %cd%\log\
call meili.exe -u %user% -p %pass% -d routerDevice.lst -i arpList.txt
echo.
echo IP ARP Discovery complete.
echo.
 
:: Clean log file
if exist arpList1.txt del /F arpList1.txt
if exist %cd%\log\!router!.txt findstr ^[0-9] %cd%\log\!router!.txt > 
arpList1.txt
:: If raw list line starts with Internet, send it to cleaned list
IF EXIST arpCleaned.txt del /F arpCleaned.txt
for /f "tokens=* delims=" %%s in (arpList1.txt) do (
        set "str="
        set "str=%%s"
        set "str=!str:~0,1!"
        if "!str:~0,1!"=="I" echo.%%s>>arpCleaned.txt
        )
echo Created arpCleaned file.
echo.
 
:: Pull out the IP addresses and MAC addresses on ports only    
set "str="
IF EXIST readyIPList.txt del /F readyIPList.txt
for /f "tokens=2,4 delims= " %%A in (arpCleaned.txt) do (
        set "str="
        set "str=%%C"
        echo %%B,%%A>>readyIPList.txt
)       
echo Cleaned up list.
echo Created readyIPList file.
echo.
 
:: Merge readyIPList.txt with macCleaned3
echo Adding IP addresses to MAC report.
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
echo Created macIP.txt.
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
echo Cleaning dnsList File.
 
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
