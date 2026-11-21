@echo off
chcp 65001 >nul
title BLS Mobile Tunnel - Port 5000
echo ========================================================
echo   🏫 Bright Light School - Online Public HTTPS Tunnel
echo ========================================================
echo.
echo [!] ប្រាកដថា "node server.js" កំពុងដំណើរការលើ Port 5000...
echo.

:loop
echo [%time%] កំពុងតភ្ជាប់ទៅកាន់ Pinggy Tunnel...
echo.
ssh -p 443 -R0:127.0.0.1:5000 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ServerAliveCountMax=3 nTh62Kv4NWl@free.pinggy.io

echo.
echo [!] ការតភ្ជាប់បានដាច់ (Disconnected)។
echo [!] នឹងធ្វើការភ្ជាប់ឡើងវិញដោយស្វ័យប្រវត្តក្នុងរយៈពេល ៣ វិនាទី...
timeout /t 3 >nul
goto loop
