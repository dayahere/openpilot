# 🚀 OpenPilot VSCode Extension - Usage Guide

## 📋 Quick Start

The OpenPilot extension is now installed! Here's how to use it as your AI coding assistant.

---

## 🎯 Activating the Extension

### Option 1: Activity Bar Icon
1. **Look for the OpenPilot icon** in the left sidebar (Activity Bar)
   - It should appear alongside Explorer, Search, Source Control, etc.
   - If you don't see it, try reloading VSCode: Press `Ctrl+Shift+P` → Type "Reload Window"

2. **Click the OpenPilot icon** to open the sidebar
   - You'll see three sections:
     - **Chat** - Main AI chat interface
     - **History** - Your conversation history
     - **Checkpoints** - Code checkpoints

### Option 2: Command Palette
Press `Ctrl+Shift+P` (Windows) or `Cmd+Shift+P` (Mac) and type:
- `OpenPilot: Open Chat` - Opens the chat interface
- `OpenPilot: Configure AI Settings` - Setup your AI provider

---

## 💬 Using the Chat Interface

### Opening Chat
**Method 1:** Click the OpenPilot icon in the Activity Bar → Chat panel
**Method 2:** Press `Ctrl+Shift+P` → `OpenPilot: Open Chat`

### Chat Features
- **Ask Questions**: Type any coding question
- **Code Explanations**: Ask about code you're working on
- **Generate Code**: Request code generation
- **Debug Help**: Get help with errors

### Example Chat Commands
```
"How do I create a React component?"
"Explain this function"
"Generate a REST API endpoint"
"Fix this TypeScript error"
```

---

## 🛠️ Available Commands

Access these via `Ctrl+Shift+P` → Type "OpenPilot":

### 1. **OpenPilot: Open Chat**
- Opens the main chat interface
- Your primary interaction point

### 2. **OpenPilot: Explain Code**
- Select code in your editor
- Run this command to get an explanation

### 3. **OpenPilot: Generate Code**
- Generates code based on your description
- Opens a dialog for you to describe what you need

### 4. **OpenPilot: Refactor Code**
- Select code to refactor
- AI suggests improvements

### 5. **OpenPilot: Fix Code**
- Select buggy code
- AI suggests fixes

### 6. **OpenPilot: Analyze Repository**
- Analyzes your entire codebase
- Provides insights and suggestions

### 7. **OpenPilot: Configure AI Settings**
- Set up your AI provider (Ollama, OpenAI, etc.)
- Configure API keys and models

### 8. **OpenPilot: Create Checkpoint**
- Save current code state
- Useful before major changes

### 9. **OpenPilot: Restore Checkpoint**
- Restore a previous code state

---

## ⚙️ Configuration (Required First Time)

Before using the AI features, you need to configure your AI provider:

### Step 1: Open Settings
1. Press `Ctrl+Shift+P`
2. Type: `OpenPilot: Configure AI Settings`
3. OR go to File → Preferences → Settings → Search "OpenPilot"

### Step 2: Choose AI Provider

#### Option A: Ollama (Free, Local)
```json
{
  "openpilot.provider": "ollama",
  "openpilot.ollamaModel": "codellama",
  "openpilot.ollamaUrl": "http://localhost:11434"
}
```
**Requirements:**
- Install Ollama: https://ollama.ai
- Run: `ollama run codellama`

#### Option B: OpenAI (Paid)
```json
{
  "openpilot.provider": "openai",
  "openpilot.openaiApiKey": "sk-your-key-here",
  "openpilot.openaiModel": "gpt-4"
}
```
**Requirements:**
- OpenAI API key from https://platform.openai.com

#### Option C: Other Providers
```json
{
  "openpilot.provider": "custom",
  "openpilot.customUrl": "https://your-api-endpoint",
  "openpilot.customApiKey": "your-api-key"
}
```

---

## 🎨 Right-Click Context Menu

When you right-click on selected code:
1. **Explain with OpenPilot** - Get explanation
2. **Fix with OpenPilot** - Get bug fixes
3. **Refactor with OpenPilot** - Get improvements

---

## 📱 Sidebar Panels

### Chat Panel
- Main conversation area
- Type messages and get AI responses
- Shows context from your current file

### History Panel
- View past conversations
- Click to restore a conversation
- Delete old chats

### Checkpoints Panel
- List of saved code states
- Click to restore
- Create new checkpoints before risky changes

---

## 🔥 Quick Tips

### 1. **Reload VSCode if Icon Doesn't Appear**
```
Ctrl+Shift+P → "Developer: Reload Window"
```

### 2. **Check Extension is Active**
```
Ctrl+Shift+P → "Extensions: Show Installed Extensions"
Look for "OpenPilot - Free AI Coding Assistant"
```

### 3. **View Extension Output**
```
View → Output → Select "OpenPilot" from dropdown
```

### 4. **Keyboard Shortcuts** (if configured)
- `Ctrl+Shift+A` - Open Chat (if set)
- `Ctrl+Shift+E` - Explain Code (if set)

---

## 🐛 Troubleshooting

### Issue: No OpenPilot Icon in Activity Bar

**Solution 1:** Reload Window
```
Ctrl+Shift+P → "Developer: Reload Window"
```

**Solution 2:** Check Extension is Enabled
```
Ctrl+Shift+P → "Extensions: Show Installed Extensions"
Find "OpenPilot" → Make sure it's enabled
```

**Solution 3:** Check Extension Host
```
Help → Toggle Developer Tools → Console tab
Look for any errors related to "openpilot"
```

### Issue: Chat Not Opening

**Solution:** Use Command Palette
```
Ctrl+Shift+P → "OpenPilot: Open Chat"
```

### Issue: AI Not Responding

**Check Configuration:**
1. `Ctrl+Shift+P` → "Preferences: Open Settings (JSON)"
2. Verify your `openpilot.provider` is set correctly
3. For Ollama: Make sure Ollama is running (`ollama serve`)
4. For OpenAI: Verify your API key is correct

### Issue: "Command not found"

**Reinstall Extension:**
```powershell
# Uninstall
code --uninstall-extension openpilot.openpilot-vscode

# Reinstall
code --install-extension i:\openpilot\artifacts-local\20251013_145343\vscode\openpilot-vscode_20251013_145343.vsix
```

---

## 📚 Example Workflows

### 1. Understanding Existing Code
```
1. Open a file in your project
2. Click OpenPilot icon in sidebar
3. In Chat, type: "Explain what this file does"
4. AI analyzes the active file and explains
```

### 2. Generating New Code
```
1. Click OpenPilot icon
2. In Chat, type: "Create a React component for a user profile card"
3. AI generates the code
4. Copy and paste into your project
```

### 3. Debugging
```
1. Select error-causing code
2. Right-click → "Fix with OpenPilot"
3. AI suggests fixes
4. Apply the fix
```

### 4. Code Review
```
1. Select code to review
2. Right-click → "Refactor with OpenPilot"
3. AI suggests improvements
4. Review and apply changes
```

---

## 🎓 Advanced Features

### Repository Analysis
```
Ctrl+Shift+P → "OpenPilot: Analyze Repository"
```
- Analyzes entire codebase structure
- Identifies patterns and issues
- Suggests architectural improvements

### Code Checkpoints
**Create Checkpoint:**
```
Ctrl+Shift+P → "OpenPilot: Create Checkpoint"
```

**Restore Checkpoint:**
```
Ctrl+Shift+P → "OpenPilot: Restore Checkpoint"
Select from list → Confirm
```

### Custom AI Prompts
In the Chat, you can use custom prompts:
```
"@code Explain the function on line 45"
"@generate Create a REST API for user authentication"
"@fix The error on line 23"
"@refactor Make this code more efficient"
```

---

## 📞 Getting Help

### View Logs
```
View → Output → Select "OpenPilot"
```

### Report Issues
Check the extension's output for errors and report them.

### Feature Requests
The extension supports:
- Multi-file context
- Git integration
- Custom AI providers
- Code checkpoints
- Conversation history

---

## 🚀 Next Steps

1. **Reload VSCode** to ensure extension is fully loaded
   ```
   Ctrl+Shift+P → "Developer: Reload Window"
   ```

2. **Look for the OpenPilot icon** in the Activity Bar (left sidebar)

3. **Configure AI Provider**
   ```
   Ctrl+Shift+P → "OpenPilot: Configure AI Settings"
   ```

4. **Start Chatting!**
   ```
   Click OpenPilot icon → Chat panel → Type your question
   ```

---

## 📝 Configuration Example

Add this to your VSCode settings (`Ctrl+,` → Search "OpenPilot"):

```json
{
  // AI Provider Settings
  "openpilot.provider": "ollama",
  "openpilot.ollamaModel": "codellama",
  "openpilot.ollamaUrl": "http://localhost:11434",
  
  // Chat Settings
  "openpilot.enableAutoComplete": true,
  "openpilot.maxContextLines": 100,
  
  // Feature Toggles
  "openpilot.enableChat": true,
  "openpilot.enableInlineCompletions": true,
  "openpilot.enableCodeLens": true
}
```

---

**Happy Coding with OpenPilot! 🚁✨**
