@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tunnel-up.ps1" %*
