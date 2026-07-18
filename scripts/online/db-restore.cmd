@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0db-restore.ps1" %*
