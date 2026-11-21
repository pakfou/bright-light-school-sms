@echo off
title Allow Port 5000 for Mobile Phone Access
echo ========================================================
echo   Opening Port 5000 in Windows Firewall...
echo ========================================================
netsh advfirewall firewall add rule name="BLS_Server_5000" dir=in action=allow protocol=TCP localport=5000
if %errorlevel% equ 0 (
    echo.
    echo [SUCCESS] Port 5000 is now allowed!
    echo Your phone can now connect to: http://192.168.100.43:5000
) else (
    echo.
    echo [ERROR] Please right-click this file and select "Run as administrator"!
)
echo.
pause
