# Temperature Humidity Zigbee End Device

A temperature and humidity sensor based on ESP32-C6 with Zigbee connectivity, designed as an End Device.

## Features

- **Sensor**: SHT40 for temperature and humidity measurement
- **Connectivity**: Zigbee 3.0 as End Device
- **Microcontroller**: ESP32-C6
- **Power Mode**: Deep Sleep to maximize battery life
- **Compatibility**: Arduino CLI and Arduino IDE

## Project Structure

This project follows the standard Arduino CLI sketch specification:

```
TemperatureHumidityZigbeeEndDevice/
├── TemperatureHumidityZigbeeEndDevice.ino  # Main sketch (must match the folder name)
├── sketch.yaml                             # Project configuration file (arduino-cli)
├── Makefile                                # Build and deploy automation
├── scripts/                                # Auxiliary scripts and tools
│   ├── setup.sh                           # Environment setup script
│   └── flash.sh                           # Flashing script for Linux/macOS
├── data/                                   # Sketch data files (optional)
├── src/                                    # Additional source files (optional)
├── build/                                  # Compiled files directory (generated)
├── TOOLS.md                               # Tools documentation
└── README.md                              # This file
```

## Scripts and Auxiliary Tools

The `scripts/` folder contains auxiliary scripts and tools for development, compilation, and deployment of the ESP32-C6 Temperature Humidity Zigbee End Device project.

### Setup Scripts

#### `scripts/setup.sh`
Initial development environment configuration script for Unix-like systems (Linux/macOS).

**Features:**
- Automatically installs Arduino CLI
- Configures ESP32 core version 3.2.0
- Installs all required libraries:
  - Adafruit SHT4x Library
  - Adafruit BusIO
  - Adafruit Unified Sensor
- Installs esptool.py for optimized flashing
- Configures user permissions for serial ports

**Usage:**
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

**Makefile equivalent:**
```bash
make setup
```

### Deployment Scripts

#### `scripts/flash.sh`
Compilation and flashing script for Unix-like systems (Linux/macOS).

**Features:**
- Compiles the sketch using arduino-cli
- Automatically detects connection port
- Flashes to ESP32-C6 with optimized configuration
- Includes debug and logging options

**Usage:**
```bash
chmod +x scripts/flash.sh
./scripts/flash.sh
```

**Makefile equivalent:**
```bash
make deploy
```

### Centralized Configuration

> 📝 **Note**: Previously there was a `ci.json` file in this folder, but it has been **consolidated into `sketch.yaml`** following Arduino CLI best practices.

All project configuration is now centralized in `sketch.yaml` at the project root:

```yaml
profiles:
  zigbee_enddevice:
    # Board options for Zigbee End Device
    board_options:
      PartitionScheme: "zigbee"
      ZigbeeMode: "ed"

    # Build properties for Zigbee configuration
    build_properties:
      - "compiler.cpp.extra_flags=-DCONFIG_SOC_IEEE802154_SUPPORTED=1"
      - "compiler.cpp.extra_flags=-DCONFIG_ZB_ENABLED=1"
      - "compiler.cpp.extra_flags=-DZIGBEE_MODE_ED=1"
```

**Consolidation advantages:**
- ✅ **Single configuration file**: All configuration in `sketch.yaml`
- ✅ **Fewer files**: Simplifies the project
- ✅ **Arduino CLI standard**: Follows official best practices
- ✅ **Easy maintenance**: Single place to change configurations

### Migration from Root

Scripts were moved from project root to this folder following organization best practices:

**Before:**
```
TemperatureHumidityZigbeeEndDevice/
├── setup.sh
├── flash.sh
├── ci.json              # ❌ Redundant
└── ...
```

**After:**
```
TemperatureHumidityZigbeeEndDevice/
├── sketch.yaml          # ✅ Consolidated configuration
├── scripts/
│   ├── setup.sh
│   └── flash.sh
└── ...
```

### Recommended Alternatives

#### 1. Makefile (Most recommended)
The project includes an optimized Makefile that replaces the need to run individual scripts:

```bash
make setup     # Replaces ./scripts/setup.sh
make deploy    # Replaces ./scripts/flash.sh
make flash     # Flashing with esptool.py (faster)
make build     # Compile only
make monitor   # Serial monitor
```

#### 2. Arduino CLI + esptool.py (For advanced users)
```bash
# Compile using consolidated profile
arduino-cli compile --profile zigbee_enddevice --export-binaries .

# Flash with esptool.py
esptool.py --chip esp32c6 --port /dev/ttyUSB0 --baud 921600 \
    --before default_reset --after hard_reset write_flash \
    --flash_mode dio --flash_freq 80m --flash_size 8MB \
    0x0 build/esp32.esp32.esp32c6/TemperatureHumidityZigbeeEndDevice.ino.merged.bin
```

### Scripts Troubleshooting

**Scripts not executable:**
```bash
chmod +x scripts/*.sh
```

**Serial port permission errors (Linux):**
```bash
sudo usermod -a -G dialout $USER
# Restart session
```

**Arduino CLI not found:**
```bash
# The setup.sh script handles automatic installation
./scripts/setup.sh

# Or manual installation
curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
```

**esptool.py not found:**
```bash
pip install esptool
# Or use setup script
./scripts/setup.sh
```

### Scripts Compatibility

- **setup.sh**: Linux, macOS, WSL
- **flash.sh**: Linux, macOS, WSL

### Scripts Recommendations

1. **For daily development**: Use `make deploy`
2. **For initial setup**: Use `make setup` or `./scripts/setup.sh`
3. **For CI/CD**: Use make commands with configuration from `sketch.yaml`
4. **For debugging**: Individual scripts can be useful for step-by-step debugging

## Compilation and Deployment

### Option 1: Makefile (Recommended)

The project includes an optimized Makefile that uses `sketch.yaml` and `esptool.py` to facilitate development:

```bash
# View all available options
make help

# Typical development workflow
make setup              # Configure initial environment
make validate-sketch    # Validate configuration
make build              # Compile using zigbee_enddevice profile (cleans automatically)
make flash              # Flash to ESP32-C6 with esptool.py
make monitor            # Start serial monitor

# Compile and flash in a single command
make deploy

# Clean build files manually
make clean
```

**Makefile Advantages:**
- ✅ Automatically uses the `zigbee_enddevice` profile from `sketch.yaml`
- ✅ Includes all dependencies automatically
- ✅ **Automatic cleaning**: Cleans the `build/` directory before each compilation
- ✅ **esptool.py integrated**: Optimized flashing for ESP32-C6
- ✅ Automatically detects ports
- ✅ Automatically exports binaries
- ✅ Integrated configuration validation

**Available flashing options:**
```bash
make flash              # Flash complete firmware (.merged.bin) - Recommended
make flash-individual   # Flash individual files (bootloader, partitions, app)
```

### Option 2: Arduino CLI + direct esptool.py

```bash
# Compile using the profile defined in sketch.yaml
arduino-cli compile --profile zigbee_enddevice --board-options "ZigbeeMode=ed,PartitionScheme=zigbee" --export-binaries .

# Flash using esptool.py (recommended for ESP32-C6)
esptool.py --chip esp32c6 --port /dev/ttyUSB0 --baud 921600 erase_flash
esptool.py --chip esp32c6 --port /dev/ttyUSB0 --baud 921600 \
    --before default_reset --after hard_reset write_flash \
    --flash_mode dio --flash_freq 80m --flash_size 8MB \
    0x0 build/esp32.esp32.esp32c6/TemperatureHumidityZigbeeEndDevice.ino.merged.bin

# Upload using arduino-cli (alternative)
arduino-cli upload --profile zigbee_enddevice --port /dev/ttyUSB0 .
```

### Option 3: Traditional Scripts

```bash
# Linux/macOS
chmod +x scripts/setup.sh scripts/flash.sh
./scripts/setup.sh
./scripts/flash.sh
```

## Development Setup

### 1. Automatic Setup (Recommended)

```bash
make setup
```

### 2. Manual Setup

```bash
# Install Arduino CLI
curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh

# Configure Arduino CLI
arduino-cli config init
arduino-cli core update-index

# Install ESP32 platform
arduino-cli core install esp32:esp32@3.2.0

# Install required libraries
arduino-cli lib install "Adafruit SHT4x Library@1.0.0"
arduino-cli lib install "Adafruit BusIO@1.17.1"
arduino-cli lib install "Adafruit Unified Sensor@1.1.15"

# Install esptool.py
pip install esptool
```

## sketch.yaml File

The project uses a `sketch.yaml` file that defines:

- **zigbee_enddevice Profile**: Optimized configuration for ESP32-C6 with Zigbee
- **Platform**: ESP32 3.2.0 (includes native Zigbee support)
- **Dependencies**: All necessary libraries with specific versions
- **Automatic Export**: Binaries are exported automatically

## Hardware

### Required Components
- ESP32-C6 DevKit (or compatible)
- SHT40 Sensor
- Connection wires
- Breadboard (optional)

### Connections
```
ESP32-C6    SHT40
--------    -----
3V3    <--> VCC
GND    <--> GND
GPIO8  <--> SDA
GPIO9  <--> SCL
```

## Generated Files

Compilation generates several files in `build/esp32.esp32.esp32c6/`:

- **`*.merged.bin`**: **Complete firmware ready to flash (~4MB)** ⭐ **Main**
- **`*.bin`**: Application firmware (~588KB)
- **`*.bootloader.bin`**: Bootloader (~21KB)
- **`*.partitions.bin`**: Partition table (~3KB)
- **`*.elf`**: File with debug symbols (~8.3MB)

> 🔥 **Important**: The `*.merged.bin` file contains the complete firmware and is recommended for flashing with esptool.py.

## Flashing with esptool.py

### Advantages of using esptool.py over arduino-cli upload:

✅ **Better performance**: Optimized flashing speed for ESP32-C6
✅ **Granular control**: Specific flash configuration (mode, frequency, size)
✅ **merged.bin file**: A single file contains the entire firmware
✅ **Full erase**: Completely cleans the flash before flashing
✅ **Compatibility**: Works with any tool that generates merged.bin

### esptool.py Configuration:
```
Chip: esp32c6
Baud: 921600
Flash Mode: dio
Flash Frequency: 80MHz
Flash Size: 8MB
```

## Features

### SHT40 Sensor
- Temperature range: -40°C to +125°C
- Humidity range: 0-100% RH
- Accuracy: ±0.2°C, ±1.8% RH
- Interface: I2C

### Zigbee 3.0 End Device
- Protocol: Zigbee 3.0
- Mode: End Device (ED)
- Sleepy Device: Yes (for power saving)
- Mesh network: Full support

### Power Management
- Deep Sleep between readings
- Configurable periodic wake-up
- Battery optimized

## Troubleshooting

### Common Errors

**Error: "Zigbee.h not found"**
```bash
# Ensure you are using ESP32 3.2.0 or higher
arduino-cli core install esp32:esp32@3.2.0
```

**Error: "ZIGBEE_MODE_ED not defined"**
```bash
# Use correct board options
--board-options "ZigbeeMode=ed,PartitionScheme=zigbee"
```

**Error: "esptool.py not found"**
```bash
# Install esptool.py
pip install esptool
# Or use the Makefile
make install-deps
```

**Binary files of size 0**
```bash
# Compilation now cleans automatically, but if problems arise:
make clean
make build
```

**Flashing problems**
```bash
# Check port
make list-ports

# Try individual flashing if merged.bin fails
make flash-individual PORT=/dev/ttyUSB0

# Monitor for debugging
make monitor PORT=/dev/ttyUSB0
```

## Development Tools

### Useful Makefile Commands

```bash
make check-deps       # Check dependencies (includes esptool.py)
make validate-sketch  # Validate sketch.yaml
make list-ports      # List serial ports
make check-port      # Check detected port
make info            # Info of generated files (highlights merged.bin)
make show-config     # Show complete configuration (Arduino + esptool)
make clean-cache     # Clean Arduino CLI cache
make clean-build     # Clean only the build directory
```

### Optimized Development Workflow

```bash
# Initial setup (only once)
make setup

# Iterative development (automatic)
make deploy    # build + flash in one command

# Or step by step
make build     # Compiles (cleans automatically)
make flash     # Flashes with esptool.py
make monitor   # Serial monitor
```

### Serial Monitor

```bash
# Using Makefile
make monitor

# Using Arduino CLI
arduino-cli monitor --port /dev/ttyUSB0 --config 115200

# Using esptool.py (for advanced debugging)
python -m serial.tools.miniterm /dev/ttyUSB0 115200
```

## Contribution

1. Fork the project
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Commit changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Create a Pull Request

## License

This project is under the MIT license. See `LICENSE` for more details. 