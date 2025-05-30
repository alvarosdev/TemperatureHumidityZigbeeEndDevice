#!/bin/bash
set -e

echo "========================================"
echo "Configuración del Entorno ESP32C6"
echo "========================================"

# Detectar sistema operativo
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
else
    OS="unknown"
fi

echo "Sistema detectado: $OS"
echo "Verificando prerrequisitos..."

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 1. Verificar Arduino CLI
if command_exists arduino-cli; then
    echo "✓ Arduino CLI ya está instalado"
else
    echo "⚠ Arduino CLI no encontrado. Instalando..."
    
    case $OS in
        "linux")
            if command_exists curl; then
                curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
                echo "✓ Arduino CLI instalado"
                echo "Agregando al PATH..."
                export PATH="$PATH:$HOME/bin"
                echo 'export PATH="$PATH:$HOME/bin"' >> ~/.bashrc
            else
                echo "✗ curl no disponible. Por favor instala curl primero"
                echo "sudo apt-get install curl"
            fi
            ;;
        "macos")
            if command_exists brew; then
                brew install arduino-cli
                echo "✓ Arduino CLI instalado via Homebrew"
            else
                echo "⚠ Homebrew no disponible. Instalando con script oficial..."
                curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
                export PATH="$PATH:$HOME/bin"
                echo 'export PATH="$PATH:$HOME/bin"' >> ~/.zshrc
            fi
            ;;
        *)
            echo "✗ Sistema no soportado automáticamente"
            echo "Por favor instala Arduino CLI manualmente:"
            echo "curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh"
            ;;
    esac
fi

# 2. Verificar Python
if command_exists python3; then
    echo "✓ Python3 ya está instalado"
elif command_exists python; then
    echo "✓ Python ya está instalado"
else
    echo "⚠ Python no encontrado. Instalando..."
    
    case $OS in
        "linux")
            echo "Instalando Python3..."
            if command_exists apt-get; then
                sudo apt-get update
                sudo apt-get install -y python3 python3-pip
            elif command_exists yum; then
                sudo yum install -y python3 python3-pip
            elif command_exists pacman; then
                sudo pacman -S python python-pip
            else
                echo "✗ Gestor de paquetes no soportado"
                echo "Por favor instala Python3 manualmente"
            fi
            ;;
        "macos")
            if command_exists brew; then
                brew install python3
                echo "✓ Python3 instalado via Homebrew"
            else
                echo "✗ Homebrew no disponible"
                echo "Por favor instala Python3 desde python.org o instala Homebrew"
            fi
            ;;
        *)
            echo "✗ Sistema no soportado automáticamente"
            echo "Por favor instala Python3 manualmente"
            ;;
    esac
fi

# 3. Verificar/instalar esptool
PYTHON_CMD=""
if command_exists python3; then
    PYTHON_CMD="python3"
elif command_exists python; then
    PYTHON_CMD="python"
fi

if [ -n "$PYTHON_CMD" ]; then
    if $PYTHON_CMD -c "import esptool" 2>/dev/null; then
        echo "✓ esptool ya está instalado"
    else
        echo "⚠ esptool no encontrado. Instalando..."
        if $PYTHON_CMD -m pip install esptool --user; then
            echo "✓ esptool instalado"
        else
            echo "⚠ Error instalando esptool. Inténtalo manualmente:"
            echo "$PYTHON_CMD -m pip install esptool --user"
        fi
    fi
fi

# 4. Configurar Arduino CLI Core ESP32
if command_exists arduino-cli; then
    echo "Configurando core ESP32..."
    
    if arduino-cli core update-index && arduino-cli core install esp32:esp32; then
        echo "✓ Core ESP32 instalado/actualizado"
    else
        echo "⚠ Error configurando core ESP32. Inténtalo manualmente:"
        echo "arduino-cli core update-index"
        echo "arduino-cli core install esp32:esp32"
    fi
fi

# 5. Verificar permisos de puerto serie (Linux)
if [[ "$OS" == "linux" ]]; then
    if groups | grep -q dialout; then
        echo "✓ Usuario ya pertenece al grupo dialout"
    else
        echo "⚠ Agregando usuario al grupo dialout para acceso al puerto serie..."
        sudo usermod -a -G dialout "$USER"
        echo "⚠ Por favor cierra sesión y vuelve a iniciarla para aplicar los cambios"
    fi
fi

echo ""
echo "========================================"
echo "Resumen de Configuración"
echo "========================================"

echo -n "Arduino CLI: "
if command_exists arduino-cli; then 
    echo "✓ Instalado"
else 
    echo "✗ No instalado"
fi

echo -n "Python: "
if command_exists python3 || command_exists python; then 
    echo "✓ Instalado"
else 
    echo "✗ No instalado"
fi

echo ""
echo "Ya puedes usar los scripts de compilación y flasheo:"
echo "  ./scripts/build.sh"
echo "  ./scripts/flash.sh"
echo "  ./scripts/build-and-flash.sh" 