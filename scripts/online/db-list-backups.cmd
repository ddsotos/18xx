@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0db-list-backups.ps1" %*
