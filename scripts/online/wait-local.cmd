@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0wait-local.ps1" %*
