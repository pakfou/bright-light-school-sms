@echo off
chcp 65001 >nul
title BLS Cloudflare Tunnel (Port 5000)
echo ========================================================
echo   🌐 Starting Cloudflare HTTPS Tunnel (No 502 Error)
echo ========================================================
echo.
echo [!] Make sure "node server.js" (Port 5000) is running!
echo.
"%~dp0cloudflared.exe" tunnel --url http://127.0.0.1:5000
pause
