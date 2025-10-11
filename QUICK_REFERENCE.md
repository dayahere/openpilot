# 🚀 OpenPilot Quick Reference Card

## ⚡ Quick Start (5 Minutes)

```bash
# 1. Install dependencies
npm install && pip install -r requirements.txt

# 2. Build core
cd core && npm install && npm run build && cd ..

# 3. Run desktop app
cd desktop && npm install && npm start
```

## 🎯 Common Commands

### Development
```bash
npm run dev                 # Watch mode for all projects
npm run build:all          # Build everything
npm run test:all           # Run all tests
python scripts/auto-fix.py # Lint, format, and fix
```

### Individual Projects
```bash
# Core
cd core && npm run build && npm test

# VS Code Extension  
cd vscode-extension && npm run compile

# Desktop
cd desktop && npm start

# Web (when ready)
cd web && npm start
```

## 🔧 Configuration

### Quick Setup (.env file)
```env
AI_PROVIDER=ollama          # or openai, grok, together
AI_MODEL=codellama          # or gpt-4, grok-1, etc.
AI_TEMPERATURE=0.7          # 0.0-2.0
AI_MAX_TOKENS=2048         # Response length
OFFLINE_MODE=false         # true for local only
AUTO_COMPLETE=true         # Enable completions
```

### Ollama Setup
```bash
# Install: https://ollama.ai
ollama serve
ollama pull codellama      # or llama2, mistral, etc.
```

### OpenAI Setup
```env
AI_PROVIDER=openai
AI_MODEL=gpt-4
OPENAI_API_KEY=sk-your-key
```

## 📁 Project Structure

```
openpilot/
├── core/              # AI engine & utilities
├── vscode-extension/  # VS Code plugin
├── desktop/           # Electron app
├── web/               # React PWA (planned)
├── mobile/            # React Native (planned)
├── scripts/           # Automation scripts
└── docs/              # Documentation
```

## 🎮 VS Code Extension

### Commands (Ctrl+Shift+P)
- `OpenPilot: Open Chat` - Open chat panel
- `OpenPilot: Explain Code` - Explain selection
- `OpenPilot: Generate Code` - Generate from description
- `OpenPilot: Refactor Code` - Refactor selection
- `OpenPilot: Fix Code` - Fix issues
- `OpenPilot: Configure` - Open settings
- `OpenPilot: Create Checkpoint` - Save state
- `OpenPilot: Restore Checkpoint` - Restore state

### Shortcuts
- `Ctrl+Shift+P` - Open chat
- Right-click selection - Context menu

## 🖥️ Desktop App

### Navigation
- 💬 **Chat** - AI conversation
- ⚙️ **Settings** - Configure AI

### Keyboard
- `Enter` - Send message
- `Shift+Enter` - New line

## 🧪 Testing

```bash
# All tests
npm run test:all

# Specific
npm run test:core
npm run test:extension
npm run test:desktop

# With coverage
cd core && npm run test:coverage
```

## 📦 Packaging

### VS Code Extension
```bash
cd vscode-extension
npm run package          # Creates .vsix
code --install-extension openpilot-*.vsix
```

### Desktop App
```bash
cd desktop
npm run build:electron   # Creates installers
# Output: desktop/dist/
```

## 🔍 Debugging

### Enable Debug Mode
```env
DEBUG=true
LOG_LEVEL=debug
```

### VS Code Extension
1. Open `vscode-extension` in VS Code
2. Press `F5`
3. New window opens with extension loaded
4. Check Debug Console for logs

### Desktop App
```bash
cd desktop
npm start
# DevTools: Ctrl+Shift+I (Windows/Linux) or Cmd+Option+I (Mac)
```

## 🐛 Common Issues & Fixes

### "Cannot find module"
```bash
npm install              # Root
cd core && npm install
cd ../vscode-extension && npm install
cd ../desktop && npm install
```

### TypeScript Errors
```bash
npm run build:core      # Build core first
```

### Ollama Not Connecting
```bash
ollama serve            # Start server
# Check: http://localhost:11434
```

### Extension Not Loading
```bash
cd vscode-extension
npm install
npm run compile
# Then press F5
```

## 📝 Code Snippets

### Add AI Provider
```typescript
// core/src/ai-engine/index.ts
class MyProvider extends BaseAIProvider {
  async chat(context: ChatContext): Promise<AIResponse> {
    // Implementation
  }
}
```

### Add VS Code Command
```typescript
// vscode-extension/src/extension.ts
vscode.commands.registerCommand('openpilot.myCommand', () => {
  // Implementation
});
```

### Custom Configuration
```typescript
// Get config
const config = vscode.workspace.getConfiguration('openpilot');
const model = config.get('model');

// Update config
config.update('model', 'new-model', true);
```

## 🎨 Customization

### Change Theme Colors
```css
/* desktop/src/components/*.css */
:root {
  --primary-color: #569cd6;
  --background-color: #1e1e1e;
  --text-color: #d4d4d4;
}
```

### Modify Chat UI
```typescript
// desktop/src/components/ChatInterface.tsx
// Edit JSX components
```

### Add Settings
```json
// vscode-extension/package.json
"contributes": {
  "configuration": {
    "properties": {
      "openpilot.mySetting": {
        "type": "string",
        "default": "value"
      }
    }
  }
}
```

## 📊 Performance Tips

1. **Limit Context**: Reduce `CONTEXT_LINES` for faster completions
2. **Cache**: Keep `CACHE_SIZE` reasonable (default: 100MB)
3. **Streaming**: Enable `ENABLE_STREAMING` for better UX
4. **Local Models**: Use Ollama for fastest responses
5. **File Exclusion**: Add patterns to `EXCLUDE_PATTERNS`

## 🔒 Security

### API Keys
- Never commit `.env` to git
- Use VS Code Secret Storage for extension
- Desktop app uses electron-store (encrypted)

### Privacy
- Set `OFFLINE_MODE=true` for complete privacy
- All data stays local by default
- No telemetry unless explicitly enabled

## 📚 Resources

- **README.md** - Overview & features
- **INSTALL.md** - Detailed installation
- **ARCHITECTURE.md** - System design
- **CONTRIBUTING.md** - How to contribute
- **PROJECT_SUMMARY.md** - Current status
- **BUILD_SUMMARY.md** - Complete build info

## 🆘 Get Help

1. Check documentation files
2. Run auto-fix: `python scripts/auto-fix.py`
3. Check logs (Debug Console / DevTools)
4. Search GitHub issues
5. Open new issue with details

## 🎯 Next Steps

1. ✅ Install dependencies
2. ✅ Setup Ollama or API key
3. ✅ Build and run
4. ✅ Try chat feature
5. ✅ Test code completion
6. ✅ Explore settings
7. ✅ Create a checkpoint
8. ✅ Contribute improvements!

## 💡 Pro Tips

- Use `Ctrl+Shift+P` frequently for quick access
- Create checkpoints before major changes
- Try different AI models for different tasks
- Use local models for privacy-sensitive code
- Contribute back to make it better!

---

**Version**: 1.0.0  
**Last Updated**: 2025-01-11  
**License**: MIT  

Happy coding! 🚀
