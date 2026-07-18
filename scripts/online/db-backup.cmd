@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0db-backup.ps1" %*
