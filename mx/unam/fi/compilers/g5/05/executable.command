#!/usr/bin/env bash

echo "Iniciando el script de setup..."

cd "$(dirname "$0")"

chmod +x ./setup/setup_and_run.sh
./setup/setup_and_run.sh

read -p "Presiona ENTER para cerrar..."