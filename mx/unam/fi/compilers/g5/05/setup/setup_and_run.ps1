<# 
============================================================
 PENTA Compiler - Setup and Run
 Windows PowerShell
============================================================

Uso recomendado:
  1) Colocar este archivo en la raíz del proyecto, o en setup/.
  2) Abrir PowerShell en la carpeta del proyecto.
  3) Si PowerShell bloquea scripts, ejecutar solo para esta sesión:

       Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

  4) Ejecutar:

       .\setup_and_run.ps1

Este script intenta preparar el entorno completo y abrir la GUI.
Si una instalación requiere permisos de administrador, muestra los
comandos necesarios y evita continuar de forma desordenada.
============================================================
#>

$ErrorActionPreference = "Stop"

function Info($Message) { Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Ok($Message) { Write-Host "[OK] $Message" -ForegroundColor Green }
function Warn($Message) { Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Fail($Message) { Write-Host "[ERROR] $Message" -ForegroundColor Red }

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if (Test-Path (Join-Path $ScriptDir "src")) {
    $RootDir = $ScriptDir
}
elseif (Test-Path (Join-Path $ScriptDir "..\src")) {
    $RootDir = Resolve-Path (Join-Path $ScriptDir "..")
}
else {
    Fail "No pude encontrar la carpeta src/."
    Write-Host "Coloca este script en la raíz del proyecto o dentro de una carpeta setup/."
    exit 1
}

Set-Location $RootDir

function Require-Path($Path) {
    if (-not (Test-Path $Path)) {
        Fail "Falta el archivo o carpeta requerida: $Path"
        Write-Host "Verifica que estés usando el proyecto completo antes de continuar."
        exit 1
    }
}

Require-Path "src\GUI.py"
Require-Path "tools\check_environment.py"
Require-Path "requirements.txt"

function Test-Admin {
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
    return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Ask-YesNo($Question) {
    $Answer = Read-Host "$Question [y/N]"
    return $Answer -match "^(y|Y|yes|YES)$"
}

function Test-PythonCompatible($Command) {
    try {
        & $Command -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" | Out-Null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function Find-Python {
    $Candidates = @("python", "py")

    foreach ($Candidate in $Candidates) {
        $Cmd = Get-Command $Candidate -ErrorAction SilentlyContinue
        if ($null -eq $Cmd) { continue }

        if ($Candidate -eq "py") {
            try {
                py -3 -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" | Out-Null
                if ($LASTEXITCODE -eq 0) { return "py -3" }
            }
            catch {
                continue
            }
        }
        else {
            if (Test-PythonCompatible $Candidate) { return $Candidate }
        }
    }

    return $null
}

function Invoke-Python($PythonCommand, $Arguments) {
    if ($PythonCommand -eq "py -3") {
        & py -3 @Arguments
    }
    else {
        & $PythonCommand @Arguments
    }
}

function Test-Tkinter($PythonCommand) {
    try {
        Invoke-Python $PythonCommand @("-c", "import tkinter") | Out-Null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function Add-Graphviz-ToCurrentPath {
    $Candidates = @(
        "C:\Program Files\Graphviz\bin",
        "C:\Program Files (x86)\Graphviz\bin"
    )

    foreach ($Path in $Candidates) {
        if (Test-Path (Join-Path $Path "dot.exe")) {
            if ($env:Path -notlike "*$Path*") {
                $env:Path = "$Path;$env:Path"
            }
            return
        }
    }
}

function Require-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Fail "winget no está disponible en este equipo."
        Write-Host ""
        Write-Host "Instala manualmente:"
        Write-Host "  - Python 3.10 o superior"
        Write-Host "  - Graphviz"
        Write-Host ""
        Write-Host "Después abre una nueva terminal y vuelve a ejecutar este script."
        exit 1
    }
}

function Show-AdminInstructions($Commands) {
    Fail "Faltan dependencias que pueden requerir permisos de administrador."
    Write-Host ""
    Write-Host "Abre PowerShell como administrador y ejecuta:"
    Write-Host ""
    foreach ($Command in $Commands) {
        Write-Host "  $Command"
    }
    Write-Host ""
    Write-Host "Después cierra y vuelve a abrir PowerShell normal, y ejecuta otra vez este script."
    exit 1
}

Info "Proyecto detectado en: $RootDir"
Info "Sistema detectado: Windows"

$PythonCommand = Find-Python
$DotCommand = Get-Command dot -ErrorAction SilentlyContinue

if ($null -eq $DotCommand) {
    Add-Graphviz-ToCurrentPath
    $DotCommand = Get-Command dot -ErrorAction SilentlyContinue
}

$MissingInstallCommands = @()

if ($null -eq $PythonCommand) {
    $MissingInstallCommands += "winget install Python.Python.3.12 --accept-source-agreements --accept-package-agreements"
}

if ($null -eq $DotCommand) {
    $MissingInstallCommands += "winget install Graphviz.Graphviz --accept-source-agreements --accept-package-agreements"
}

if ($MissingInstallCommands.Count -gt 0) {
    Require-Winget

    if (-not (Test-Admin)) {
        Show-AdminInstructions $MissingInstallCommands
    }

    Warn "Faltan dependencias del sistema."
    Write-Host ""
    Write-Host "Comandos que se ejecutarán:"
    foreach ($Command in $MissingInstallCommands) {
        Write-Host "  $Command"
    }
    Write-Host ""

    if (Ask-YesNo "¿Quieres que intente instalar estas dependencias ahora?") {
        foreach ($Command in $MissingInstallCommands) {
            Info "Ejecutando: $Command"
            Invoke-Expression $Command
        }
    }
    else {
        Warn "Instalación cancelada por el usuario."
        Write-Host "Ejecuta manualmente los comandos mostrados y vuelve a correr este script."
        exit 1
    }

    Add-Graphviz-ToCurrentPath
    $PythonCommand = Find-Python
    $DotCommand = Get-Command dot -ErrorAction SilentlyContinue
}

if ($null -eq $PythonCommand) {
    Fail "No encontré Python 3.10 o superior después de la instalación."
    Write-Host "Instala Python manualmente y vuelve a ejecutar este script."
    exit 1
}

if (-not (Test-Tkinter $PythonCommand)) {
    Fail "Python está instalado, pero Tkinter no está disponible."
    Write-Host ""
    Write-Host "En Windows normalmente Tkinter viene con Python."
    Write-Host "Solución recomendada:"
    Write-Host "  1) Reinstala Python desde python.org."
    Write-Host "  2) Activa la opción Tcl/Tk and IDLE durante la instalación."
    Write-Host "  3) Vuelve a ejecutar este script."
    exit 1
}

if ($null -eq $DotCommand) {
    Fail "Graphviz no está disponible en PATH. El comando dot no se reconoce."
    Write-Host ""
    Write-Host "Si Graphviz se acaba de instalar, cierra y abre PowerShell."
    Write-Host "También verifica que esta ruta esté en PATH:"
    Write-Host "  C:\Program Files\Graphviz\bin"
    exit 1
}

Ok "Python detectado: $PythonCommand"
Ok "Graphviz detectado."

if (-not (Test-Path ".venv")) {
    Info "Creando entorno virtual .venv..."
    Invoke-Python $PythonCommand @("-m", "venv", ".venv")

    if ($LASTEXITCODE -ne 0) {
        Fail "No se pudo crear el entorno virtual."
        exit 1
    }
}
else {
    Ok "Entorno virtual .venv ya existe."
}

Info "Activando entorno virtual..."
$ActivateScript = Join-Path $RootDir ".venv\Scripts\Activate.ps1"

if (-not (Test-Path $ActivateScript)) {
    Fail "No se encontró el script de activación del entorno virtual."
    exit 1
}

. $ActivateScript

Info "Instalando dependencias de Python..."
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

if ($LASTEXITCODE -ne 0) {
    Fail "No se pudieron instalar las dependencias de Python."
    exit 1
}

Info "Ejecutando verificador de entorno..."
python tools\check_environment.py

if ($LASTEXITCODE -ne 0) {
    Fail "El verificador encontró problemas."
    Write-Host "Corrige los elementos marcados como [NO] y vuelve a ejecutar este script."
    exit 1
}

Ok "Entorno listo. Abriendo PENTA Compiler..."
Set-Location src
python GUI.py
