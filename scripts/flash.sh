#!/bin/bash
set -e

echo "========================================"
echo "Flashing ESP32C6"
echo "========================================"

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python3 is not installed or not in PATH"
    echo "Please install Python3"
    exit 1
fi

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKETCH_PATH="$(dirname "$SCRIPT_DIR")"
BUILD_PATH="$SKETCH_PATH/build/esp32.esp32.esp32c6"

# Check that binary files exist
if [ ! -f "$BUILD_PATH/main.ino.bootloader.bin" ] || [ ! -f "$BUILD_PATH/main.ino.partitions.bin" ] || [ ! -f "$BUILD_PATH/main.ino.bin" ]; then
    echo "ERROR: Required binary files not found"
    echo "Please run the compilation script first: ./scripts/build.sh"
    exit 1
fi

# Check/install esptool
if ! python3 -c "import esptool" 2>/dev/null; then
    echo "esptool is not installed. Installing..."
    python3 -m pip install esptool --user
fi

# Automatically detect port (Linux/macOS)
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
    echo "ERROR: Could not automatically detect ESP32 port"
    echo "Available ports:"
    ls /dev/tty* 2>/dev/null | grep -E "(USB|ACM|usbserial|SLAB)" || echo "No ports found"
    echo ""
    echo "Please specify the port manually by editing the script"
    exit 1
fi

echo "Detected port: $PORT"
echo "Files to flash:"
echo "  Bootloader: $BUILD_PATH/main.ino.bootloader.bin"
echo "  Partitions: $BUILD_PATH/main.ino.partitions.bin"
echo "  App: $BUILD_PATH/main.ino.bin"

# Flash
echo ""
echo "Starting flash process..."
python3 -m esptool --chip esp32c6 --port "$PORT" --baud 921600 --before default_reset --after hard_reset write_flash -z --flash_mode dio --flash_freq 80m --flash_size 8MB 0x0 "$BUILD_PATH/main.ino.bootloader.bin" 0x8000 "$BUILD_PATH/main.ino.partitions.bin" 0x10000 "$BUILD_PATH/main.ino.bin"

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "✓ Flashing successful"
    echo "========================================"
else
    echo ""
    echo "========================================"
    echo "✗ Flashing error"
    echo "========================================"
    exit 1
fi 