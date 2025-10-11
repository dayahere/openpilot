# OpenPilot VSCode Extension Build Instructions

## Prerequisites
- Node.js 18+
- npm 9+
- Visual Studio Code
- vsce (VS Code Extension Manager)

## Build Steps

1. **Install Dependencies**
   ```bash
   cd vscode-extension
   npm install
   ```

2. **Install vsce**
   ```bash
   npm install -g @vscode/vsce
   ```

3. **Compile Extension**
   ```bash
   npm run compile
   ```

4. **Package Extension**
   ```bash
   vsce package
   ```
   Output: openpilot-1.0.0.vsix

## Installation

### Method 1: Install from VSIX
1. Open VS Code
2. Press Ctrl+Shift+P (Windows/Linux) or Cmd+Shift+P (macOS)
3. Type "Extensions: Install from VSIX"
4. Select openpilot-1.0.0.vsix
5. Reload VS Code

### Method 2: Command Line
```bash
code --install-extension openpilot-1.0.0.vsix
```

### Method 3: Extensions View
1. Open Extensions view (Ctrl+Shift+X)
2. Click ... menu â†’ "Install from VSIX"
3. Select openpilot-1.0.0.vsix

## Testing

1. **Run Extension in Development Mode**
   - Open extension folder in VS Code
   - Press F5 to launch Extension Development Host
   - Test features in new VS Code window

2. **Run Tests**
   ```bash
   npm test
   ```

3. **Test Commands**
   - Open Command Palette (Ctrl+Shift+P)
   - Type "OpenPilot" to see available commands
   - Test each command

## Publishing (Optional)

1. **Create Publisher Account**
   - Visit: https://marketplace.visualstudio.com/manage
   - Create publisher account

2. **Login with vsce**
   ```bash
   vsce login <publisher-name>
   ```

3. **Publish Extension**
   ```bash
   vsce publish
   ```

## Features

- âœ… AI-powered code completion
- âœ… Chat interface for code assistance
- âœ… Context-aware suggestions
- âœ… Multi-language support
- âœ… Offline mode with Ollama
- âœ… Cloud mode with OpenAI/Grok

## Configuration

After installation, configure in VS Code settings:

```json
{
  "openpilot.provider": "ollama",
  "openpilot.model": "codellama",
  "openpilot.apiUrl": "http://localhost:11434",
  "openpilot.enableCompletion": true,
  "openpilot.enableChat": true
}
```

## Uninstallation

1. Open Extensions view (Ctrl+Shift+X)
2. Find "OpenPilot"
3. Click "Uninstall"

---
**Package:** OpenPilot VSCode Extension  
**Version:** 1.0.0  
**VS Code Version:** 1.75.0+  
**Extension ID:** openpilot.vscode-extension
