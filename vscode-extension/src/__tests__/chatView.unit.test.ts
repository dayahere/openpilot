import { ChatViewProvider } from '../views/chatView';
import { Message } from '@openpilot/core';

// Mock AIEngine
class MockAIEngine {
  public updateConfig = jest.fn();
  public async streamChat(_ctx: any, onChunk: (c: string) => void) {
    onChunk('Hello');
    onChunk(' World');
    return {
      id: 'resp-1',
      content: 'Hello World',
      role: 'assistant' as const,
      timestamp: Date.now(),
      model: 'test',
    };
  }
}

// Mock ContextManager
class MockContextManager {
  public getCodeContext = jest.fn().mockResolvedValue(undefined);
}

// Mock SessionManager
class MockSessionManager {
  private session = {
    id: 's1',
    messages: [] as Message[],
    createdAt: Date.now(),
    updatedAt: Date.now(),
  };

  getCurrentSession() {
    return this.session;
  }
  
  addMessage = jest.fn((m: Message) => {
    this.session.messages.push(m);
  });
  
  clearCurrentSession = jest.fn(() => {
    this.session.messages = [];
  });
}

describe('ChatViewProvider webview config and messaging', () => {
  let provider: ChatViewProvider;
  let mockEngine: MockAIEngine;
  let mockSession: MockSessionManager;
  let mockContext: any;
  let mockWebview: any;
  let messageCallback: (data: any) => Promise<void>;

  beforeEach(() => {
    mockEngine = new MockAIEngine();
    mockSession = new MockSessionManager();
    mockContext = {
      globalState: {
        get: jest.fn().mockReturnValue(null),
        update: jest.fn().mockResolvedValue(undefined),
      },
      subscriptions: [],
      extensionUri: { fsPath: '/test', scheme: 'file' },
    };

    const uri: any = { fsPath: '/test', scheme: 'file' };
    provider = new ChatViewProvider(
      mockContext as any,
      uri as any,
      mockEngine as any,
      new MockContextManager() as any,
      mockSession as any
    );

    // Setup fake webview environment
    mockWebview = {
      options: {},
      html: '',
      cspSource: 'test-csp',
      onDidReceiveMessage: jest.fn((cb: any) => {
        messageCallback = cb;
        return { dispose: jest.fn() };
      }),
      postMessage: jest.fn().mockResolvedValue(true),
    };

    const mockWebviewView: any = {
      webview: mockWebview,
    };

    // Resolve webview view to initialize
    provider.resolveWebviewView(mockWebviewView, {} as any, {} as any);
  });

  it('updateConfig triggers engine.updateConfig and posts configUpdated', async () => {
    await messageCallback({
      type: 'updateConfig',
      payload: {
        provider: 'openai',
        model: 'gpt-4.1',
        temperature: 1.2,
        mode: 'chat',
      },
    });

    expect(mockEngine.updateConfig).toHaveBeenCalledWith(
      expect.objectContaining({
        provider: 'openai',
        model: 'gpt-4.1',
        temperature: 1.2,
      })
    );

    expect(mockWebview.postMessage).toHaveBeenCalledWith(
      expect.objectContaining({
        type: 'configUpdated',
        config: expect.objectContaining({
          provider: 'openai',
          model: 'gpt-4.1',
          mode: 'chat',
        }),
      })
    );

    expect(mockContext.globalState.update).toHaveBeenCalledWith(
      'openpilot.preferences',
      expect.objectContaining({
        provider: 'openai',
        model: 'gpt-4.1',
        mode: 'chat',
      })
    );
  });

  it('requestConfig posts loadConfig with defaults or persisted values', async () => {
    await messageCallback({ type: 'requestConfig' });

    expect(mockWebview.postMessage).toHaveBeenCalledWith(
      expect.objectContaining({
        type: 'loadConfig',
        config: expect.objectContaining({
          mode: expect.any(String),
          provider: expect.any(String),
          model: expect.any(String),
        }),
      })
    );
  });

  it('mode switching changes sessionPreferences and posts configUpdated', async () => {
    await messageCallback({
      type: 'updateConfig',
      payload: { mode: 'agent', provider: 'ollama', model: 'codellama', temperature: 0.7 },
    });

    expect(mockWebview.postMessage).toHaveBeenCalledWith(
      expect.objectContaining({
        type: 'configUpdated',
        config: expect.objectContaining({ mode: 'agent' }),
      })
    );

    // Switch to chat mode
    await messageCallback({
      type: 'updateConfig',
      payload: { mode: 'chat', provider: 'ollama', model: 'codellama', temperature: 0.7 },
    });

    expect(mockWebview.postMessage).toHaveBeenCalledWith(
      expect.objectContaining({
        type: 'configUpdated',
        config: expect.objectContaining({ mode: 'chat' }),
      })
    );
  });

  it('sendMessage appends user and streams assistant chunks', async () => {
    await provider.sendMessage('Hi');

    // User message should be posted
    expect(mockWebview.postMessage).toHaveBeenCalledWith(
      expect.objectContaining({
        type: 'addMessage',
        message: expect.objectContaining({
          role: 'user',
          content: 'Hi',
        }),
      })
    );

    // Session should have user message added
    expect(mockSession.addMessage).toHaveBeenCalled();

    // Stream chunks should be posted
    expect(mockWebview.postMessage).toHaveBeenCalledWith(
      expect.objectContaining({
        type: 'streamChunk',
        content: expect.any(String),
      })
    );

    // Final assistant message should be added to session
    const addMessageCalls = mockSession.addMessage.mock.calls;
    const assistantMessage = addMessageCalls.find(
      (call: any[]) => call[0].role === 'assistant'
    );
    expect(assistantMessage).toBeDefined();
  });

  it('clearChat clears session', async () => {
    await messageCallback({ type: 'clearChat' });
    expect(mockSession.clearCurrentSession).toHaveBeenCalled();
  });

  it('handles sendMessage via message handler', async () => {
    await messageCallback({ type: 'sendMessage', message: 'Test message' });

    expect(mockSession.addMessage).toHaveBeenCalled();
    expect(mockWebview.postMessage).toHaveBeenCalledWith(
      expect.objectContaining({ type: 'addMessage' })
    );
  });
});
