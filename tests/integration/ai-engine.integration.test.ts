import { describe, it, expect, beforeAll, beforeEach, jest, afterEach } from '@jest/globals';
import { AIEngine, AIProvider } from '@openpilot/core';
import {
  createTestAIConfig,
  createChatContext,
  createCompletionRequest,
  createMockOllamaResponse,
  createMockOllamaChatResponse,
} from '../helpers/test-helpers';

// Mock axios - uses the manual mock in __mocks__/axios.ts
jest.mock('axios');
import axios from 'axios';

// Get the mocked axios instance
const mockedAxios = axios as jest.Mocked<typeof axios>;
const mockCreate = mockedAxios.create as jest.MockedFunction<typeof axios.create>;
let mockPost: jest.MockedFunction<any>;
let mockGet: jest.MockedFunction<any>;

describe('AI Engine Integration Tests', () => {
  let engine: AIEngine;
  let config: ReturnType<typeof createTestAIConfig>;

  beforeAll(() => {
    config = createTestAIConfig(AIProvider.OLLAMA, 'codellama:7b');
    
    // Set up the mock axios instance
    const mockAxiosInstance = {
      post: jest.fn(),
      get: jest.fn(),
      interceptors: {
        request: { use: jest.fn(), eject: jest.fn() },
        response: { use: jest.fn(), eject: jest.fn() },
      },
    };
    mockPost = mockAxiosInstance.post as jest.MockedFunction<any>;
    mockGet = mockAxiosInstance.get as jest.MockedFunction<any>;
    mockCreate.mockReturnValue(mockAxiosInstance as any);
    
    engine = new AIEngine({ config });
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  beforeEach(() => {
    // Reset and provide default implementation for mocks
    mockPost.mockReset().mockImplementation(() => Promise.resolve({ data: {} }));
    mockGet.mockReset().mockImplementation(() => Promise.resolve({ data: {} }));
  });

  describe('Code Completion', () => {
    it.skip('should complete JavaScript code', async () => {
      const selectedCode = 'function add(a, b) {';
      const expectedCompletion = '  return a + b;\n}';

      mockPost.mockResolvedValueOnce(
        createMockOllamaResponse(expectedCompletion)
      );

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
      expect(response.completions[0].text).toContain('return');
      expect(mockPost).toHaveBeenCalledTimes(1);
    }, 30000);

    it.skip('should complete TypeScript code', async () => {
      const selectedCode = 'interface User {\n  name: string;';
      const expectedCompletion = '  age: number;\n  email: string;\n}';

      mockPost.mockResolvedValueOnce(
        createMockOllamaResponse(expectedCompletion)
      );

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
      expect(mockPost).toHaveBeenCalled();
    }, 30000);

    it.skip('should complete Python code', async () => {
      const selectedCode = 'def calculate_sum(numbers):';
      const expectedCompletion = '    total = sum(numbers)\n    return total';

      mockPost.mockResolvedValueOnce(
        createMockOllamaResponse(expectedCompletion)
      );

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
    }, 30000);
  });

  describe('Chat Functionality', () => {
    it.skip('should respond to a simple coding question', async () => {
      const chatContext = createChatContext([
        { role: 'user', content: 'What is a closure in JavaScript?' },
      ]);

      mockPost.mockResolvedValueOnce(
        createMockOllamaChatResponse(
          'A closure is a function that has access to variables in its outer scope.'
        )
      );

      const response = await engine.chat(chatContext);

      expect(response).toBeDefined();
      expect(response.content.toLowerCase()).toMatch(/closure|function|scope/);
    }, 30000);

    it.skip('should generate code from natural language', async () => {
      const chatContext = createChatContext([
        {
          role: 'user',
          content: 'Write a function that reverses a string in JavaScript',
        },
      ]);

      mockPost.mockResolvedValueOnce(
        createMockOllamaChatResponse(
          'function reverseString(str) {\n  return str.split("").reverse().join("");\n}'
        )
      );

      const response = await engine.chat(chatContext);

      expect(response).toBeDefined();
      expect(response.content).toContain('function');
    }, 30000);
  });

  describe('Error Handling', () => {
    it('should handle network errors gracefully', async () => {
      const chatContext = createChatContext([{ role: 'user', content: 'test' }]);

      mockPost.mockRejectedValueOnce(new Error('Network error'));

      await expect(engine.chat(chatContext)).rejects.toThrow();
    }, 30000);
  });

  describe('Performance', () => {
    it.skip('should complete requests within timeout', async () => {
      const startTime = Date.now();
      const chatContext = createChatContext([
        { role: 'user', content: 'Quick question' },
      ]);

      mockPost.mockResolvedValueOnce(
        createMockOllamaChatResponse('Quick answer')
      );

      await engine.chat(chatContext);

      const duration = Date.now() - startTime;
      expect(duration).toBeLessThan(10000);
    }, 30000);
  });
});
