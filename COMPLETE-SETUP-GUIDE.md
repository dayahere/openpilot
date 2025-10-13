# OpenPilot - Complete Setup & Testing Guide

## ✅ STEP 1: Ollama is Running!

Ollama is now running in Docker at: `http://localhost:11434`
Model installed: `phi3:mini` (2GB, good for testing)

## ✅ STEP 2: Configure OpenPilot Extension

### Method 1: Using VSCode Settings UI
1. In the **Extension Development Host** window:
2. `Ctrl+Shift+P` → `OpenPilot: Configure`
3. Or: `File > Preferences > Settings`
4. Search for: `openpilot`
5. Set these values:
   - **Provider**: `ollama`
   - **Model**: `phi3:mini`
   - **API URL**: `http://localhost:11434` (default)
   - **Temperature**: `0.7` (default)
   - **Max Tokens**: `2048` (default)

### Method 2: Using settings.json (Faster)
1. `Ctrl+Shift+P` → `Preferences: Open User Settings (JSON)`
2. Add this configuration:

```json
{
  "openpilot.provider": "ollama",
  "openpilot.model": "phi3:mini",
  "openpilot.apiUrl": "http://localhost:11434",
  "openpilot.temperature": 0.7,
  "openpilot.maxTokens": 2048,
  "openpilot.offline": false
}
```

## ✅ STEP 3: Test the Extension

After configuring, try these commands in the Extension Development Host window:

### Test 1: Chat
1. `Ctrl+Shift+P` → `OpenPilot: Open Chat`
2. Type: "hello"
3. Should get a response from phi3:mini

### Test 2: Explain Code
1. Select some code
2. `Ctrl+Shift+P` → `OpenPilot: Explain Code`
3. Should get an explanation

### Test 3: Generate Code
1. `Ctrl+Shift+P` → `OpenPilot: Generate Code`
2. Enter prompt: "Create a function to add two numbers"
3. Should generate code

## Troubleshooting

### If you still get "API request failed: Error"

**Check Ollama is responding:**
```powershell
curl http://localhost:11434/api/tags
```

**Check extension configuration:**
1. Open Extension Development Host
2. `View > Output` → Select "Extension Host"
3. Look for error messages
4. Check Debug Console: `View > Debug Console`

**Reload the extension:**
1. In Extension Development Host window
2. `Ctrl+Shift+P` → `Developer: Reload Window`

**Verify Ollama works directly:**
```powershell
curl http://localhost:11434/api/generate -d '{
  "model": "phi3:mini",
  "prompt": "Hello"
}'
```

## About Other Platforms (Desktop, Web, Android)

### Current Status:
- **VSCode Extension**: ✅ Working (in development mode)
- **Desktop App**: Uses same `@openpilot/core` library
- **Web App**: Uses same `@openpilot/core` library
- **Android App**: Not yet implemented (mobile-specific)

### Shared Issues:
The issues we fixed in VSCode extension are **SPECIFIC to VSCode packaging (VSIX)**. The other platforms have their own build systems:

- **Desktop**: Electron app, bundles differently
- **Web**: Webpack bundle, served via browser
- **Android**: React Native, different architecture

### To Test Other Platforms:

**Desktop App:**
```powershell
cd i:\openpilot\desktop
# Install dependencies in Docker
docker run --rm -v "${PWD}:/workspace" -w /workspace node:20-alpine npm install
# Start desktop app
docker run --rm -v "${PWD}:/workspace" -w /workspace node:20-alpine npm start
```

**Web App:**
```powershell
cd i:\openpilot\web
# Install dependencies
docker run --rm -v "${PWD}:/workspace" -w /workspace node:20-alpine npm install
# Start web server
docker run --rm -p 3000:3000 -v "${PWD}:/workspace" -w /workspace node:20-alpine npm start
# Open browser: http://localhost:3000
```

## Test Coverage

The current test suite (210+ tests) covers:
- ✅ Core AI Engine functionality
- ✅ Context Management
- ✅ Prompt Generation
- ✅ Code Analysis
- ✅ Repository Analysis
- ✅ AI Provider integrations

**What tests DON'T cover yet:**
- UI/UX interactions (VSCode commands, chat interface)
- End-to-end user workflows
- Cross-platform compatibility
- Performance under load

**Next Steps for Comprehensive Testing:**
1. Add integration tests for VSCode extension commands
2. Add E2E tests for chat functionality
3. Add tests for Desktop/Web platforms
4. Add performance benchmarks

Would you like me to:
1. ✅ Create comprehensive integration tests for all features?
2. ✅ Test and fix Desktop/Web apps?
3. ✅ Add E2E test suite for user workflows?
