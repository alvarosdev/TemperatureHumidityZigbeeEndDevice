# Makefile for ESP32C6 - Temperature and Humidity Sensor with Zigbee
# Optimized to use sketch.yaml and arduino-cli with profiles

# Main configuration variables
SKETCH_PATH := .
SKETCH_YAML := sketch.yaml
PROFILE := zigbee_enddevice
BUILD_PATH := build
CHIP := esp32c6
BAUD := 921600

# Board configuration (alternative if not using profile)
BOARD_FQBN := esp32:esp32:esp32c6
BOARD_OPTIONS := ZigbeeMode=ed,PartitionScheme=zigbee

# Binary files (new structure)
BUILD_DIR := $(BUILD_PATH)/esp32.esp32.esp32c6
BOOTLOADER_BIN := $(BUILD_DIR)/TemperatureHumidityZigbeeEndDevice.ino.bootloader.bin
PARTITIONS_BIN := $(BUILD_DIR)/TemperatureHumidityZigbeeEndDevice.ino.partitions.bin
APP_BIN := $(BUILD_DIR)/TemperatureHumidityZigbeeEndDevice.ino.bin
MERGED_BIN := $(BUILD_DIR)/TemperatureHumidityZigbeeEndDevice.ino.merged.bin
ELF_FILE := $(BUILD_DIR)/TemperatureHumidityZigbeeEndDevice.ino.elf

# Configuration for esptool.py (ESP32-C6)
ESPTOOL_CHIP := esp32c6
ESPTOOL_BAUD := 921600
FLASH_MODE := dio
FLASH_FREQ := 80m
FLASH_SIZE := 8MB

# Memory addresses for ESP32-C6
BOOTLOADER_ADDR := 0x0
PARTITION_ADDR := 0x8000
APP_ADDR := 0x10000

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
CYAN := \033[0;36m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Automatic port detection
PORT := $(shell \
	if [ -e /dev/ttyUSB0 ]; then \
		echo "/dev/ttyUSB0"; \
	elif [ -e /dev/ttyACM0 ]; then \
		echo "/dev/ttyACM0"; \
	elif ls /dev/cu.usbserial* 1> /dev/null 2>&1; then \
		ls /dev/cu.usbserial* | head -n1; \
	elif ls /dev/cu.SLAB_USBtoUART* 1> /dev/null 2>&1; then \
		ls /dev/cu.SLAB_USBtoUART* | head -n1; \
	else \
		echo ""; \
	fi)

# Default targets
.PHONY: all build build-profile build-manual flash flash-merged flash-individual clean setup help install-deps check-deps check-port list-ports monitor deploy info validate-sketch clean-build

# Default target
all: build

help: ## Show this help
	@echo -e "$(CYAN)============================================$(NC)"
	@echo -e "$(CYAN)  ESP32-C6 Zigbee Temperature Sensor$(NC)"
	@echo -e "$(CYAN)============================================$(NC)"
	@echo -e ""
	@echo -e "$(GREEN)Main commands:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo -e ""
	@echo -e "$(GREEN)Configurable variables:$(NC)"
	@echo -e "  $(YELLOW)PROFILE$(NC)        = $(PROFILE) (sketch.yaml profile)"
	@echo -e "  $(YELLOW)BUILD_PATH$(NC)     = $(BUILD_PATH)"
	@echo -e "  $(YELLOW)PORT$(NC)           = $(if $(PORT),$(PORT),auto-detect)"
	@echo -e "  $(YELLOW)BAUD$(NC)           = $(BAUD)"
	@echo -e "  $(YELLOW)CHIP$(NC)           = $(ESPTOOL_CHIP)"
	@echo -e ""
	@echo -e "$(GREEN)Typical usage:$(NC)"
	@echo -e "  1. $(CYAN)make setup$(NC)          # Configure initial environment"
	@echo -e "  2. $(CYAN)make validate-sketch$(NC) # Validate sketch.yaml"
	@echo -e "  3. $(CYAN)make build$(NC)          # Compile using profile (cleans automatically)"
	@echo -e "  4. $(CYAN)make flash$(NC)          # Flash to ESP32-C6 with esptool.py"
	@echo -e "  5. $(CYAN)make monitor$(NC)        # Serial monitor"
	@echo -e ""
	@echo -e "$(BLUE)Alternative compilation:$(NC)"
	@echo -e "  $(CYAN)make build-manual$(NC)      # Compile without profile (manual)"
	@echo -e ""
	@echo -e "$(BLUE)Flashing options:$(NC)"
	@echo -e "  $(CYAN)make flash$(NC)             # Flash complete firmware (.merged.bin)"
	@echo -e "  $(CYAN)make flash-individual$(NC)  # Flash individual files"

# ===========================
# Verification and Setup
# ===========================

check-deps: ## Check that all dependencies are installed
	@echo -e "$(CYAN)========================================$(NC)"
	@echo -e "$(CYAN)Checking dependencies...$(NC)"
	@echo -e "$(CYAN)========================================$(NC)"
	@command -v arduino-cli >/dev/null 2>&1 || (echo "$(RED)ERROR: arduino-cli is not installed$(NC)" && exit 1)
	@command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1 || (echo "$(RED)ERROR: Python is not installed$(NC)" && exit 1)
	@command -v esptool.py >/dev/null 2>&1 || (echo "$(RED)ERROR: esptool.py is not installed$(NC)" && echo "$(YELLOW)Install with: pip install esptool$(NC)" && exit 1)
	@echo -e "$(GREEN)✓ arduino-cli available$(NC)"
	@echo -e "$(GREEN)✓ Python available$(NC)"
	@echo -e "$(GREEN)✓ esptool.py available$(NC)"
	@echo -e "$(GREEN)✓ All dependencies are available$(NC)"

validate-sketch: ## Validate sketch.yaml file
	@echo -e "$(CYAN)========================================$(NC)"
	@echo -e "$(CYAN)Validating sketch.yaml...$(NC)"
	@echo -e "$(CYAN)========================================$(NC)"
	@if [ ! -f "$(SKETCH_YAML)" ]; then \
		echo -e "$(RED)ERROR: $(SKETCH_YAML) not found$(NC)"; \
		exit 1; \
	fi
	@echo -e "$(GREEN)✓ sketch.yaml found$(NC)"
	@echo -e "$(YELLOW)Available profiles:$(NC)"
	@grep -A 1 "profiles:" $(SKETCH_YAML) | grep -v "profiles:" | grep -E "^ *[a-zA-Z]" | sed 's/://' | sed 's/^/  /'
	@echo -e "$(GREEN)✓ Profile '$(PROFILE)' configured$(NC)"

setup: check-deps ## Execute automatic configuration script
	@echo -e "$(CYAN)Running automatic configuration...$(NC)"
	@if [ -f "./scripts/setup.sh" ]; then \
		chmod +x ./scripts/setup.sh && ./scripts/setup.sh; \
	else \
		echo -e "$(RED)ERROR: scripts/setup.sh not found$(NC)"; \
		echo -e "$(YELLOW)Run manually: arduino-cli core install esp32:esp32$(NC)"; \
		exit 1; \
	fi

install-deps: ## Install basic dependencies (requires sudo permissions on Linux)
	@echo -e "$(CYAN)========================================$(NC)"
	@echo -e "$(CYAN)Installing dependencies...$(NC)"
	@echo -e "$(CYAN)========================================$(NC)"
	@if [[ "$$OSTYPE" == "linux-gnu"* ]]; then \
		echo "Detected: Linux"; \
		if command -v apt-get >/dev/null 2>&1; then \
			sudo apt-get update && sudo apt-get install -y python3 python3-pip curl; \
		elif command -v yum >/dev/null 2>&1; then \
			sudo yum install -y python3 python3-pip curl; \
		elif command -v pacman >/dev/null 2>&1; then \
			sudo pacman -S python python-pip curl; \
		fi; \
		curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh; \
		export PATH="$$PATH:$$HOME/bin"; \
	elif [[ "$$OSTYPE" == "darwin"* ]]; then \
		echo "Detected: macOS"; \
		if command -v brew >/dev/null 2>&1; then \
			brew install python3 arduino-cli; \
		else \
			echo "$(YELLOW)Please install Homebrew first: https://brew.sh$(NC)"; \
		fi; \
	fi
	@echo -e "$(YELLOW)Installing esptool.py...$(NC)"
	@pip3 install esptool || pip install esptool
	@echo -e "$(GREEN)✓ Dependencies installed$(NC)"

# ===========================
# Compilation using sketch.yaml
# ===========================

clean-build: ## Clean build files
	@echo -e "$(YELLOW)Cleaning previous build files...$(NC)"
	@rm -rf $(BUILD_PATH)
	@echo -e "$(GREEN)✓ Build directory cleaned$(NC)"

build: clean-build validate-sketch build-profile ## Compile using sketch.yaml profile (recommended) - cleans automatically

build-profile: check-deps validate-sketch ## Compile using the profile defined in sketch.yaml
	@echo -e "$(CYAN)========================================$(NC)"
	@echo -e "$(CYAN)Compiling with profile: $(PROFILE)$(NC)"
	@echo -e "$(CYAN)========================================$(NC)"
	@echo -e "$(GREEN)Configuration:$(NC)"
	@echo -e "  $(YELLOW)Sketch:$(NC) $(SKETCH_PATH)"
	@echo -e "  $(YELLOW)Profile:$(NC) $(PROFILE)"
	@echo -e "  $(YELLOW)Config:$(NC) $(SKETCH_YAML)"
	@echo -e "  $(YELLOW)Board Options:$(NC) $(BOARD_OPTIONS)"
	@echo -e ""
	arduino-cli compile \
		--profile $(PROFILE) \
		--board-options "$(BOARD_OPTIONS)" \
		--export-binaries \
		$(SKETCH_PATH)
	@echo -e ""
	@echo -e "$(GREEN)✓ Compilation completed successfully$(NC)"
	@$(MAKE) info

build-manual: clean-build check-deps ## Compile manually without using profile (alternative) - cleans automatically
	@echo -e "$(CYAN)========================================$(NC)"
	@echo -e "$(CYAN)Manual compilation (without profile)$(NC)"
	@echo -e "$(CYAN)========================================$(NC)"
	@echo -e "$(GREEN)Configuration:$(NC)"
	@echo -e "  $(YELLOW)FQBN:$(NC) $(BOARD_FQBN)"
	@echo -e "  $(YELLOW)Options:$(NC) $(BOARD_OPTIONS)"
	@echo -e ""
	arduino-cli compile \
		--fqbn "$(BOARD_FQBN):$(BOARD_OPTIONS)" \
		--export-binaries \
		$(SKETCH_PATH)
	@echo -e ""
	@echo -e "$(GREEN)✓ Manual compilation completed$(NC)"
	@$(MAKE) info

info: ## Show information about generated files
	@echo -e "$(GREEN)Generated files:$(NC)"
	@if [ -d "$(BUILD_DIR)" ]; then \
		ls -lh $(BUILD_DIR)/*.bin $(BUILD_DIR)/*.elf 2>/dev/null | while read line; do \
			echo -e "  $(BLUE)$$line$(NC)"; \
		done; \
		echo -e ""; \
		echo -e "$(GREEN)Main file for flashing:$(NC)"; \
		if [ -f "$(MERGED_BIN)" ]; then \
			echo -e "  $(CYAN)$(MERGED_BIN)$(NC)"; \
		else \
			echo -e "  $(RED)$(MERGED_BIN) not found$(NC)"; \
		fi; \
	else \
		echo -e "  $(YELLOW)No files found in $(BUILD_DIR)$(NC)"; \
	fi

# ===========================
# Flash and Upload with esptool.py
# ===========================

check-port: ## Check port connection
	@echo -e "$(CYAN)========================================$(NC)"
	@echo -e "$(CYAN)Checking port...$(NC)"
	@echo -e "$(CYAN)========================================$(NC)"
	@if [ -z "$(PORT)" ]; then \
		echo -e "$(RED)ERROR: No port detected automatically$(NC)"; \
		echo -e "$(YELLOW)Available ports:$(NC)"; \
		ls /dev/tty* 2>/dev/null | grep -E "(USB|ACM|usbserial|SLAB)" || echo "  None found"; \
		echo -e "$(YELLOW)Specify manually: make flash PORT=/dev/ttyUSB0$(NC)"; \
		exit 1; \
	else \
		echo -e "$(GREEN)Port detected: $(PORT)$(NC)"; \
	fi

list-ports: ## List available ports
	@echo -e "$(CYAN)========================================$(NC)"
	@echo -e "$(CYAN)Available serial ports:$(NC)"
	@echo -e "$(CYAN)========================================$(NC)"
	@ls /dev/tty* 2>/dev/null | grep -E "(USB|ACM|usbserial|SLAB)" || echo "$(YELLOW)No serial ports found$(NC)"

flash: flash-merged ## Flash to ESP32-C6 using esptool.py (merged.bin file)

flash-merged: ## Flash complete firmware using merged.bin with esptool.py
	@if [ ! -f "$(MERGED_BIN)" ]; then \
		echo -e "$(RED)ERROR: merged.bin file not found$(NC)"; \
		echo -e "$(YELLOW)Run 'make build' first$(NC)"; \
		exit 1; \
	fi
	@if [ -z "$(PORT)" ] && [ -z "$$PORT" ]; then \
		echo -e "$(RED)ERROR: Port not specified$(NC)"; \
		echo -e "$(YELLOW)Use: make flash PORT=/dev/ttyUSB0$(NC)"; \
		exit 1; \
	fi
	@echo -e "$(CYAN)========================================$(NC)"
	@echo -e "$(CYAN)Flashing ESP32-C6 with esptool.py$(NC)"
	@echo -e "$(CYAN)========================================$(NC)"
	@echo -e "$(GREEN)Configuration:$(NC)"
	@echo -e "  $(YELLOW)Port:$(NC) $(if $(PORT),$(PORT),$$PORT)"
	@echo -e "  $(YELLOW)Chip:$(NC) $(ESPTOOL_CHIP)"
	@echo -e "  $(YELLOW)Baud:$(NC) $(ESPTOOL_BAUD)"
	@echo -e "  $(YELLOW)File:$(NC) $(MERGED_BIN)"
	@echo -e "  $(YELLOW)Size:$(NC) $$(ls -lh $(MERGED_BIN) | awk '{print $$5}')"
	@echo -e ""
	@echo -e "$(YELLOW)Erasing flash...$(NC)"
	esptool.py --chip $(ESPTOOL_CHIP) --port $(if $(PORT),$(PORT),$$PORT) --baud $(ESPTOOL_BAUD) erase_flash
	@echo -e ""
	@echo -e "$(YELLOW)Flashing complete firmware...$(NC)"
	esptool.py --chip $(ESPTOOL_CHIP) --port $(if $(PORT),$(PORT),$$PORT) --baud $(ESPTOOL_BAUD) \
		--before default_reset --after hard_reset write_flash \
		--flash_mode $(FLASH_MODE) --flash_freq $(FLASH_FREQ) --flash_size $(FLASH_SIZE) \
		0x0 $(MERGED_BIN)
	@echo -e ""
	@echo -e "$(GREEN)✓ Flashing completed successfully$(NC)"

flash-individual: ## Flash individual files (bootloader, partitions, app) with esptool.py
	@if [ ! -f "$(BOOTLOADER_BIN)" ] || [ ! -f "$(PARTITIONS_BIN)" ] || [ ! -f "$(APP_BIN)" ]; then \
		echo -e "$(RED)ERROR: Binary files not found$(NC)"; \
		echo -e "$(YELLOW)Run 'make build' first$(NC)"; \
		exit 1; \
	fi
	@if [ -z "$(PORT)" ] && [ -z "$$PORT" ]; then \
		echo -e "$(RED)ERROR: Port not specified$(NC)"; \
		echo -e "$(YELLOW)Use: make flash-individual PORT=/dev/ttyUSB0$(NC)"; \
		exit 1; \
	fi
	@echo -e "$(CYAN)========================================$(NC)"
	@echo -e "$(CYAN)Flashing ESP32-C6 (individual files)$(NC)"
	@echo -e "$(CYAN)========================================$(NC)"
	@echo -e "$(GREEN)Configuration:$(NC)"
	@echo -e "  $(YELLOW)Port:$(NC) $(if $(PORT),$(PORT),$$PORT)"
	@echo -e "  $(YELLOW)Chip:$(NC) $(ESPTOOL_CHIP)"
	@echo -e "  $(YELLOW)Baud:$(NC) $(ESPTOOL_BAUD)"
	@echo -e ""
	@echo -e "$(GREEN)Files to flash:$(NC)"
	@echo -e "  $(YELLOW)Bootloader:$(NC) $(BOOTLOADER_BIN) -> $(BOOTLOADER_ADDR)"
	@echo -e "  $(YELLOW)Partitions:$(NC) $(PARTITIONS_BIN) -> $(PARTITION_ADDR)"
	@echo -e "  $(YELLOW)App:$(NC) $(APP_BIN) -> $(APP_ADDR)"
	@echo -e ""
	@echo -e "$(YELLOW)Erasing flash...$(NC)"
	esptool.py --chip $(ESPTOOL_CHIP) --port $(if $(PORT),$(PORT),$$PORT) --baud $(ESPTOOL_BAUD) erase_flash
	@echo -e ""
	@echo -e "$(YELLOW)Flashing individual files...$(NC)"
	esptool.py --chip $(ESPTOOL_CHIP) --port $(if $(PORT),$(PORT),$$PORT) --baud $(ESPTOOL_BAUD) \
		--before default_reset --after hard_reset write_flash \
		--flash_mode $(FLASH_MODE) --flash_freq $(FLASH_FREQ) --flash_size $(FLASH_SIZE) \
		$(BOOTLOADER_ADDR) $(BOOTLOADER_BIN) \
		$(PARTITION_ADDR) $(PARTITIONS_BIN) \
		$(APP_ADDR) $(APP_BIN)
	@echo -e ""
	@echo -e "$(GREEN)✓ Individual flashing completed successfully$(NC)"

deploy: build flash ## Compile and flash in a single command

monitor: ## Start serial monitor
	@if [ -z "$(PORT)" ] && [ -z "$$PORT" ]; then \
		echo -e "$(RED)ERROR: Port not specified$(NC)"; \
		echo -e "$(YELLOW)Use: make monitor PORT=/dev/ttyUSB0$(NC)"; \
		exit 1; \
	fi
	@echo -e "$(CYAN)========================================$(NC)"
	@echo -e "$(CYAN)Serial Monitor - Port: $(if $(PORT),$(PORT),$$PORT)$(NC)"
	@echo -e "$(CYAN)========================================$(NC)"
	@echo -e "$(YELLOW)Press Ctrl+C to exit$(NC)"
	@echo -e ""
	arduino-cli monitor --port $(if $(PORT),$(PORT),$$PORT) --config 115200

# ===========================
# Utilities
# ===========================

clean: ## Clean build files
	@echo -e "$(YELLOW)Cleaning build files...$(NC)"
	@rm -rf $(BUILD_PATH)
	@echo -e "$(GREEN)✓ Cleanup completed$(NC)"

clean-cache: ## Clean Arduino CLI cache
	@echo -e "$(YELLOW)Cleaning Arduino CLI cache...$(NC)"
	@arduino-cli cache clean
	@echo -e "$(GREEN)✓ Cache cleaned$(NC)"

# ===========================
# Information and debug
# ===========================

show-config: ## Show current configuration
	@echo -e "$(CYAN)========================================$(NC)"
	@echo -e "$(CYAN)Current configuration$(NC)"
	@echo -e "$(CYAN)========================================$(NC)"
	@echo -e "$(GREEN)Paths:$(NC)"
	@echo -e "  $(YELLOW)SKETCH_PATH$(NC)    = $(SKETCH_PATH)"
	@echo -e "  $(YELLOW)SKETCH_YAML$(NC)    = $(SKETCH_YAML)"
	@echo -e "  $(YELLOW)BUILD_PATH$(NC)     = $(BUILD_PATH)"
	@echo -e "  $(YELLOW)BUILD_DIR$(NC)      = $(BUILD_DIR)"
	@echo -e ""
	@echo -e "$(GREEN)Arduino configuration:$(NC)"
	@echo -e "  $(YELLOW)PROFILE$(NC)        = $(PROFILE)"
	@echo -e "  $(YELLOW)BOARD_FQBN$(NC)     = $(BOARD_FQBN)"
	@echo -e "  $(YELLOW)BOARD_OPTIONS$(NC)  = $(BOARD_OPTIONS)"
	@echo -e ""
	@echo -e "$(GREEN)esptool.py configuration:$(NC)"
	@echo -e "  $(YELLOW)ESPTOOL_CHIP$(NC)   = $(ESPTOOL_CHIP)"
	@echo -e "  $(YELLOW)ESPTOOL_BAUD$(NC)   = $(ESPTOOL_BAUD)"
	@echo -e "  $(YELLOW)FLASH_MODE$(NC)     = $(FLASH_MODE)"
	@echo -e "  $(YELLOW)FLASH_FREQ$(NC)     = $(FLASH_FREQ)"
	@echo -e "  $(YELLOW)FLASH_SIZE$(NC)     = $(FLASH_SIZE)"
	@echo -e "  $(YELLOW)PORT$(NC)           = $(if $(PORT),$(PORT),auto-detect)"
	@echo -e ""
	@echo -e "$(GREEN)Target files:$(NC)"
	@echo -e "  $(YELLOW)MERGED_BIN$(NC)     = $(MERGED_BIN)"
	@echo -e "  $(YELLOW)APP_BIN$(NC)        = $(APP_BIN)"
	@echo -e "  $(YELLOW)BOOTLOADER_BIN$(NC) = $(BOOTLOADER_BIN)"
	@echo -e "  $(YELLOW)PARTITIONS_BIN$(NC) = $(PARTITIONS_BIN)"
	@echo -e "  $(YELLOW)ELF_FILE$(NC)       = $(ELF_FILE)" 