import * as vscode from 'vscode';
import { AIEngine, ContextManager, ChatContext, Message } from '@openpilot/core';
import { SessionManager } from '../utils/sessionManager';
import { getNonce } from '../utils/webview';

export class ChatViewProvider implements vscode.WebviewViewProvider {
  private _view?: vscode.WebviewView;

  constructor(
    private readonly _extensionUri: vscode.Uri,
    private aiEngine: AIEngine,
    private contextManager: ContextManager,
    private sessionManager: SessionManager
  ) {}

  public resolveWebviewView(
    webviewView: vscode.WebviewView,
    _context: vscode.WebviewViewResolveContext,
    _token: vscode.CancellationToken
  ) {
    this._view = webviewView;

    webviewView.webview.options = {
      enableScripts: true,
      localResourceRoots: [this._extensionUri],
    };

    webviewView.webview.html = this._getHtmlForWebview(webviewView.webview);

    // Handle messages from webview
    webviewView.webview.onDidReceiveMessage(async (data) => {
      switch (data.type) {
        case 'sendMessage':
          await this.handleUserMessage(data.message);
          break;
        case 'clearChat':
          this.sessionManager.clearCurrentSession();
          break;
      }
    });

    // Load session history
    const session = this.sessionManager.getCurrentSession();
    if (session) {
      this._view.webview.postMessage({
        type: 'loadHistory',
        messages: session.messages,
      });
    }
  }

  public async sendMessage(message: string) {
    if (!this._view) return;

    // Add user message to UI
    this._view.webview.postMessage({
      type: 'addMessage',
      message: {
        role: 'user',
        content: message,
        timestamp: Date.now(),
      },
    });

    await this.handleUserMessage(message);
  }

  private async handleUserMessage(content: string) {
    if (!this._view) return;

    try {
      // Get current editor context
      const codeContext = await this.getCurrentCodeContext();

      // Build chat context
      const session = this.sessionManager.getCurrentSession();
      const userMessage: Message = {
        id: `msg-${Date.now()}`,
        role: 'user',
        content,
        timestamp: Date.now(),
      };

      const messages = [...(session?.messages || []), userMessage];
      const chat_context: ChatContext = {
        messages,
        codeContext,
      };

      // Save user message
      this.sessionManager.addMessage(userMessage);

      // Show typing indicator
      this._view.webview.postMessage({ type: 'typing', isTyping: true });

      // Stream response
      let assistantContent = '';
      const response = await this.aiEngine.streamChat(chat_context, (chunk) => {
        assistantContent += chunk;
        this._view?.webview.postMessage({
          type: 'streamChunk',
          content: chunk,
        });
      });

      // Hide typing indicator
      this._view.webview.postMessage({ type: 'typing', isTyping: false });

      // Save assistant message
      this.sessionManager.addMessage({
        id: response.id,
        role: 'assistant',
        content: assistantContent,
        timestamp: response.timestamp,
      });

      // Send complete message
      this._view.webview.postMessage({
        type: 'addMessage',
        message: {
          role: 'assistant',
          content: assistantContent,
          timestamp: response.timestamp,
        },
      });
    } catch (error) {
      this._view.webview.postMessage({ type: 'typing', isTyping: false });
      this._view.webview.postMessage({
        type: 'error',
        message: `Error: ${error instanceof Error ? error.message : 'Unknown error'}`,
      });
    }
  }

  private async getCurrentCodeContext() {
    const editor = vscode.window.activeTextEditor;
    if (!editor || !this.contextManager) return undefined;

    const document = editor.document;
    const selection = editor.selection;

    if (selection.isEmpty) return undefined;

    const lineStart = selection.start.line + 1;
    const lineEnd = selection.end.line + 1;

    return this.contextManager.getCodeContext(document.uri.fsPath, lineStart, lineEnd);
  }

  private _getHtmlForWebview(webview: vscode.Webview) {
    const nonce = getNonce();

    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src ${webview.cspSource} 'unsafe-inline'; script-src 'nonce-${nonce}';">
  <title>OpenPilot Chat</title>
  <style>
    body {
      padding: 0;
      margin: 0;
      font-family: var(--vscode-font-family);
      color: var(--vscode-foreground);
      background-color: var(--vscode-editor-background);
    }
    #chat-container {
      display: flex;
      flex-direction: column;
      height: 100vh;
    }
    #messages {
      flex: 1;
      overflow-y: auto;
      padding: 10px;
    }
    .message {
      margin-bottom: 15px;
      padding: 10px;
      border-radius: 5px;
    }
    .message.user {
      background-color: var(--vscode-input-background);
      margin-left: 20px;
    }
    .message.assistant {
      background-color: var(--vscode-editor-inactiveSelectionBackground);
      margin-right: 20px;
    }
    .message-role {
      font-weight: bold;
      margin-bottom: 5px;
      font-size: 0.9em;
      opacity: 0.8;
    }
    .message-content {
      white-space: pre-wrap;
      word-wrap: break-word;
    }
    .message-content code {
      background-color: var(--vscode-textCodeBlock-background);
      padding: 2px 4px;
      border-radius: 3px;
    }
    .message-content pre {
      background-color: var(--vscode-textCodeBlock-background);
      padding: 10px;
      border-radius: 5px;
      overflow-x: auto;
    }
    .typing-indicator {
      display: none;
      padding: 10px;
      font-style: italic;
      opacity: 0.7;
    }
    .typing-indicator.active {
      display: block;
    }
    #input-container {
      display: flex;
      padding: 10px;
      border-top: 1px solid var(--vscode-panel-border);
      background-color: var(--vscode-editor-background);
    }
    #message-input {
      flex: 1;
      padding: 8px;
      background-color: var(--vscode-input-background);
      color: var(--vscode-input-foreground);
      border: 1px solid var(--vscode-input-border);
      border-radius: 3px;
      font-family: var(--vscode-font-family);
      resize: none;
    }
    #send-button {
      margin-left: 5px;
      padding: 8px 15px;
      background-color: var(--vscode-button-background);
      color: var(--vscode-button-foreground);
      border: none;
      border-radius: 3px;
      cursor: pointer;
    }
    #send-button:hover {
      background-color: var(--vscode-button-hoverBackground);
    }
  </style>
</head>
<body>
  <div id="chat-container">
    <div id="messages"></div>
    <div class="typing-indicator" id="typing-indicator">AI is thinking...</div>
    <div id="input-container">
      <textarea id="message-input" placeholder="Ask OpenPilot anything..." rows="3"></textarea>
      <button id="send-button">Send</button>
    </div>
  </div>

  <script nonce="${nonce}">
    const vscode = acquireVsCodeApi();
    const messagesDiv = document.getElementById('messages');
    const messageInput = document.getElementById('message-input');
    const sendButton = document.getElementById('send-button');
    const typingIndicator = document.getElementById('typing-indicator');

    let currentStreamMessage = null;

    sendButton.addEventListener('click', sendMessage);
    messageInput.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        sendMessage();
      }
    });

    function sendMessage() {
      const message = messageInput.value.trim();
      if (!message) return;

      vscode.postMessage({
        type: 'sendMessage',
        message: message
      });

      messageInput.value = '';
      messageInput.style.height = 'auto';
    }

    function addMessage(message) {
      const messageDiv = document.createElement('div');
      messageDiv.className = \`message \${message.role}\`;
      
      const roleDiv = document.createElement('div');
      roleDiv.className = 'message-role';
      roleDiv.textContent = message.role === 'user' ? 'You' : 'OpenPilot';
      
      const contentDiv = document.createElement('div');
      contentDiv.className = 'message-content';
      contentDiv.innerHTML = formatContent(message.content);
      
      messageDiv.appendChild(roleDiv);
      messageDiv.appendChild(contentDiv);
      messagesDiv.appendChild(messageDiv);
      
      messagesDiv.scrollTop = messagesDiv.scrollHeight;
      return messageDiv;
    }

    function formatContent(content) {
      // Simple markdown-like formatting
      return content
        .replace(/\`\`\`([\\s\\S]*?)\`\`\`/g, '<pre><code>$1</code></pre>')
        .replace(/\`([^\`]+)\`/g, '<code>$1</code>')
        .replace(/\\n/g, '<br>');
    }

    window.addEventListener('message', event => {
      const message = event.data;
      
      switch (message.type) {
        case 'addMessage':
          addMessage(message.message);
          break;
          
        case 'streamChunk':
          if (!currentStreamMessage) {
            currentStreamMessage = addMessage({
              role: 'assistant',
              content: message.content
            });
          } else {
            const contentDiv = currentStreamMessage.querySelector('.message-content');
            contentDiv.innerHTML = formatContent(
              contentDiv.textContent + message.content
            );
            messagesDiv.scrollTop = messagesDiv.scrollHeight;
          }
          break;
          
        case 'typing':
          typingIndicator.classList.toggle('active', message.isTyping);
          if (!message.isTyping) {
            currentStreamMessage = null;
          }
          break;
          
        case 'loadHistory':
          messagesDiv.innerHTML = '';
          message.messages.forEach(addMessage);
          break;
          
        case 'error':
          const errorDiv = addMessage({
            role: 'assistant',
            content: message.message
          });
          errorDiv.style.borderLeft = '3px solid var(--vscode-errorForeground)';
          break;
      }
    });
  </script>
</body>
</html>`;
  }
}

