```bat
@echo off
title PENTA Compiler - Setup and Run

echo ==========================================
echo   PENTA Compiler - Setup and Run
echo ==========================================
echo.

REM Obtener la ruta donde está este .bat
cd /d "%~dp0"

REM Verificar que exista el script PowerShell
if not exist "setup\setup_and_run.ps1" (
    echo [ERROR] No se encontro:
    echo   setup\setup_and_run.ps1
    echo.
    echo Verifica que la carpeta setup exista.
    pause
    exit /b 1
)

echo [INFO] Iniciando instalacion/verificacion...
echo.

REM Ejecutar PowerShell con bypass temporal
powershell -NoProfile -ExecutionPolicy Bypass -File ".\setup\setup_and_run.ps1"

REM Si algo falla, mantener la ventana abierta
if %errorlevel% neq 0 (
    echo.
    echo ==========================================
    echo [ERROR] El script termino con errores.
    echo Revisa el mensaje mostrado arriba.
    echo ==========================================
    pause
    exit /b %errorlevel%
)

echo.
echo ==========================================
echo [OK] PENTA Compiler finalizado.
echo ==========================================
pause
```
