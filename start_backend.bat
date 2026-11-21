@echo off
chcp 65001 >nul
title BLS Enterprise Server (Port 5000)
cd /d "%~dp0backend"
echo ========================================================
echo   🏫 BLS Enterprise Server • Bright Light School
echo   Port: 5000
echo   [!] សូមកុំបិទផ្ទាំងនេះ (Keep this window open)
echo ========================================================
echo.
start "" http://localhost:5000
node server.js
if %errorlevel% neq 0 (
    echo.
    echo [!] Server ឈប់ដំណើរការដោយសារកំហុស (Error code: %errorlevel%)
    pause
)
