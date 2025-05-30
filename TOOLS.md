# Tools and Scripts

This project contains auxiliary scripts and tools organized in the `scripts/` folder for project development and deployment.

## Scripts Structure

```
scripts/
├── setup.sh      # Initial development environment setup
├── flash.sh      # Flashing script for Linux/macOS
└── README.md     # Scripts documentation
```

## Available Scripts

### `scripts/setup.sh`
Initial development environment setup script.
- Installs necessary dependencies
- Configures Arduino CLI
- Downloads required libraries
- Installs esptool.py

**Usage:**
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### `scripts/flash.sh`
Script to compile and flash the firmware to the device.
- Compiles the sketch
- Flashes to the ESP32-C6 device
- Includes debug options

**Usage:**
```bash
chmod +x scripts/flash.sh
./scripts/flash.sh
```

## Makefile (Recommended)

The project includes a fully optimized Makefile that integrates all tools:

### Main Features:
- ✅ **Automatic cleaning**: Cleans `build/` before each compilation
- ✅ **esptool.py integrated**: Optimized flashing for ESP32-C6
- ✅ **sketch.yaml**: Uses configuration profiles
- ✅ **Automatic detection**: Port and dependencies
- ✅ **Validations**: Verifies configuration before execution

### Basic Usage:
```bash
# Setup environment (once)
make setup

# Compile and flash
make deploy

# Monitor serial output
make monitor
```

### Detailed `make` Commands:

```bash
# General
make help             # Show all available options
make setup            # Setup development environment
make install-deps     # Install/update dependencies (Arduino CLI, ESP32 core, libs, esptool)
make check-deps       # Check if all dependencies are installed

# Configuration and Validation
make validate-sketch  # Validate sketch.yaml and board configuration
make show-config      # Display complete project configuration
make list-boards      # List available ESP32 boards
make list-ports       # List available serial ports
make check-port       # Check detected serial port

# Compilation
make build            # Compile the sketch (cleans build directory first)
make compile          # Alias for 'build'
make clean            # Clean all build files and cache
make clean-build      # Clean only the build directory
make clean-cache      # Clean Arduino CLI cache

# Flashing (using esptool.py)
make flash            # Flash the complete merged firmware (recommended)
make flash-individual # Flash individual components (bootloader, partitions, app)
make erase            # Erase the entire flash memory

# Deployment
make deploy           # Build and flash in one command
make export           # Export compiled binaries

# Monitoring and Debugging
make monitor          # Open serial monitor
make debug            # (Placeholder for future debug configurations)

# Information
make info             # Show information about generated binary files
make version          # Show project version (if defined)
```

## Arduino CLI Integration

The Makefile heavily relies on `arduino-cli` for compilation and board management.

### Key `arduino-cli` commands used:
- `arduino-cli compile`
- `arduino-cli upload` (used as a fallback or for specific cases)
- `arduino-cli core install/update`
- `arduino-cli lib install/update`
- `arduino-cli board listall`
- `arduino-cli version`

### `sketch.yaml`
This file is crucial for defining build profiles, board options, and library dependencies for `arduino-cli`.

Example profile (`zigbee_enddevice`):
```yaml
profiles:
  zigbee_enddevice:
    fqbn: esp32:esp32:esp32c6:ZigbeeMode=ed,PartitionScheme=zigbee
    platforms:
      - name: esp32:esp32
        version: "3.2.0"
    libraries:
      - "Adafruit SHT4x Library@1.0.0"
      - "Adafruit BusIO@1.17.1"
      - "Adafruit Unified Sensor@1.1.15"
    prebuild_script: "scripts/prebuild.sh" # Example
    postbuild_script: "scripts/postbuild.sh" # Example
```

## `esptool.py` Integration

For flashing ESP32 devices, `esptool.py` is preferred over `arduino-cli upload` due to its speed and advanced options.

### Key `esptool.py` commands used:
- `esptool.py erase_flash`
- `esptool.py write_flash`
- `esptool.py chip_id` (for port detection)

### Configuration for ESP32-C6:
- **Chip**: `esp32c6`
- **Baud rate**: `921600` (or configurable)
- **Flash mode**: `dio`
- **Flash frequency**: `80m`
- **Flash size**: `8MB` (or as per device)

The Makefile automatically determines most of these settings.

## Shell Scripts (`scripts/`)

### `setup.sh`
- **Purpose**: Automates the initial setup of the development environment.
- **Tasks**: 
  - Installs `arduino-cli`.
  - Installs the ESP32 core.
  - Installs required Arduino libraries.
  - Installs `esptool.py`.
  - Sets up serial port permissions (Linux).
- **Usage**: `make setup` or `./scripts/setup.sh`

### `flash.sh` (Legacy/Alternative)
- **Purpose**: Provides a standalone script for compiling and flashing.
- **Tasks**:
  - Compiles the sketch using `arduino-cli`.
  - Flashes using `arduino-cli upload` or `esptool.py` (configurable).
- **Usage**: `./scripts/flash.sh` (generally, `make deploy` is preferred).

## Port Detection Logic (Makefile)

The Makefile attempts to automatically detect the serial port connected to the ESP32.

1. **Linux**: Searches `/dev/ttyUSB*` and `/dev/ttyACM*`.
2. **macOS**: Searches `/dev/cu.usbserial-*` and `/dev/cu.SLAB_USBtoUART*`.
3. **Windows (WSL)**: Uses `powershell.exe` to query COM ports and maps them (e.g., COM3 to `/dev/ttyS3`).

If automatic detection fails, the port can be specified manually:
`make flash PORT=/dev/ttyUSB1`

## Environment Variables

Several environment variables can customize the build and flash process:
- `SKETCH_NAME`: Name of the main `.ino` file and sketch directory.
- `PROFILE`: Build profile from `sketch.yaml` (default: `zigbee_enddevice`).
- `BOARD_FQBN`: Fully Qualified Board Name (overrides profile FQBN).
- `PORT`: Serial port for flashing and monitoring.
- `BAUD_RATE`: Baud rate for `esptool.py` and serial monitor.
- `ESPTOOL_BAUD`: Specific baud rate for `esptool.py`.
- `MONITOR_BAUD`: Specific baud rate for the serial monitor.
- `VERBOSE`: Set to `1` for verbose output from `arduino-cli` and `esptool.py`.
- `ESP32_CORE_VERSION`: ESP32 core version to use (default: `3.2.0`).

Example: `make deploy PORT=/dev/ttyUSB0 VERBOSE=1`

## Customization

- **Adding new libraries**: Add to `sketch.yaml` and optionally to `scripts/setup.sh` if manual setup is supported.
- **Changing board options**: Modify `sketch.yaml` or use `BOARD_FQBN`.
- **Custom build steps**: Add pre-build or post-build scripts in `sketch.yaml`.

## Troubleshooting Tools

- `make check-deps`: Verifies all necessary tools and libraries are installed.
- `make validate-sketch`: Checks `sketch.yaml` syntax and FQBN validity.
- `make list-ports`: Shows available serial ports.
- `make clean && make build`: Forcing a clean rebuild can solve some issues.
- Verbose output: `make build VERBOSE=1` to get more detailed logs.

## Generated Files

### Optimized Build Structure:
```
build/esp32.esp32.esp32c6/
├── TemperatureHumidityZigbeeEndDevice.ino.merged.bin    # ⭐ Principal (4MB)
├── TemperatureHumidityZigbeeEndDevice.ino.bin           # App (588KB)
├── TemperatureHumidityZigbeeEndDevice.ino.bootloader.bin # Bootloader (21KB)
├── TemperatureHumidityZigbeeEndDevice.ino.partitions.bin # Partitions (3KB)
└── TemperatureHumidityZigbeeEndDevice.ino.elf           # Debug (8.3MB)
```

### Recommended Usage:
- **For normal flashing**: Use `merged.bin` with esptool.py
- **For development**: Use individual files if there are issues
- **For debugging**: Use `.elf` file with gdb

## esptool.py Troubleshooting

```bash
# Verify installation
esptool.py version

# Install/update
pip install --upgrade esptool

# Detect chip
esptool.py --port /dev/ttyUSB0 chip_id

# Flash information
esptool.py --port /dev/ttyUSB0 --chip esp32c6 flash_id
```

## Arduino CLI Troubleshooting

```bash
# Verify configuration
arduino-cli config dump

# Update index
arduino-cli core update-index

# Verify libraries
arduino-cli lib list

# Verify ESP32 core
arduino-cli core list esp32
```

## Common Issues

**"esptool.py: command not found"**
```bash
pip install esptool
# Or using the Makefile
make install-deps
```

**"Permission denied" on serial port**
```bash
# Linux: Add user to dialout group
sudo usermod -a -G dialout $USER
# Restart session

# Temporarily
sudo chmod 666 /dev/ttyUSB0
```

**Flashing failure**
```bash
# Try lower speed
esptool.py --chip esp32c6 --port /dev/ttyUSB0 --baud 115200 ...

# Force download mode
# Hold BOOT, press RESET, release RESET, release BOOT

# Use individual files
make flash-individual
```

## CI/CD Integration

The Makefile is optimized for use in CI/CD pipelines:

```bash
# Typical pipeline
make check-deps     # Verify environment
make validate-sketch # Validate configuration
make build          # Compile (includes cleanup)
make info           # Verify generated files
```

For automatic flashing on hardware in the loop:
```bash
# With specific port
make deploy PORT=/dev/ttyUSB0

# With automatic detection
make deploy
```

> 📝 **Note**: The file `ci.json` was **consolidated in `sketch.yaml`** following best practices for Arduino CLI. 