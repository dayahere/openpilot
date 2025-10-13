# OpenPilot VSCode Extension - Working Setup

## The Issue
The VSIX packaging is not including the `@openpilot/core` dependency properly, causing the "command not found" error.

## ✅ WORKING SOLUTION: Development Mode

### Method 1: Open Extension Folder in VSCode

1. **Close all VSCode windows**

2. **Open VSCode fresh**

3. **Open the extension folder:**
   - File > Open Folder
   - Navigate to: `i:\openpilot\vscode-extension`
   - Click "Select Folder"

4. **Run the extension:**
   - Press `F5` (or click Run > Start Debugging)
   - OR press `Ctrl+Shift+D` then click the green play button

5. **A NEW VSCode window opens** (Extension Development Host)

6. **In the NEW window, test the commands:**
   - Press `Ctrl+Shift+P`
   - Type "OpenPilot: Open Chat"
   - It should work! ✅

### Method 2: Command Line Launch

Run this command:
```powershell
code --extensionDevelopmentPath="i:\openpilot\vscode-extension"
```

This launches VSCode with the extension loaded directly from source.

## Why This Works

- Development mode runs the extension from source files
- All dependencies (`@openpilot/core`, `axios`, etc.) are available
- No packaging/bundling issues
- This is how extension developers test their extensions

## Available Commands (in Extension Development Host window)

- `OpenPilot: Open Chat` - Start AI chat
- `OpenPilot: Explain Code` - Explain selected code
- `OpenPilot: Generate Code` - Generate new code
- `OpenPilot: Refactor Code` - Improve code quality
- `OpenPilot: Fix Code` - Auto-fix bugs
- `OpenPilot: Analyze Repository` - Full repo analysis
- `OpenPilot: Configure` - Setup AI provider

## Configuration

Before first use, configure your AI provider:
1. `Ctrl+Shift+P` → "OpenPilot: Configure"
2. Choose: Ollama (local, free) or OpenAI/Grok (needs API key)

## Troubleshooting

If commands still don't appear:
1. Check the Debug Console (View > Debug Console) for errors
2. Check Output panel (View > Output > "Extension Host")
3. Make sure you're in the **Extension Development Host** window, not the original window
