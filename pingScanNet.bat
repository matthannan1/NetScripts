@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
rem Execute from CMD line as such: "pingScanNet.bat 10.25.68"
rem Where 10 25 and 68 are the network octets in 10.25.68.0.
rem Created by Matt Hannan 7 March 2018


:: Delete files if they exists
IF EXIST pingScanResults.txt del /F pingScanResults.txt
IF EXIST cleanedPingScanResults.txt del /F cleanedPingScanResults.txt


:: Ping all addresses
echo %1 
for /l %%i in (1,1,254) do @(
	set "host_ip="
	set "host_ip=%%i"
	set "target="
	set "target=%1%.!host_ip!"
	echo Pinging: !target!
	ping !target! -n 1 -w 100 | find /i "Reply">>pingScanResults.txt
	)
	

	
::Clean up the pingScanResults.txt file
for /f "tokens=3 delims= " %%a in (pingScanResults.txt) do (
	set S=%%a
	set S=!S:~0,-1!
	>> cleanedPingScanResults.txt echo.!S!
	)
	

