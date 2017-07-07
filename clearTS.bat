@echo off
cls
 
set /P "ts=Which Terminal Server? "
set /P "pass=What is your password? "
echo *********************************
echo Need to set/verify the ssh key.
echo Accept ssh key, if needed, then 
echo log in and then exit back out.
echo *********************************
echo.
echo plink -ssh %ts%
plink -ssh %USERNAME%@%ts%  -pw %pass%
echo.
echo *********************************
echo Now to clear some lines...
echo *********************************
echo.
if exist tsout.dat del f tsout.dat
plink -ssh %USERNAME%@%ts%  -pw %pass% < tsclear.dat > tsout.dat 
echo *********************************
echo Should be all set.
echo Check tsout.dat file for output.
echo *********************************
echo.
