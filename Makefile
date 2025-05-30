# Makefile para ESP32C6 - Sensor de Humedad y Temperatura
# Basado en los scripts de shell para Linux/macOS

# Variables de configuración
BOARD := esp32:esp32:esp32c6
SKETCH_PATH := .
BUILD_PATH := build
CONFIG_FILE := ci.json
CHIP := esp32c6
BAUD := 921600

# Archivos binarios
BUILD_DIR := $(BUILD_PATH)/esp32.esp32.esp32c6
BOOTLOADER_BIN := $(BUILD_DIR)/main.ino.bootloader.bin
PARTITIONS_BIN := $(BUILD_DIR)/main.ino.partitions.bin
APP_BIN := $(BUILD_DIR)/main.ino.bin

# Colores para output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
CYAN := \033[0;36m
NC := \033[0m # No Color

# Detección automática del puerto
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

# Targets por defecto
.PHONY: all build flash clean setup help install-deps check-deps check-port list-ports

# Target por defecto
all: build

help: ## Mostrar esta ayuda
	@echo "$(CYAN)========================================$(NC)"
	@echo "$(CYAN)Makefile para ESP32C6 - HumiTempSensor$(NC)"
	@echo "$(CYAN)========================================$(NC)"
	@echo ""
	@echo "Targets disponibles:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "Variables:"
	@echo "  $(YELLOW)BOARD$(NC)      = $(BOARD)"
	@echo "  $(YELLOW)BUILD_PATH$(NC) = $(BUILD_PATH)"
	@echo "  $(YELLOW)PORT$(NC)       = $(if $(PORT),$(PORT),auto-detect)"
	@echo "  $(YELLOW)BAUD$(NC)       = $(BAUD)"

check-deps: ## Verificar que todas las dependencias estén instaladas
	@echo "$(CYAN)========================================$(NC)"
	@echo "$(CYAN)Verificando dependencias...$(NC)"
	@echo "$(CYAN)========================================$(NC)"
	@command -v arduino-cli >/dev/null 2>&1 || (echo "$(RED)ERROR: arduino-cli no está instalado$(NC)" && exit 1)
	@command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1 || (echo "$(RED)ERROR: Python no está instalado$(NC)" && exit 1)
	@echo "$(GREEN)✓ Todas las dependencias están disponibles$(NC)"

setup: ## Ejecutar script de configuración automática
	@echo "$(CYAN)Ejecutando configuración automática...$(NC)"
	@./scripts/setup.sh

install-deps: ## Instalar dependencias básicas (requiere permisos sudo en Linux)
	@echo "$(CYAN)========================================$(NC)"
	@echo "$(CYAN)Instalando dependencias...$(NC)"
	@echo "$(CYAN)========================================$(NC)"
	@if [[ "$$OSTYPE" == "linux-gnu"* ]]; then \
		echo "Detectado: Linux"; \
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
		echo "Detectado: macOS"; \
		if command -v brew >/dev/null 2>&1; then \
			brew install python3 arduino-cli; \
		else \
			echo "$(YELLOW)Por favor instala Homebrew primero: https://brew.sh$(NC)"; \
		fi; \
	fi

$(BUILD_PATH): ## Crear directorio de build
	@mkdir -p $(BUILD_PATH)

build: check-deps $(BUILD_PATH) ## Compilar el proyecto
	@echo "$(CYAN)========================================$(NC)"
	@echo "$(CYAN)Compilando main.ino$(NC)"
	@echo "$(CYAN)========================================$(NC)"
	@echo "FQBN: $(BOARD)"
	@echo "Ruta del sketch: $(SKETCH_PATH)"
	@echo "Ruta de build: $(BUILD_PATH)"
	@echo ""
	@echo "$(GREEN)Compilando sketch...$(NC)"
	@arduino-cli compile --fqbn "$(BOARD)" --build-path "$(BUILD_PATH)" --config-file "$(CONFIG_FILE)" "$(SKETCH_PATH)"
	@if [ $$? -eq 0 ]; then \
		echo ""; \
		echo "$(GREEN)========================================$(NC)"; \
		echo "$(GREEN)✓ Compilación exitosa$(NC)"; \
		echo "$(GREEN)========================================$(NC)"; \
		echo "Los archivos binarios están en: $(BUILD_PATH)"; \
	else \
		echo ""; \
		echo "$(RED)========================================$(NC)"; \
		echo "$(RED)✗ Error en la compilación$(NC)"; \
		echo "$(RED)========================================$(NC)"; \
		exit 1; \
	fi

check-binaries: ## Verificar que los archivos binarios existen
	@if [ ! -f "$(BOOTLOADER_BIN)" ] || [ ! -f "$(PARTITIONS_BIN)" ] || [ ! -f "$(APP_BIN)" ]; then \
		echo "$(RED)ERROR: No se encontraron los archivos binarios necesarios$(NC)"; \
		echo "Por favor ejecuta: make build"; \
		exit 1; \
	fi

check-port: ## Verificar/detectar puerto del ESP32
	@if [ -z "$(PORT)" ]; then \
		echo "$(RED)ERROR: No se pudo detectar automáticamente el puerto del ESP32$(NC)"; \
		echo "Puertos disponibles:"; \
		ls /dev/tty* 2>/dev/null | grep -E "(USB|ACM|usbserial|SLAB)" || echo "Ningún puerto encontrado"; \
		echo ""; \
		echo "Especifica el puerto manualmente: make flash PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	@echo "$(GREEN)Puerto detectado: $(PORT)$(NC)"

list-ports: ## Listar puertos serie disponibles
	@echo "$(CYAN)Puertos serie disponibles:$(NC)"
	@ls /dev/tty* 2>/dev/null | grep -E "(USB|ACM|usbserial|SLAB)" || echo "Ningún puerto encontrado"

install-esptool: ## Instalar esptool si no está disponible
	@if command -v python3 >/dev/null 2>&1; then \
		PYTHON_CMD="python3"; \
	elif command -v python >/dev/null 2>&1; then \
		PYTHON_CMD="python"; \
	else \
		echo "$(RED)ERROR: Python no está disponible$(NC)"; \
		exit 1; \
	fi; \
	if ! $$PYTHON_CMD -c "import esptool" 2>/dev/null; then \
		echo "$(YELLOW)esptool no está instalado. Instalando...$(NC)"; \
		$$PYTHON_CMD -m pip install esptool --user; \
	fi

flash: check-deps check-binaries check-port install-esptool ## Flashear el ESP32
	@echo "$(CYAN)========================================$(NC)"
	@echo "$(CYAN)Flasheando ESP32C6$(NC)"
	@echo "$(CYAN)========================================$(NC)"
	@echo "Puerto: $(PORT)"
	@echo "Archivos a flashear:"
	@echo "  Bootloader: $(BOOTLOADER_BIN)"
	@echo "  Partitions: $(PARTITIONS_BIN)"
	@echo "  App: $(APP_BIN)"
	@echo ""
	@echo "$(GREEN)Iniciando flasheo...$(NC)"
	@if command -v python3 >/dev/null 2>&1; then \
		PYTHON_CMD="python3"; \
	else \
		PYTHON_CMD="python"; \
	fi; \
	$$PYTHON_CMD -m esptool --chip $(CHIP) --port "$(PORT)" --baud $(BAUD) \
		--before default_reset --after hard_reset write_flash -z \
		--flash_mode dio --flash_freq 80m --flash_size 8MB \
		0x0 "$(BOOTLOADER_BIN)" \
		0x8000 "$(PARTITIONS_BIN)" \
		0x10000 "$(APP_BIN)"
	@if [ $$? -eq 0 ]; then \
		echo ""; \
		echo "$(GREEN)========================================$(NC)"; \
		echo "$(GREEN)✓ Flasheo exitoso$(NC)"; \
		echo "$(GREEN)========================================$(NC)"; \
	else \
		echo ""; \
		echo "$(RED)========================================$(NC)"; \
		echo "$(RED)✗ Error en el flasheo$(NC)"; \
		echo "$(RED)========================================$(NC)"; \
		exit 1; \
	fi

deploy: build flash ## Compilar y flashear en un solo paso
	@echo "$(GREEN)========================================$(NC)"
	@echo "$(GREEN)✓ Proceso completo exitoso$(NC)"
	@echo "$(GREEN)========================================$(NC)"
	@echo "El ESP32C6 ha sido compilado y flasheado correctamente"

monitor: check-port ## Abrir monitor serie
	@echo "$(CYAN)========================================$(NC)"
	@echo "$(CYAN)Monitor Serie - ESP32C6$(NC)"
	@echo "$(CYAN)========================================$(NC)"
	@echo "Puerto: $(PORT)"
	@echo "Presiona Ctrl+C para salir"
	@echo ""
	@arduino-cli monitor -p "$(PORT)" -c baudrate=115200

clean: ## Limpiar archivos de build
	@echo "$(YELLOW)Limpiando archivos de build...$(NC)"
	@rm -rf $(BUILD_PATH)
	@echo "$(GREEN)✓ Archivos de build eliminados$(NC)"

# Target especial para forzar un puerto específico
flash-port: ## Flashear especificando puerto manualmente (uso: make flash-port PORT=/dev/ttyUSB0)
	@if [ -z "$(PORT)" ]; then \
		echo "$(RED)ERROR: Debes especificar un puerto$(NC)"; \
		echo "Uso: make flash-port PORT=/dev/ttyUSB0"; \
		exit 1; \
	fi
	@$(MAKE) flash PORT=$(PORT)

# Targets de conveniencia que llaman a los scripts
build-script: ## Ejecutar script de compilación
	@./scripts/build.sh

flash-script: ## Ejecutar script de flasheo
	@./scripts/flash.sh

deploy-script: ## Ejecutar script de compilar y flashear
	@./scripts/build-and-flash.sh 