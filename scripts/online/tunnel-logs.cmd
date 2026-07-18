@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tunnel-logs.ps1" %*
