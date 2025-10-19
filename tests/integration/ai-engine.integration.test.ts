import { describe, it, expect, beforeAll, beforeEach, jest, afterEach } from '@jest/globals';
import { AIEngine, AIProvider } from '@openpilot/core';
import {
  createTestAIConfig,
  createChatContext,
  createCompletionRequest,
  createMockOllamaResponse,
  createMockOllamaChatResponse,
} from '../helpers/test-helpers';


describe('AI Engine Integration Tests', () => {
  let engine: AIEngine;
  let config: ReturnType<typeof createTestAIConfig>;

  beforeAll(() => {
  process.env.OLLAMA_API_URL = 'http://host.docker.internal:11434';
    config = createTestAIConfig(AIProvider.OLLAMA, 'llama2');
    engine = new AIEngine({ config });
  });

  // Removed duplicate and invalid beforeAll

  afterEach(() => {
    jest.clearAllMocks();
  });

  beforeEach(() => {

  });

  describe('Code Completion', () => {
  it('should complete JavaScript code', async () => {
      const selectedCode = 'function add(a, b) {';
      const request = createCompletionRequest(
        'Complete this function',
        'javascript',
        selectedCode,
        config
      );

      const response = await engine.complete(request);

      expect(response).toBeDefined();
      expect(response.completions).toBeDefined();
      expect(response.completions.length).toBeGreaterThan(0);
    expect(response.completions[0].text).toMatch(/function add\(/);
  }, 85000);

  it('should complete TypeScript code', async () => {
      const selectedCode = 'interface User {\n  name: string;';
      const request = createCompletionRequest(
        'Complete this interface',
        'typescript',
        selectedCode,
        config
      );

      const response = await engine.complete(request);

      expect(response).toBeDefined();
      expect(response.completions).toBeDefined();
      expect(response.completions.length).toBeGreaterThan(0);
      expect(response.completions[0].text).toBeTruthy();
  }, 60000);

  it('should complete Python code', async () => {
      const selectedCode = 'def calculate_sum(numbers):';
      const request = createCompletionRequest(
        'Complete this function',
        'python',
        selectedCode,
        config
      );

      const response = await engine.complete(request);

      expect(response).toBeDefined();
      expect(response.completions).toBeDefined();
      expect(response.completions.length).toBeGreaterThan(0);
      expect(response.completions[0].text).toBeTruthy();
  }, 60000);
  });

  describe('Chat Functionality', () => {

  it('should respond to a simple coding question', async () => {
      const chatContext = createChatContext([
        { role: 'user', content: 'Explain closure in JS.' },
      ]);

      const response = await engine.chat(chatContext);

      expect(response).toBeDefined();
      expect(response.content.toLowerCase()).toMatch(/closure|function|scope/);
  }, 85000);

  it('should generate code from natural language', async () => {

      const chatContext = createChatContext([
        {
          role: 'user',
          content: 'Write a function that reverses a string in JavaScript',
        },
      ]);

      const response = await engine.chat(chatContext);

      expect(response).toBeDefined();
      expect(response.content).toContain('function');
  }, 85000);
  });

  describe('Error Handling', () => {
    it('should handle network errors gracefully', async () => {
      const chatContext = createChatContext([{ role: 'user', content: 'test' }]);
      // For true integration, this test should simulate a real network error, e.g., by using an invalid API URL
      process.env.OLLAMA_API_URL = 'http://invalid:9999';
      const engineWithBadUrl = new AIEngine({ config: createTestAIConfig(AIProvider.OLLAMA, 'llama2') });
      await expect(engineWithBadUrl.chat(chatContext)).rejects.toThrow();
    }, 30000);
  });

  describe('Performance', () => {
  it('should complete requests within timeout', async () => {
      const startTime = Date.now();
      const chatContext = createChatContext([
        { role: 'user', content: 'Quick question' },
      ]);

      await engine.chat(chatContext);

      const duration = Date.now() - startTime;
  expect(duration).toBeLessThan(35000);
    }, 30000);
  });
});
