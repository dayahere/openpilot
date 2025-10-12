import * as vscode from 'vscode';
// import * as assert from 'assert'; // Unused
import { activate, deactivate } from '../extension';

// Mock VS Code API
jest.mock('vscode', () => ({
  workspace: {
    workspaceFolders: [{ uri: { fsPath: '/test/workspace' } }],
    getConfiguration: jest.fn(() => ({
      get: jest.fn((key) => {
        if (key === 'autoComplete') return true;
        return undefined;
      }),
    })),
    onDidChangeConfiguration: jest.fn(() => ({ dispose: jest.fn() })),
  },
  window: {
    registerWebviewViewProvider: jest.fn(() => ({ dispose: jest.fn() })),
    registerTreeDataProvider: jest.fn(() => ({ dispose: jest.fn() })),
  },
  languages: {
    registerInlineCompletionItemProvider: jest.fn(() => ({ dispose: jest.fn() })),
  },
  commands: {
    registerCommand: jest.fn(() => ({ dispose: jest.fn() })),
    executeCommand: jest.fn(),
  },
}));

// Mock @openpilot/core
jest.mock('@openpilot/core', () => ({
  AIEngine: jest.fn().mockImplementation(() => ({
    updateConfig: jest.fn(),
  })),
  ContextManager: jest.fn().mockImplementation(() => ({
    analyzeRepository: jest.fn().mockResolvedValue({}),
  })),
}));

// Mock providers and views
jest.mock('../views/chatView', () => ({
  ChatViewProvider: jest.fn().mockImplementation(() => ({})),
}));

jest.mock('../views/historyView', () => ({
  HistoryViewProvider: jest.fn().mockImplementation(() => ({})),
}));

jest.mock('../views/checkpointsView', () => ({
  CheckpointsViewProvider: jest.fn().mockImplementation(() => ({})),
}));

jest.mock('../providers/completionProvider', () => ({
  CompletionProvider: jest.fn().mockImplementation(() => ({})),
}));

jest.mock('../utils/configManager', () => ({
  ConfigurationManager: jest.fn().mockImplementation(() => ({
    getAIConfig: jest.fn().mockReturnValue({
      provider: 'ollama',
      model: 'codellama',
      temperature: 0.7,
      maxTokens: 2048,
    }),
  })),
}));

jest.mock('../utils/sessionManager', () => ({
  SessionManager: jest.fn().mockImplementation(() => ({})),
}));

jest.mock('../utils/checkpointManager', () => ({
  CheckpointManager: jest.fn().mockImplementation(() => ({})),
}));

describe('VSCode Extension', () => {
  let mockContext: vscode.ExtensionContext;

  beforeEach(() => {
    mockContext = {
      subscriptions: [],
      extensionUri: { fsPath: '/test/extension' } as any,
      globalState: {
        get: jest.fn(),
        update: jest.fn(),
        keys: jest.fn(() => []),
        setKeysForSync: jest.fn(),
      } as any,
      workspaceState: {
        get: jest.fn(),
        update: jest.fn(),
        keys: jest.fn(() => []),
      } as any,
    } as any;
  });

  describe('activate', () => {
    it('should activate without errors', async () => {
      await expect(activate(mockContext)).resolves.not.toThrow();
    });

    it('should register chat view provider', async () => {
      await activate(mockContext);
      expect(vscode.window.registerWebviewViewProvider).toHaveBeenCalledWith(
        'openpilot.chatView',
        expect.any(Object)
      );
    });

    it('should register history view provider', async () => {
      await activate(mockContext);
      expect(vscode.window.registerTreeDataProvider).toHaveBeenCalledWith(
        'openpilot.historyView',
        expect.any(Object)
      );
    });

    it('should register checkpoints view provider', async () => {
      await activate(mockContext);
      expect(vscode.window.registerTreeDataProvider).toHaveBeenCalledWith(
        'openpilot.checkpointsView',
        expect.any(Object)
      );
    });

    it('should register completion provider when enabled', async () => {
      await activate(mockContext);
      expect(vscode.languages.registerInlineCompletionItemProvider).toHaveBeenCalled();
    });

    it('should add subscriptions to context', async () => {
      await activate(mockContext);
      expect(mockContext.subscriptions.length).toBeGreaterThan(0);
    });

    it('should initialize AIEngine', async () => {
      const { AIEngine } = require('@openpilot/core');
      await activate(mockContext);
      expect(AIEngine).toHaveBeenCalled();
    });

    it('should initialize ContextManager with workspace root', async () => {
      const { ContextManager } = require('@openpilot/core');
      await activate(mockContext);
      expect(ContextManager).toHaveBeenCalledWith({
        rootPath: '/test/workspace',
      });
    });

    it('should analyze repository on startup', async () => {
      const { ContextManager } = require('@openpilot/core');
      await activate(mockContext);
      const instance = ContextManager.mock.results[0].value;
      expect(instance.analyzeRepository).toHaveBeenCalled();
    });

    it('should register configuration change listener', async () => {
      await activate(mockContext);
      expect(vscode.workspace.onDidChangeConfiguration).toHaveBeenCalled();
    });
  });

  describe('deactivate', () => {
    it('should deactivate without errors', () => {
      expect(() => deactivate()).not.toThrow();
    });
  });
});

