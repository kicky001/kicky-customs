@echo off
title Kicky Server

:: 检查是否以管理员运行（监听所有网卡需要管理员权限）
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting admin privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

powershell -ExecutionPolicy Bypass -File "%~dp0server.ps1"
pause
