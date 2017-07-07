@echo off
cls
echo ************************************************************
echo.
echo Welcome to Host Discovery
echo.
set /P switch=Access switch to investigate? 
rem set /P subnet=Subnet to investigate? (example 10.25.68) 
set /P pass=What is your password? 
cls
 
 
echo.
echo Here we go!
echo.
call PortDiscoverySmall.bat %switch%,%pass%
