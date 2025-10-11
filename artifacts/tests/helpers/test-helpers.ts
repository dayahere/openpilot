/**
 * Test Helper Utilities
 * Provides helper functions for creating properly typed test data
 */

import { v4 as uuid } from 'uuid';
import {
  Message,
  ChatContext,
  CompletionRequest,
  CodeContext,
  AIConfig,
  AIProvider,
  CompletionResponse,
  AIResponse,
  Completion,
} from '@openpilot/core';

/**
 * Creates a properly typed Message object
 */
export function createMessage(
  role: 'system' | 'user' | 'assistant',
  content: string,
  metadata?: Record<string, unknown>
): Message {
  return {
    id: uuid(),
    role,
    content,
    timestamp: Date.now(),
    metadata,
  };
}

/**
 * Creates a ChatContext with proper Message types
 */
export function createChatContext(
  messages: Array<{ role: 'system' | 'user' | 'assistant'; content: string }>,
  codeContext?: CodeContext
): ChatContext {
  return {
    messages: messages.map(msg => createMessage(msg.role, msg.content)),
    codeContext,
  };
}

/**
 * Creates a CodeContext for testing
 */
export function createCodeContext(
  language: string,
  selectedCode: string,
  fileName: string = 'test.ts',
  filePath: string = '/test/test.ts'
): CodeContext {
  return {
    language,
    fileName,
    filePath,
    lineStart: 1,
    lineEnd: 10,
    selectedCode,
    surroundingCode: selectedCode,
    imports: [],
    symbols: [],
  };
}

/**
 * Creates a CompletionRequest with proper types
 */
export function createCompletionRequest(
  prompt: string,
  language: string,
  selectedCode: string,
  config: AIConfig
): CompletionRequest {
  return {
    prompt,
    context: createCodeContext(language, selectedCode),
    config,
  };
}

/**
 * Creates a default AI configuration for testing
 */
export function createTestAIConfig(
  provider: AIProvider = AIProvider.OLLAMA,
  model: string = 'codellama:7b'
): AIConfig {
  return {
    provider,
    model,
    temperature: 0.7,
    maxTokens: 2048,
    topP: 0.9,
    frequencyPenalty: 0,
    presencePenalty: 0,
    offline: false,
    apiUrl: 'http://localhost:11434',
  };
}

/**
 * Mock axios response for Ollama API
 */
export function createMockOllamaResponse(content: string) {
  return {
    data: {
      model: 'codellama:7b',
      created_at: new Date().toISOString(),
      response: content,
      done: true,
    },
  };
}

/**
 * Mock axios response for Ollama Chat API
 */
export function createMockOllamaChatResponse(content: string) {
  return {
    data: {
      model: 'codellama:7b',
      created_at: new Date().toISOString(),
      message: {
        role: 'assistant',
        content,
      },
      done: true,
    },
  };
}

/**
 * Mock streaming response for Ollama
 */
export function createMockOllamaStreamChunk(content: string, done: boolean = false) {
  return `data: ${JSON.stringify({
    model: 'codellama:7b',
    created_at: new Date().toISOString(),
    response: content,
    done,
  })}\n\n`;
}

/**
 * Waits for a condition to be true (useful for async tests)
 */
export async function waitFor(
  condition: () => boolean,
  timeout: number = 5000,
  interval: number = 100
): Promise<void> {
  const startTime = Date.now();
  while (!condition()) {
    if (Date.now() - startTime > timeout) {
      throw new Error('Timeout waiting for condition');
    }
    await new Promise(resolve => setTimeout(resolve, interval));
  }
}

/**
 * Creates a mock repository structure for testing
 */
export function createMockRepository(rootPath: string) {
  return {
    rootPath,
    files: [
      {
        path: `${rootPath}/package.json`,
        relativePath: 'package.json',
        language: 'json',
        size: 1024,
        lastModified: Date.now(),
      },
      {
        path: `${rootPath}/src/index.ts`,
        relativePath: 'src/index.ts',
        language: 'typescript',
        size: 2048,
        lastModified: Date.now(),
      },
    ],
    dependencies: [
      { name: 'axios', version: '1.6.2', type: 'npm' as const },
      { name: 'typescript', version: '5.3.2', type: 'npm' as const },
    ],
  };
}

/**
 * Creates a mock CompletionResponse for testing
 */
export function createMockCompletionResponse(
  text: string,
  confidence: number = 0.9,
  offset: number = 0
): CompletionResponse {
  const completion: Completion = {
    text,
    confidence,
    offset,
  };

  return {
    completions: [completion],
  };
}

/**
 * Creates a mock AIResponse for testing
 */
export function createMockAIResponse(
  content: string,
  model: string = 'codellama:7b'
): AIResponse {
  return {
    id: uuid(),
    content,
    role: 'assistant',
    timestamp: Date.now(),
    model,
  };
}

