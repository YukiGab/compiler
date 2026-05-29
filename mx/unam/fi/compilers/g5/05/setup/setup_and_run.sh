#!/usr/bin/env bash
# ============================================================
# PENTA Compiler - Setup and Run
# Linux / macOS
# ============================================================
#
# Uso recomendado:
#   1) Colocar este archivo en la raíz del proyecto, o en setup/.
#   2) Dar permisos de ejecución:
#        chmod +x setup_and_run.sh
#   3) Ejecutar:
#        ./setup_and_run.sh
#
# Este script intenta preparar el entorno completo y abrir la GUI.
# Si una instalación requiere permisos de administrador, se muestra
# el comando necesario y se pide confirmación antes de ejecutar algo.
# ============================================================

set -Eeuo pipefail

info() { printf "\033[1;34m[INFO]\033[0m %s\n" "$1"; }
ok() { printf "\033[1;32m[OK]\033[0m %s\n" "$1"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$1"; }
fail() { printf "\033[1;31m[ERROR]\033[0m %s\n" "$1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -d "$SCRIPT_DIR/src" ]]; then
    ROOT_DIR="$SCRIPT_DIR"
elif [[ -d "$SCRIPT_DIR/../src" ]]; then
    ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
else
    fail "No pude encontrar la carpeta src/."
    echo "Coloca este script en la raíz del proyecto o dentro de una carpeta setup/."
    exit 1
fi

cd "$ROOT_DIR"

require_file() {
    local path="$1"
    if [[ ! -e "$path" ]]; then
        fail "Falta el archivo o carpeta requerida: $path"
        echo "Verifica que estés usando el proyecto completo antes de continuar."
        exit 1
    fi
}

require_file "src/GUI.py"
require_file "tools/check_environment.py"
require_file "requirements.txt"

command_exists() { command -v "$1" >/dev/null 2>&1; }

ask_yes_no() {
    local question="$1"
    local answer
    read -r -p "$question [y/N]: " answer
    case "$answer" in
        y|Y|yes|YES) return 0 ;;
        *) return 1 ;;
    esac
}

python_is_compatible() {
    local cmd="$1"
    "$cmd" - <<'PY' >/dev/null 2>&1
import sys
raise SystemExit(0 if sys.version_info >= (3, 10) else 1)
PY
}

find_python() {
    if command_exists python3 && python_is_compatible python3; then
        echo "python3"
        return 0
    fi

    if command_exists python && python_is_compatible python; then
        echo "python"
        return 0
    fi

    return 1
}

tkinter_available() {
    local cmd="$1"
    "$cmd" - <<'PY' >/dev/null 2>&1
import tkinter
PY
}

run_manual_or_confirmed() {
    local description="$1"
    local command_text="$2"

    warn "$description"
    echo
    echo "Comando sugerido:"
    echo "  $command_text"
    echo

    if ask_yes_no "¿Quieres que intente ejecutarlo ahora?"; then
        info "Ejecutando instalación solicitada..."
        eval "$command_text"
    else
        warn "Instalación cancelada por el usuario."
        echo "Ejecuta manualmente el comando mostrado y vuelve a correr este script."
        exit 1
    fi
}

OS_NAME="$(uname -s)"

case "$OS_NAME" in
    Darwin) PLATFORM="macos" ;;
    Linux) PLATFORM="linux" ;;
    *)
        fail "Sistema no soportado por este script: $OS_NAME"
        echo "Para Windows usa setup_and_run.ps1."
        exit 1
        ;;
esac

info "Proyecto detectado en: $ROOT_DIR"
info "Sistema detectado: $PLATFORM"

install_macos_dependencies() {
    local formulas=()

    if ! command_exists brew; then
        fail "Homebrew no está instalado."
        echo
        echo "Para instalar dependencias automáticamente en macOS se recomienda Homebrew."
        echo "Instálalo con el comando oficial:"
        echo
        echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        echo
        echo "Después cierra y abre la terminal, y vuelve a ejecutar este script."
        exit 1
    fi

    if ! find_python >/dev/null 2>&1; then
        formulas+=("python")
    fi

    if ! command_exists dot; then
        formulas+=("graphviz")
    fi

    local py_cmd=""
    if py_cmd="$(find_python 2>/dev/null)"; then
        if ! tkinter_available "$py_cmd"; then
            formulas+=("python-tk")
        fi
    else
        formulas+=("python-tk")
    fi

    if (( ${#formulas[@]} > 0 )); then
        local unique_formulas
        unique_formulas="$(printf "%s\n" "${formulas[@]}" | awk '!seen[$0]++' | tr '\n' ' ')"
        run_manual_or_confirmed \
            "Faltan dependencias del sistema en macOS." \
            "brew install $unique_formulas"
    else
        ok "Dependencias del sistema disponibles."
    fi
}

install_linux_dependencies() {
    local install_cmd=""

    if command_exists apt; then
        install_cmd="sudo apt update && sudo apt install -y python3 python3-pip python3-venv python3-tk graphviz"
    elif command_exists dnf; then
        install_cmd="sudo dnf install -y python3 python3-pip python3-tkinter graphviz"
    elif command_exists pacman; then
        install_cmd="sudo pacman -Sy --needed python python-pip tk graphviz"
    else
        fail "No se detectó un gestor de paquetes compatible."
        echo
        echo "Instala manualmente:"
        echo "  - Python 3.10 o superior"
        echo "  - pip"
        echo "  - venv"
        echo "  - Tkinter"
        echo "  - Graphviz"
        echo
        echo "Después vuelve a ejecutar este script."
        exit 1
    fi

    local py_cmd=""
    local needs_install=false

    if ! find_python >/dev/null 2>&1; then
        needs_install=true
    else
        py_cmd="$(find_python)"
        if ! tkinter_available "$py_cmd"; then
            needs_install=true
        fi
    fi

    if ! command_exists dot; then
        needs_install=true
    fi

    if [[ "$needs_install" == true ]]; then
        if ! command_exists sudo && [[ "$(id -u)" -ne 0 ]]; then
            fail "Se requieren permisos de administrador, pero sudo no está disponible."
            echo
            echo "Pide a un administrador ejecutar:"
            echo "  $install_cmd"
            echo
            echo "Después vuelve a correr este script."
            exit 1
        fi

        run_manual_or_confirmed \
            "Faltan dependencias del sistema en Linux. Puede pedir contraseña de administrador." \
            "$install_cmd"
    else
        ok "Dependencias del sistema disponibles."
    fi
}

if [[ "$PLATFORM" == "macos" ]]; then
    install_macos_dependencies
else
    install_linux_dependencies
fi

PYTHON_CMD="$(find_python || true)"
if [[ -z "$PYTHON_CMD" ]]; then
    fail "No encontré Python 3.10 o superior después de la instalación."
    echo "Instala Python manualmente y vuelve a ejecutar este script."
    exit 1
fi

if ! tkinter_available "$PYTHON_CMD"; then
    fail "Python está instalado, pero Tkinter no está disponible."
    echo "Instala Tkinter para tu sistema y vuelve a correr el script."
    exit 1
fi

if ! command_exists dot; then
    fail "Graphviz no está disponible en PATH. El comando dot no se reconoce."
    echo "Instala Graphviz o vuelve a abrir la terminal si acabas de instalarlo."
    exit 1
fi

ok "Python detectado: $($PYTHON_CMD --version)"
ok "Graphviz detectado: $(dot -V 2>&1)"

if [[ ! -d ".venv" ]]; then
    info "Creando entorno virtual .venv..."
    if ! "$PYTHON_CMD" -m venv .venv; then
        fail "No se pudo crear el entorno virtual."
        echo
        echo "En Linux normalmente se corrige instalando python3-venv."
        echo "Vuelve a ejecutar este script después de instalarlo."
        exit 1
    fi
else
    ok "Entorno virtual .venv ya existe."
fi

info "Activando entorno virtual..."
# shellcheck disable=SC1091
source ".venv/bin/activate"

info "Instalando dependencias de Python..."
python -m pip install --upgrade pip
python -m pip install -r requirements.txt

info "Ejecutando verificador de entorno..."
if ! python tools/check_environment.py; then
    fail "El verificador encontró problemas."
    echo "Corrige los elementos marcados como [NO] y vuelve a ejecutar este script."
    exit 1
fi

ok "Entorno listo. Abriendo PENTA Compiler..."
cd src
python GUI.py
