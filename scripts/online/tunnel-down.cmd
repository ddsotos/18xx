@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tunnel-down.ps1" %*
