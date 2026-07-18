@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0collect-diagnostics.ps1" %*
