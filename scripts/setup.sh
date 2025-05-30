#!/bin/bash
set -e

echo "========================================"
echo "ESP32C6 Environment Setup"
echo "========================================"

# Detect operating system
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
else
    OS="unknown"
fi

echo "Detected system: $OS"
echo "Checking prerequisites..."

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 1. Check Arduino CLI
if command_exists arduino-cli; then
    echo "✓ Arduino CLI is already installed"
else
    echo "⚠ Arduino CLI not found. Installing..."
    
    case $OS in
        "linux")
            if command_exists curl; then
                curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
                echo "✓ Arduino CLI installed"
                echo "Adding to PATH..."
                export PATH="$PATH:$HOME/bin"
                echo 'export PATH="$PATH:$HOME/bin"' >> ~/.bashrc
            else
                echo "✗ curl not available. Please install curl first"
                echo "sudo apt-get install curl"
            fi
            ;;
        "macos")
            if command_exists brew; then
                brew install arduino-cli
                echo "✓ Arduino CLI installed via Homebrew"
            else
                echo "⚠ Homebrew not available. Installing with official script..."
                curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
                export PATH="$PATH:$HOME/bin"
                echo 'export PATH="$PATH:$HOME/bin"' >> ~/.zshrc
            fi
            ;;
        *)
            echo "✗ System not automatically supported"
            echo "Please install Arduino CLI manually:"
            echo "curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh"
            ;;
    esac
fi

# 2. Check Python
if command_exists python3; then
    echo "✓ Python3 is already installed"
elif command_exists python; then
    echo "✓ Python is already installed"
else
    echo "⚠ Python not found. Installing..."
    
    case $OS in
        "linux")
            echo "Installing Python3..."
            if command_exists apt-get; then
                sudo apt-get update
                sudo apt-get install -y python3 python3-pip
            elif command_exists yum; then
                sudo yum install -y python3 python3-pip
            elif command_exists pacman; then
                sudo pacman -S python python-pip
            else
                echo "✗ Package manager not supported"
                echo "Please install Python3 manually"
            fi
            ;;
        "macos")
            if command_exists brew; then
                brew install python3
                echo "✓ Python3 installed via Homebrew"
            else
                echo "✗ Homebrew not available"
                echo "Please install Python3 from python.org or install Homebrew"
            fi
            ;;
        *)
            echo "✗ System not automatically supported"
            echo "Please install Python3 manually"
            ;;
    esac
fi

# 3. Check/install esptool
PYTHON_CMD=""
if command_exists python3; then
    PYTHON_CMD="python3"
elif command_exists python; then
    PYTHON_CMD="python"
fi

if [ -n "$PYTHON_CMD" ]; then
    if $PYTHON_CMD -c "import esptool" 2>/dev/null; then
        echo "✓ esptool is already installed"
    else
        echo "⚠ esptool not found. Installing..."
        if $PYTHON_CMD -m pip install esptool --user; then
            echo "✓ esptool installed"
        else
            echo "⚠ Error installing esptool. Try manually:"
            echo "$PYTHON_CMD -m pip install esptool --user"
        fi
    fi
fi

# 4. Configure Arduino CLI ESP32 Core
if command_exists arduino-cli; then
    echo "Configuring ESP32 core..."
    
    if arduino-cli core update-index && arduino-cli core install esp32:esp32; then
        echo "✓ ESP32 core installed/updated"
    else
        echo "⚠ Error configuring ESP32 core. Try manually:"
        echo "arduino-cli core update-index"
        echo "arduino-cli core install esp32:esp32"
    fi
fi

# 5. Check serial port permissions (Linux)
if [[ "$OS" == "linux" ]]; then
    # Check for both dialout (common) and uucp (Arch/Manjaro) groups
    if groups | grep -q dialout || groups | grep -q uucp; then
        echo "✓ User already belongs to a serial port group (dialout or uucp)"
    else
        echo "⚠ Adding user to uucp group for serial port access..."
        sudo usermod -a -G uucp "$USER"
        echo "⚠ Please log out and log back in to apply the changes"
    fi
fi

echo ""
echo "========================================"
echo "Setup Summary"
echo "========================================"

echo -n "Arduino CLI: "
if command_exists arduino-cli; then 
    echo "✓ Installed"
else 
    echo "✗ Not installed"
fi

echo -n "Python: "
if command_exists python3 || command_exists python; then 
    echo "✓ Installed"
else 
    echo "✗ Not installed"
fi

echo ""
echo "You can now use the compilation and flashing scripts:"
echo "  ./scripts/build.sh"
echo "  ./scripts/flash.sh"
echo "  ./scripts/build-and-flash.sh" 