@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
rem Execute from CMD line as such: "pingNet.bat 10.25.68"
rem Where 10 25 and 68 are the network octets in 10.25.68.0.


:: Delete files if they exists
set "switch=%1"
IF EXIST pingScanResults.txt del /F pingScanResults.txt
IF EXIST cleanedPingScanResults.txt del /F cleanedPingScanResults.txt

goto :comment12

:: Ping all addresses
echo %1 
for /l %%i in (1,1,254) do @(
	echo Pinging: %1
	ping %1 -n 1 -w 100 | find /i "Reply">>pingScanResults.txt
	)
	
:comment12

ping %1.255 


goto :comment13
	
::Clean up the ScanResults.txt file
for /f "tokens=3 delims= " %%a in (pingScanResults.txt) do (
	set S=%%a
	set S=!S:~0,-1!
	>> cleanedPingScanResults.txt echo.!S!
	)
	
del /F pingScanResults.txt
:comment13
