# OpenPilot Installation & Setup Guide

This guide will help you get OpenPilot running on your system.

## System Requirements

- **Node.js**: 18.0 or higher
- **Python**: 3.9 or higher
- **npm** or **yarn**
- **Git**
- (Optional) **Ollama** for local AI models

## Installation Steps

### 1. Install Dependencies

#### Install Node.js Dependencies
```bash
# From the root directory
npm install

# This will install dependencies for all workspaces
```

#### Install Python Dependencies
```bash
pip install -r requirements.txt
```

### 2. Setup Local AI (Optional - Ollama)

If you want to use local AI models:

#### Windows
```powershell
# Download and install Ollama from https://ollama.ai/download
# Or using winget:
winget install Ollama.Ollama

# Start Ollama
ollama serve

# Pull a code model
ollama pull codellama
```

#### macOS
```bash
# Using Homebrew
brew install ollama

# Start Ollama
ollama serve

# Pull a code model
ollama pull codellama
```

#### Linux
```bash
curl https://ollama.ai/install.sh | sh

# Start Ollama
ollama serve

# Pull a code model
ollama pull codellama
```

### 3. Configuration

Create a `.env` file in the root directory (optional):

```env
# AI Provider Configuration
AI_PROVIDER=ollama
AI_MODEL=codellama
AI_TEMPERATURE=0.7
AI_MAX_TOKENS=2048

# For cloud providers (optional)
# OPENAI_API_KEY=your_key_here
# GROK_API_KEY=your_key_here
# TOGETHER_API_KEY=your_key_here
```

### 4. Build Projects

```bash
# Build all projects
npm run build:all

# Or build individually
npm run build:core
npm run build:extension
npm run build:desktop
npm run build:web
```

## Running OpenPilot

### VS Code Extension

1. Open the `vscode-extension` folder in VS Code
2. Press `F5` to launch the Extension Development Host
3. In the new VS Code window, open the Command Palette (`Ctrl+Shift+P` or `Cmd+Shift+P`)
4. Search for "OpenPilot" commands

Or install as VSIX:
```bash
cd vscode-extension
npm run package
# Install the generated .vsix file in VS Code
```

### Desktop Application

```bash
cd desktop
npm start
```

For production build:
```bash
cd desktop
npm run build:electron
```

The built app will be in `desktop/dist`.

### Web Application

```bash
cd web
npm install
npm start
```

Access at `http://localhost:3000`

For production:
```bash
npm run build
```

### Mobile Application

#### iOS
```bash
cd mobile
npm install
npx pod-install # iOS only
npx react-native run-ios
```

#### Android
```bash
cd mobile
npm install
npx react-native run-android
```

## Testing

### Run All Tests
```bash
npm run test:all
```

### Run Tests by Project
```bash
npm run test:core      # Core library tests
npm run test:extension # VS Code extension tests
npm run test:desktop   # Desktop app tests
npm run test:web       # Web app tests
```

### Coverage
```bash
cd core
npm run test:coverage
```

## Troubleshooting

### Common Issues

#### 1. "Cannot find module '@openpilot/core'"
```bash
# Make sure you've built the core module
cd core
npm install
npm run build
```

#### 2. Ollama connection errors
```bash
# Make sure Ollama is running
ollama serve

# Check if models are available
ollama list

# Pull a model if needed
ollama pull codellama
```

#### 3. VS Code extension not loading
```bash
# Rebuild the extension
cd vscode-extension
npm install
npm run compile
```

#### 4. Desktop app won't start
```bash
# Clear node_modules and reinstall
cd desktop
rm -rf node_modules
npm install
npm start
```

### Port Conflicts

If you get port conflicts:

- Web app uses port 3000 (configurable in `.env`)
- Ollama uses port 11434
- Backend server uses port 8000 (if running)

## Development Mode

### Watch Mode for Core Library
```bash
cd core
npm run dev
```

### Watch Mode for VS Code Extension
```bash
cd vscode-extension
npm run watch
```

### Hot Reload for Web/Desktop
```bash
# Desktop
cd desktop
npm start

# Web
cd web
npm start
```

## Environment Variables

Create `.env` files in each project as needed:

### Core `.env`
```env
AI_PROVIDER=ollama
AI_MODEL=codellama
DEBUG=true
```

### Web `.env`
```env
REACT_APP_API_URL=http://localhost:8000
REACT_APP_AI_PROVIDER=ollama
```

### Desktop `.env`
```env
ELECTRON_START_URL=http://localhost:3000
```

## Next Steps

1. **Configure AI Provider**: Open Settings in the app and configure your preferred AI provider
2. **Try Chat**: Open the chat interface and ask a coding question
3. **Test Code Completion**: Start typing code and see inline suggestions
4. **Create Checkpoint**: Save a checkpoint before making major changes
5. **Analyze Repository**: Let OpenPilot analyze your codebase for better context

## Getting Help

- **Documentation**: See `docs/` folder
- **Issues**: Report bugs on GitHub Issues
- **Discord**: Join our community for support
- **Examples**: Check `examples/` folder for usage samples

## Updating

```bash
# Pull latest changes
git pull

# Update dependencies
npm install
pip install -r requirements.txt

# Rebuild
npm run build:all
```

---

Enjoy using OpenPilot! 🚀
