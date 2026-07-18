@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0preflight.ps1" %*
