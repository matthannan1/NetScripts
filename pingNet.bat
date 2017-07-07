@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
rem Execute from CMD line as such: "pingNet.bat 10.25.68"
rem Where 10 25 and 68 are the network octets in 10.25.68.0.
rem 
rem
rem Delete files if they exists
rem
IF EXIST pingScanResults.txt del /F pingScanResults.txt
IF EXIST cleanedPingScanResults.txt del /F cleanedPingScanResults.txt
 
rem
rem
rem Find the live addresses
rem
echo %1 
for /l %%i in (1,1,254) do @(
        echo Pinging: %1.%%i
        ping %1.%%i -n 1 -w 100 | find /i "Reply">>pingScanResults.txt
        )
rem
rem
rem Clean up the ScanResults.txt file
rem
rem
for /f "tokens=3 delims= " %%a in (pingScanResults.txt) do (
        set S=%%a
        set S=!S:~0,-1!
        >> cleanedPingScanResults.txt echo.!S!
        )
del /F pingScanResults.txt
