// Local type definitions for Desktop app (browser-compatible)
// Mirrors types from @openpilot/core without Node.js dependencies

export enum AIProvider {
  OLLAMA = 'ollama',
  OPENAI = 'openai',
  GROK = 'grok',
  TOGETHER = 'together',
  HUGGINGFACE = 'huggingface',
  CUSTOM = 'custom'
}

export interface Message {
  id: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  timestamp: number; // Unix timestamp
}

export interface ChatContext {
  messages: Message[];
  systemPrompt?: string;
  temperature?: number;
  maxTokens?: number;
}

export interface AIConfig {
  provider: AIProvider;
  model: string;
  apiKey?: string;
  apiUrl?: string;
  temperature?: number;
  maxTokens?: number;
  offline?: boolean;
}

// Mock AIEngine class for UI purposes
// Desktop app should communicate with backend or Electron main process for actual AI calls
export class AIEngine {
  private config: AIConfig;

  constructor(config: AIConfig) {
    this.config = config;
  }

  async sendMessage(message: string, context?: ChatContext): Promise<string> {
    // In a real desktop app, this would communicate with:
    // - Electron main process (IPC)
    // - Backend server (HTTP/WebSocket)
    // - Local AI service (if available)
    
    console.log('AIEngine.sendMessage called (stub)');
    return 'This is a stub response. Implement actual AI communication.';
  }

  async streamChat(context: ChatContext, onChunk: (chunk: string) => void): Promise<string> {
    console.log('AIEngine.streamChat called (stub)');
    // Simulate streaming
    const response = 'This is a simulated streaming response.';
    onChunk(response);
    return response;
  }

  async generateCode(prompt: string, language?: string): Promise<string> {
    console.log('AIEngine.generateCode called (stub)');
    return '// Generated code placeholder';
  }

  async analyzeCode(code: string): Promise<string> {
    console.log('AIEngine.analyzeCode called (stub)');
    return 'Code analysis placeholder';
  }
}
