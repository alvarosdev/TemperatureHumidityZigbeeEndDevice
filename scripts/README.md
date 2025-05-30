# Scripts de Compilación y Flasheo

Este directorio contiene scripts para compilar y flashear el proyecto main.ino en ESP32C6 en sistemas Unix (Linux/macOS).

## Estructura Actual

### Scripts de Shell (Linux/macOS)
- `build.sh` - Script de compilación para sistemas Unix
- `flash.sh` - Script de flasheo para sistemas Unix
- `build-and-flash.sh` - Script completo compilar + flashear

### Scripts de Configuración
- `setup.sh` - Script de configuración automática

### Makefile (Recomendado)
En la raíz del proyecto se encuentra un `Makefile` completo que implementa todas las funcionalidades de los scripts.

## Prerrequisitos

### 1. Arduino CLI
```bash
# Linux/macOS
curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh

# macOS con Homebrew
brew install arduino-cli
```

### 2. Python y esptool
```bash
# Linux
sudo apt-get install python3 python3-pip

# macOS
brew install python3
```

### 3. Core ESP32
```bash
arduino-cli core update-index
arduino-cli core install esp32:esp32
```

## Uso

### Opción 1: Makefile (Recomendado)

```bash
# Mostrar ayuda
make help

# Configurar entorno automáticamente
make setup

# Compilar proyecto
make build

# Flashear ESP32
make flash

# Compilar y flashear en un paso
make deploy

# Monitor serie
make monitor

# Limpiar archivos de build
make clean

# Listar puertos disponibles
make list-ports

# Flashear especificando puerto
make flash PORT=/dev/ttyUSB0
```

### Opción 2: Scripts Shell Unix

```bash
# Configuración inicial
./scripts/setup.sh

# Compilar, flashear, etc.
./scripts/build.sh
./scripts/flash.sh
./scripts/build-and-flash.sh
```

## Configuración

Los scripts utilizan la configuración definida en:
- `ci.json` - Configuración específica del ESP32C6 con Zigbee
- Board: `esp32:esp32:esp32c6`
- Opciones: `PartitionScheme=zigbee,ZigbeeMode=ed`

## Estructura de Build

Los archivos compilados se almacenan en:
```
build/
└── esp32.esp32.esp32c6/
    ├── main.ino.bootloader.bin
    ├── main.ino.partitions.bin
    ├── main.ino.bin
    └── otros archivos...
```

## Troubleshooting

### Error: arduino-cli no encontrado
- Instala Arduino CLI según tu sistema operativo
- Asegúrate de que esté en el PATH del sistema

### Error: Python no encontrado
- Instala Python según tu sistema operativo
- Asegúrate de que esté en el PATH

### Error: No se puede conectar al ESP32
- Verifica que el ESP32 esté conectado por USB
- Asegúrate de que no esté siendo usado por otro programa
- Prueba poner el ESP32 en modo de descarga manualmente (mantén presionado BOOT mientras presionas RESET)
- En Linux, asegúrate de tener permisos para acceder al puerto serie:
  ```bash
  sudo usermod -a -G dialout $USER
  # Luego cierra sesión y vuelve a iniciarla
  ```

### Error: Archivos binarios no encontrados
- Ejecuta primero el script de compilación antes del flasheo
- Verifica que la compilación haya sido exitosa

## Ventajas del Makefile

1. **Simplicidad**: Un solo comando para cada tarea
2. **Autodetección**: Detecta automáticamente puertos y dependencias
3. **Colores**: Output con colores para mejor legibilidad
4. **Validaciones**: Verifica dependencias y archivos antes de ejecutar
5. **Flexibilidad**: Permite especificar parámetros personalizados
6. **Monitor integrado**: Incluye monitor serie
7. **Help integrado**: `make help` muestra todas las opciones 