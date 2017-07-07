@echo off
setlocal disableDelayedExpansion
title %~n0
set $lf=^
 
::
set "$iFile=rawMacList1.TXT"
set "$oFile=rawMacList2.TXT"
 
set /a XP = 512600 &for /f "tokens=2 delims=[]" %%? in (
        'ver.EXE'
) do for /f "tokens=2-4 delims=. " %%a in (
        "%%~?"
) do set /a $ver = %%~a%%~b%%~c
 
 
cls
echo.¯ '%$iFile%'
rem type "%$iFile%"
echo.
echo.® '%$iFile%'
 
more "%$iFile%" > "tmp.TXT"
 
for /f %%? in ( '2^>nul ^( ^< "%$iFile%" find.EXE /c /v "" ^)' ) do set "$end=%%?"
 
< "tmp.TXT" (
 
        for /l %%! in (
        
                1, 1, %$end%
                
        ) do set "$=" &set /p "$=" &(
        
                setlocal enabledelayedexpansion
                rem (
                        if defined $ (
                                if %%~! neq !$end! set "$=!$!!$lf!"
                                
                                <nul set /p ="!$!">&2
                                <nul set /p ="!$!"
                                
                        ) else if %%~! neq !$end! if !$ver! gtr !XP! (
                                <nul set /p ="!$lf!">&2
                                <nul set /p ="!$lf!"
                                
                        ) else (
                        
                                <nul set /p ="!$lf!">&2
                                <nul set /p ="!$lf!"
                                
                                )
                
                rem )
                endlocal
        )
) > "%$oFile%"
set /a $end -= 1
 
echo.
echo.¯ '%$oFile%'
type "%$oFile%" &echo.
echo.® '%$oFile%'
 
echo.linefeeds[%$end%]
