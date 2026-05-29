@echo off
echo Iniciando el script de setup...

cd /d "%~dp0"

powershell.exe -Command "Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; .\setup\setup_and_run.ps1"

pause