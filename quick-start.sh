#!/bin/bash
# OpenPilot Quick Start Script for Unix/Linux/macOS
# This script sets up and runs OpenPilot

set -e

echo "========================================"
echo "OpenPilot Quick Start"
echo "========================================"
echo ""

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "[ERROR] Node.js is not installed!"
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "[ERROR] Python is not installed!"
    echo "Please install Python from https://www.python.org/"
    exit 1
fi

echo "[OK] Node.js found: $(node --version)"
echo "[OK] Python found: $(python3 --version)"
echo ""

# Install dependencies
echo "========================================"
echo "Installing Dependencies..."
echo "========================================"
echo ""

echo "Installing root dependencies..."
npm install

echo "Installing Python dependencies..."
pip3 install -r requirements.txt

echo ""
echo "========================================"
echo "Building Projects..."
echo "========================================"
echo ""

echo "Building core library..."
cd core
npm install
npm run build
cd ..

echo "Building VS Code extension..."
cd vscode-extension
npm install
npm run compile
cd ..

echo "Building desktop app..."
cd desktop
npm install
cd ..

echo ""
echo "========================================"
echo "Setup Complete!"
echo "========================================"
echo ""
echo "What would you like to do?"
echo ""
echo "1. Run Desktop App"
echo "2. Open VS Code Extension (development)"
echo "3. Install Ollama (local AI)"
echo "4. Run Tests"
echo "5. Exit"
echo ""

read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        echo ""
        echo "Starting Desktop App..."
        cd desktop
        npm start &
        cd ..
        ;;
    2)
        echo ""
        echo "Opening VS Code extension..."
        echo "Press F5 in VS Code to start the extension development host"
        cd vscode-extension
        code .
        cd ..
        ;;
    3)
        echo ""
        echo "Installing Ollama..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command -v brew &> /dev/null; then
                brew install ollama
                echo "Ollama installed!"
                echo "Run: ollama serve"
                echo "Then: ollama pull codellama"
            else
                echo "Please install Homebrew first: https://brew.sh"
                open https://ollama.ai/download
            fi
        else
            # Linux
            curl https://ollama.ai/install.sh | sh
            echo "Ollama installed!"
            echo "Run: ollama serve"
            echo "Then: ollama pull codellama"
        fi
        ;;
    4)
        echo ""
        echo "Running tests..."
        npm run test:all
        ;;
    5)
        echo "Goodbye!"
        exit 0
        ;;
    *)
        echo "Invalid choice"
        ;;
esac

echo ""
echo "========================================"
echo "Quick Commands:"
echo "========================================"
echo ""
echo "Desktop App:     cd desktop && npm start"
echo "VS Code Ext:     cd vscode-extension && code ."
echo "Run Tests:       npm run test:all"
echo "Auto-Fix:        python3 scripts/auto-fix.py"
echo ""
