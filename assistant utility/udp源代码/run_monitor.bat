@echo off
chcp 65001 >nul
cd /d "%~dp0"
python udp_monitor.py
pause
