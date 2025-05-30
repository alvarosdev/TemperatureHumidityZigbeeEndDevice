#!/bin/bash
set -e

echo "========================================"
echo "Flasheando ESP32C6"
echo "========================================"

# Verificar si Python está instalado
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python3 no está instalado o no está en el PATH"
    echo "Por favor instala Python3"
    exit 1
fi

# Obtener el directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKETCH_PATH="$(dirname "$SCRIPT_DIR")"
BUILD_PATH="$SKETCH_PATH/build/esp32.esp32.esp32c6"

# Verificar que existan los archivos binarios
if [ ! -f "$BUILD_PATH/main.ino.bootloader.bin" ] || [ ! -f "$BUILD_PATH/main.ino.partitions.bin" ] || [ ! -f "$BUILD_PATH/main.ino.bin" ]; then
    echo "ERROR: No se encontraron los archivos binarios necesarios"
    echo "Por favor ejecuta el script de compilación primero: ./scripts/build.sh"
    exit 1
fi

# Verificar/instalar esptool
if ! python3 -c "import esptool" 2>/dev/null; then
    echo "esptool no está instalado. Instalando..."
    python3 -m pip install esptool --user
fi

# Detectar puerto automáticamente (Linux/macOS)
PORT=""
if [ -e /dev/ttyUSB0 ]; then
    PORT="/dev/ttyUSB0"
elif [ -e /dev/ttyACM0 ]; then
    PORT="/dev/ttyACM0"
elif ls /dev/cu.usbserial* 1> /dev/null 2>&1; then
    PORT=$(ls /dev/cu.usbserial* | head -n1)
elif ls /dev/cu.SLAB_USBtoUART* 1> /dev/null 2>&1; then
    PORT=$(ls /dev/cu.SLAB_USBtoUART* | head -n1)
else
    echo "ERROR: No se pudo detectar automáticamente el puerto del ESP32"
    echo "Puertos disponibles:"
    ls /dev/tty* 2>/dev/null | grep -E "(USB|ACM|usbserial|SLAB)" || echo "Ningún puerto encontrado"
    echo ""
    echo "Por favor especifica el puerto manualmente editando el script"
    exit 1
fi

echo "Puerto detectado: $PORT"
echo "Archivos a flashear:"
echo "  Bootloader: $BUILD_PATH/main.ino.bootloader.bin"
echo "  Partitions: $BUILD_PATH/main.ino.partitions.bin"
echo "  App: $BUILD_PATH/main.ino.bin"

# Flashear
echo ""
echo "Iniciando flasheo..."
python3 -m esptool --chip esp32c6 --port "$PORT" --baud 921600 --before default_reset --after hard_reset write_flash -z --flash_mode dio --flash_freq 80m --flash_size 8MB 0x0 "$BUILD_PATH/main.ino.bootloader.bin" 0x8000 "$BUILD_PATH/main.ino.partitions.bin" 0x10000 "$BUILD_PATH/main.ino.bin"

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "✓ Flasheo exitoso"
    echo "========================================"
else
    echo ""
    echo "========================================"
    echo "✗ Error en el flasheo"
    echo "========================================"
    exit 1
fi 