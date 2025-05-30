# AlvarosDev - Sensor de Temperatura y Humedad Zigbee (HumiTempSensor)

Este proyecto está **basado en el ejemplo oficial de Zigbee Temperature Sensor para ESP32-C6** de Espressif, pero incluye **modificaciones propias significativas** para implementar un sensor de temperatura y humedad real usando el sensor SHT4x, con funcionalidades avanzadas de gestión de energía y validación de datos.

## 🚀 Características Propias Implementadas

### Modificaciones sobre el ejemplo base:
- **Sensor real SHT4x**: Reemplaza la lectura de temperatura interna del chip por un sensor SHT4x de alta precisión
- **Dual sensing**: Implementación completa de temperatura Y humedad (el ejemplo original solo manejaba temperatura)
- **Gestión avanzada de energía**: Sistema de deep sleep configurable con wake-up por timer
- **Validación de datos**: Verificación de rangos válidos y detección de lecturas NaN
- **Factory Reset**: Funcionalidad de reset por botón (10 segundos presionado)
- **Configuración personalizada**: Parámetros organizados y documentados para fácil modificación
- **Manejo de errores robusto**: Reintentos y recuperación ante fallos
- **Logging detallado**: Sistema de debug con emojis y formato estructurado

## 🎯 Funcionalidades del Sensor

1. **Medición precisa**: Temperatura y humedad usando sensor SHT4x con alta precisión
2. **Conectividad Zigbee**: Reporta datos como dispositivo end-device en red Zigbee HA
3. **Ahorro de energía**: Modo deep sleep entre lecturas (configurable)
4. **Auto-recuperación**: Manejo de fallos de conexión y reinicio automático
5. **Configuración flexible**: Parámetros fácilmente modificables

# Objetivos Cumplidos

| Supported Targets | ESP32-C6 | ESP32-H2 |
| ----------------- | -------- | -------- |

## 🔧 Hardware Requerido

* **ESP32-C6** development board (recomendado)
* **Sensor SHT4x** (SHT40, SHT41, SHT45)
* Conexiones I2C:
  - SDA: GPIO 1
  - SCL: GPIO 2
* Cable USB para alimentación y programación

## ⚙️ Configuración del Proyecto

### Configuración de Hardware
- **Sensor SHT4x**: Conectado por I2C (pines 1 y 2)
- **Botón**: Utiliza el botón BOOT para factory reset
- **Precisión**: Configurado en modo HIGH_PRECISION
- **Heater**: Deshabilitado por defecto

### Parámetros Configurables (en el código)
```cpp
#define TIME_TO_SLEEP 60              // Tiempo de sleep en segundos
#define ENABLE_SLEEP true             // Habilitar/deshabilitar deep sleep
#define TEMP_MIN -40.0               // Rango mínimo temperatura
#define TEMP_MAX 125.0               // Rango máximo temperatura
#define HUMIDITY_MIN 0.0             // Rango mínimo humedad
#define HUMIDITY_MAX 100.0           // Rango máximo humedad
```

### Configuración en Arduino IDE

1. **Seleccionar placa**: `Tools -> Board -> ESP32-C6 Dev Module`
2. **Modo Zigbee**: `Tools -> Zigbee mode: Zigbee ED (end device)`
3. **Partición**: `Tools -> Partition Scheme: Zigbee 4MB with spiffs`
4. **Puerto**: `Tools -> Port: xxx` (puerto COM detectado)
5. **Debug opcional**: `Tools -> Core Debug Level: Verbose`

### Dependencias Requeridas
```json
// Librerías necesarias (instalar desde Library Manager)
- Adafruit SHT4x Library
- Zigbee Library (incluida en ESP32 core)
```

## 🔄 Funcionamiento

1. **Inicialización**: Configura sensor SHT4x y stack Zigbee
2. **Conexión**: Se conecta automáticamente a la red Zigbee
3. **Lectura**: Lee temperatura y humedad del sensor SHT4x
4. **Validación**: Verifica que los datos estén en rangos válidos
5. **Reporte**: Envía datos a la red Zigbee como dispositivo HA
6. **Sleep**: Entra en deep sleep por el tiempo configurado
7. **Repetición**: Wake-up automático y repetición del ciclo

## 🛠️ Solución de Problemas

### Conexión Zigbee
Si el dispositivo no se conecta al coordinador:
* Borra la flash: `Tools -> Erase All Flash Before Sketch Upload: Enabled`
* Agrega `Zigbee.factoryReset();` al código para reset completo
* Verifica que la red del coordinador esté abierta

### Sensor SHT4x
* **Error "SHT4x sensor not found"**: Verifica conexiones I2C (pines 1 y 2)
* **Datos inválidos**: Verifica alimentación del sensor (3.3V)
* **Lecturas erráticas**: Aumenta el tiempo de estabilización

### Gestión de Energía
* **No entra en sleep**: Verifica `ENABLE_SLEEP true` en configuración
* **Wake-up no funciona**: Revisa configuración del timer de wake-up

### Factory Reset
* Mantén presionado el botón BOOT durante 10 segundos
* El dispositivo mostrará mensaje de confirmación y entrará en deep sleep
* Presiona RESET para reiniciar

## 📁 Estructura del Proyecto

```
AlvarosDev_HumiTempSensor/
├── main.ino                        # Código principal
├── README.md                        # Este archivo
├── ci.json                         # Configuración CI
├── flash.cmd                       # Script de flasheo original
├── scripts/                        # Scripts de compilación y flasheo
│   ├── compile.cmd                 # Compilar (Windows CMD)
│   ├── flash.cmd                   # Flashear (Windows CMD)
│   └── README.md                   # Documentación de scripts
└── .github/
    └── workflows/
        └── compile-esp32.yml        # GitHub Actions CI/CD
```

## 🚀 Scripts de Compilación y Flasheo

Este proyecto incluye scripts automatizados para facilitar el desarrollo:

### Compilación Local
```cmd
# Windows CMD
scripts\compile.cmd
```

### Flasheo Local
```cmd
# Windows CMD (después de compilar)
scripts\flash.cmd
```

### Compilación y Flasheo en un Solo Comando
```cmd
# Windows CMD - compila y flashea automáticamente
scripts\build-and-flash.cmd
```

### Prerrequisitos para Scripts Locales
- **Arduino CLI**: Instalar desde [arduino.github.io/arduino-cli](https://arduino.github.io/arduino-cli/)
- **Python 3.x**: Para esptool (se instala automáticamente si no está presente)
- **Core ESP32**: Se instala automáticamente la primera vez

### CI/CD con GitHub Actions
El proyecto incluye integración continua que se activa automáticamente:
- **Trigger**: Push a ramas `release/*`
- **Acciones**: Compilación automática en Ubuntu
- **Artefactos**: Archivos `.bin`, `.elf`, y `.map` disponibles para descarga
- **Duración**: Los artefactos se mantienen 30 días

Para más detalles sobre los scripts, consulta [`scripts/README.md`](scripts/README.md).

## 🌟 Créditos y Base

**Proyecto base**: Arduino-ESP32 Zigbee Temperature Sensor Example (Espressif)
**Desarrollador**: AlvarosDev
**Modificaciones**: Implementación de sensor real SHT4x, gestión de energía avanzada, validación de datos y mejoras en estabilidad

## 📚 Recursos y Referencias

* [Arduino-ESP32 Official Repository](https://github.com/espressif/arduino-esp32)
* [ESP32-C6 Datasheet](https://www.espressif.com/sites/default/files/documentation/esp32-c6_datasheet_en.pdf)
* [Adafruit SHT4x Library](https://github.com/adafruit/Adafruit_SHT4X)
* [Official ESP32 Forum](https://esp32.com)
* [ESP-IDF Documentation](https://idf.espressif.com)

## 🤝 Contribuciones

Si encuentras algún problema o tienes sugerencias de mejora, por favor:
1. Revisa la sección de solución de problemas
2. Busca issues similares en el repositorio base
3. Crea un nuevo issue con detalles específicos

---
**Nota**: Este proyecto demuestra la implementación práctica de un sensor IoT Zigbee con gestión eficiente de energía, ideal para aplicaciones de monitoreo ambiental domótico.

## 🛠️ Compilación y Flasheo

### Opción 1: Makefile (Recomendado para Linux/macOS)

```bash
# Mostrar todas las opciones disponibles
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
```

### Opción 2: Scripts Shell Unix

```bash
# Configuración inicial
./scripts/setup.sh

# Desarrollo
./scripts/build.sh
./scripts/flash.sh
./scripts/build-and-flash.sh
```

## 📋 Prerrequisitos

Los scripts de configuración (`make setup` o `scripts/setup.sh`) instalan automáticamente las dependencias. Manual:

- **Arduino CLI**: Herramienta de línea de comandos de Arduino
- **Python 3**: Para esptool (flasheo del ESP32)
- **Core ESP32**: Soporte para placas ESP32 en Arduino CLI

## 📁 Estructura del Proyecto

```
├── main.ino              # Código principal del sensor
├── ci.json               # Configuración del ESP32C6
├── Makefile              # Build system para Linux/macOS
├── build/                # Archivos compilados (generado)
└── scripts/              # Scripts de compilación y flasheo
    ├── README.md         # Documentación de scripts
    ├── setup.sh          # Configuración automática
    ├── build.sh          # Compilar
    ├── flash.sh          # Flashear
    └── build-and-flash.sh   # Todo en uno
```

## ⚙️ Configuración del Hardware

- **Placa**: ESP32C6
- **Configuración**: Zigbee End Device
- **Partición**: zigbee
- **Sensor**: [Especificar sensor de humedad y temperatura usado]

## 🔧 Desarrollo

### Comandos Frecuentes

```bash
# Con Makefile
make deploy        # Compilar y flashear
make monitor       # Ver salida del sensor
make clean         # Limpiar build

# Con scripts
./scripts/build-and-flash.sh    # Compilar y flashear
```

### Solución de Problemas

- **Puerto no detectado**: `make list-ports` o `make flash PORT=/dev/ttyUSB0`
- **Permisos en Linux**: `sudo usermod -a -G dialout $USER` (reiniciar sesión)
- **ESP32 no responde**: Presiona BOOT mientras presionas RESET

## 📖 Documentación Adicional

- Ver `scripts/README.md` para documentación detallada de scripts
- Ejecutar `make help` para ver todas las opciones del Makefile
