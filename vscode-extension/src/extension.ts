import * as vscode from 'vscode';
import { AIEngine, ContextManager } from '@openpilot/core';
import { ChatViewProvider } from './views/chatView';
import { HistoryViewProvider } from './views/historyView';
import { CheckpointsViewProvider } from './views/checkpointsView';
import { CompletionProvider } from './providers/completionProvider';
import { ConfigurationManager } from './utils/configManager';
import { SessionManager } from './utils/sessionManager';
import { CheckpointManager } from './utils/checkpointManager';

let aiEngine: AIEngine;
let contextManager: ContextManager;
let sessionManager: SessionManager;
let checkpointManager: CheckpointManager;

export async function activate(context: vscode.ExtensionContext) {
  console.log('OpenPilot extension is now active!');

  // Initialize configuration
  const configManager = new ConfigurationManager();
  const config = configManager.getAIConfig();

  // Initialize AI engine
  aiEngine = new AIEngine({ config });

  // Initialize context manager
  const workspaceRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
  if (workspaceRoot) {
    contextManager = new ContextManager({ rootPath: workspaceRoot });
  }

  // Initialize session and checkpoint managers
  sessionManager = new SessionManager(context);
  checkpointManager = new CheckpointManager(context);

  // Watch for configuration changes
  context.subscriptions.push(
    vscode.workspace.onDidChangeConfiguration((e) => {
      if (e.affectsConfiguration('openpilot')) {
        const newConfig = configManager.getAIConfig();
        aiEngine.updateConfig(newConfig);
        console.log('OpenPilot configuration updated:', newConfig);
        vscode.window.showInformationMessage('OpenPilot configuration updated!');
      }
    })
  );

  // Register views
  const chatViewProvider = new ChatViewProvider(
    context.extensionUri,
    aiEngine,
    contextManager,
    sessionManager
  );
  context.subscriptions.push(
    vscode.window.registerWebviewViewProvider('openpilot.chatView', chatViewProvider)
  );

  const historyViewProvider = new HistoryViewProvider(sessionManager);
  context.subscriptions.push(
    vscode.window.registerTreeDataProvider('openpilot.historyView', historyViewProvider)
  );

  const checkpointsViewProvider = new CheckpointsViewProvider(checkpointManager);
  context.subscriptions.push(
    vscode.window.registerTreeDataProvider('openpilot.checkpointsView', checkpointsViewProvider)
  );

  // Register completion provider if enabled
  if (vscode.workspace.getConfiguration('openpilot').get('autoComplete')) {
    const completionProvider = new CompletionProvider(aiEngine, contextManager);
    context.subscriptions.push(
      vscode.languages.registerInlineCompletionItemProvider(
        { pattern: '**' },
        completionProvider
      )
    );
  }

  // Register commands
  registerCommands(context, chatViewProvider);

  // Listen for configuration changes
  context.subscriptions.push(
    vscode.workspace.onDidChangeConfiguration((e) => {
      if (e.affectsConfiguration('openpilot')) {
        const newConfig = configManager.getAIConfig();
        aiEngine.updateConfig(newConfig);
      }
    })
  );

  // Analyze repository on startup
  if (contextManager) {
    contextManager.analyzeRepository().catch((error) => {
      console.error('Failed to analyze repository:', error);
    });
  }
}

function registerCommands(
  context: vscode.ExtensionContext,
  chatViewProvider: ChatViewProvider
) {
  // Open chat
  context.subscriptions.push(
    vscode.commands.registerCommand('openpilot.openChat', () => {
      vscode.commands.executeCommand('openpilot.chatView.focus');
    })
  );

  // Explain code
  context.subscriptions.push(
    vscode.commands.registerCommand('openpilot.explainCode', async () => {
      const editor = vscode.window.activeTextEditor;
      if (!editor) return;

      const selection = editor.selection;
      const text = editor.document.getText(selection);

      if (!text) {
        vscode.window.showWarningMessage('Please select code to explain');
        return;
      }

      chatViewProvider.sendMessage(`Explain this code:\n\`\`\`\n${text}\n\`\`\``);
      vscode.commands.executeCommand('openpilot.chatView.focus');
    })
  );

  // Generate code
  context.subscriptions.push(
    vscode.commands.registerCommand('openpilot.generateCode', async () => {
      const prompt = await vscode.window.showInputBox({
        prompt: 'What code would you like to generate?',
        placeHolder: 'e.g., Create a function to sort an array',
      });

      if (!prompt) return;

      chatViewProvider.sendMessage(prompt);
      vscode.commands.executeCommand('openpilot.chatView.focus');
    })
  );

  // Refactor code
  context.subscriptions.push(
    vscode.commands.registerCommand('openpilot.refactorCode', async () => {
      const editor = vscode.window.activeTextEditor;
      if (!editor) return;

      const selection = editor.selection;
      const text = editor.document.getText(selection);

      if (!text) {
        vscode.window.showWarningMessage('Please select code to refactor');
        return;
      }

      const instruction = await vscode.window.showInputBox({
        prompt: 'How should this code be refactored?',
        placeHolder: 'e.g., Make it more readable, optimize performance',
      });

      if (!instruction) return;

      chatViewProvider.sendMessage(
        `Refactor this code (${instruction}):\n\`\`\`\n${text}\n\`\`\``
      );
      vscode.commands.executeCommand('openpilot.chatView.focus');
    })
  );

  // Fix code
  context.subscriptions.push(
    vscode.commands.registerCommand('openpilot.fixCode', async () => {
      const editor = vscode.window.activeTextEditor;
      if (!editor) return;

      const selection = editor.selection;
      const text = editor.document.getText(selection);

      if (!text) {
        vscode.window.showWarningMessage('Please select code to fix');
        return;
      }

      chatViewProvider.sendMessage(`Fix issues in this code:\n\`\`\`\n${text}\n\`\`\``);
      vscode.commands.executeCommand('openpilot.chatView.focus');
    })
  );

  // Analyze repository
  context.subscriptions.push(
    vscode.commands.registerCommand('openpilot.analyzeRepo', async () => {
      if (!contextManager) {
        vscode.window.showErrorMessage('No workspace opened');
        return;
      }

      await vscode.window.withProgress(
        {
          location: vscode.ProgressLocation.Notification,
          title: 'Analyzing repository...',
          cancellable: false,
        },
        async () => {
          await contextManager.analyzeRepository();
          vscode.window.showInformationMessage('Repository analysis complete!');
        }
      );
    })
  );

  // Configure
  context.subscriptions.push(
    vscode.commands.registerCommand('openpilot.configure', () => {
      vscode.commands.executeCommand('workbench.action.openSettings', 'openpilot');
    })
  );

  // Create checkpoint
  context.subscriptions.push(
    vscode.commands.registerCommand('openpilot.createCheckpoint', async () => {
      const description = await vscode.window.showInputBox({
        prompt: 'Checkpoint description',
        placeHolder: 'e.g., Before major refactoring',
      });

      const session = sessionManager.getCurrentSession();
      if (!session) {
        vscode.window.showWarningMessage('No active session');
        return;
      }

      await checkpointManager.createCheckpoint(session.id, description || '');
      vscode.window.showInformationMessage('Checkpoint created!');
    })
  );

  // Restore checkpoint
  context.subscriptions.push(
    vscode.commands.registerCommand('openpilot.restoreCheckpoint', async () => {
      const checkpoints = checkpointManager.getCheckpoints();
      if (checkpoints.length === 0) {
        vscode.window.showWarningMessage('No checkpoints available');
        return;
      }

      const items = checkpoints.map((cp) => ({
        label: cp.description || 'Unnamed checkpoint',
        detail: new Date(cp.timestamp).toLocaleString(),
        checkpoint: cp,
      }));

      const selected = await vscode.window.showQuickPick(items, {
        placeHolder: 'Select a checkpoint to restore',
      });

      if (selected) {
        await checkpointManager.restoreCheckpoint(selected.checkpoint.id);
        vscode.window.showInformationMessage('Checkpoint restored!');
      }
    })
  );
}

export function deactivate() {
  console.log('OpenPilot extension deactivated');
}
