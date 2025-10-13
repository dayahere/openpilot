/**
 * AI Engine Advanced Tests - HTTP Error Handling
 * Coverage target: HTTP status codes, network errors, error responses
 */

import { describe, it, expect, jest, beforeEach } from '@jest/globals';
import { OllamaProvider, OpenAIProvider } from '../../core/src/ai-engine/index';
import { AIProvider } from '@openpilot/core';
import { createChatContext, createTestAIConfig } from '../helpers/test-helpers';

// Mock axios module
jest.mock('axios', () => {
  const actualAxios = jest.requireActual('axios');
  return {
    __esModule: true,
    default: {
      ...actualAxios.default,
      create: jest.fn(() => mockAxiosInstance),
      isAxiosError: jest.fn((error: any) => error && error.isAxiosError === true),
    },
    isAxiosError: jest.fn((error: any) => error && error.isAxiosError === true),
  };
});

const mockAxiosInstance = {
  post: jest.fn(),
  get: jest.fn(),
  defaults: {
    baseURL: '',
    headers: {},
  },
};

describe('AI Engine - HTTP Error Handling', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('HTTP 401 Unauthorized', () => {
    it('should handle 401 from Ollama', async () => {
      const config = createTestAIConfig(AIProvider.OLLAMA, 'codellama');
      const provider = new OllamaProvider(config);
      const context = createChatContext([{ role: 'user', content: 'test' }]);

      mockAxiosInstance.post.mockRejectedValueOnce({
        response: {
          status: 401,
          statusText: 'Unauthorized',
          data: { error: 'Invalid credentials' },
        },
        isAxiosError: true,
        message: 'Request failed with status code 401',
      });

      await expect(provider.chat(context)).rejects.toThrow();
    });

    it('should handle 401 from OpenAI', async () => {
      const config = createTestAIConfig(AIProvider.OPENAI, 'gpt-4');
      config.apiKey = 'invalid-key';
      const provider = new OpenAIProvider(config);
      const context = createChatContext([{ role: 'user', content: 'test' }]);

      mockedAxios.post.mockRejectedValueOnce({
        response: {
          status: 401,
          data: { error: { message: 'Invalid API key' } },
        },
        isAxiosError: true,
      });

      await expect(provider.chat(context)).rejects.toThrow();
    });
  });

  describe('HTTP 403 Forbidden', () => {
    it('should handle 403 access denied', async () => {
      const config = createTestAIConfig(AIProvider.OPENAI, 'gpt-4');
      config.apiKey = 'test-key';
      const provider = new OpenAIProvider(config);
      const context = createChatContext([{ role: 'user', content: 'test' }]);

      mockedAxios.post.mockRejectedValueOnce({
        response: {
          status: 403,
          data: { error: 'Access denied to this resource' },
        },
        isAxiosError: true,
      });

      await expect(provider.chat(context)).rejects.toThrow();
    });
  });

  describe('HTTP 429 Rate Limit', () => {
    it('should handle 429 with retry-after header', async () => {
      const config = createTestAIConfig(AIProvider.OPENAI, 'gpt-4');
      config.apiKey = 'test-key';
      const provider = new OpenAIProvider(config);
      const context = createChatContext([{ role: 'user', content: 'test' }]);

      mockedAxios.post.mockRejectedValueOnce({
        response: {
          status: 429,
          data: { error: 'Rate limit exceeded. Please try again later.' },
          headers: { 'retry-after': '60' },
        },
        isAxiosError: true,
      });

      await expect(provider.chat(context)).rejects.toThrow();
    });

    it('should handle 429 without retry-after header', async () => {
      const config = createTestAIConfig(AIProvider.OLLAMA, 'codellama');
      const provider = new OllamaProvider(config);
      const context = createChatContext([{ role: 'user', content: 'test' }]);

      mockedAxios.post.mockRejectedValueOnce({
        response: {
          status: 429,
          data: { error: 'Too many requests' },
        },
        isAxiosError: true,
      });

      await expect(provider.chat(context)).rejects.toThrow();
    });
  });

  describe('HTTP 500 Internal Server Error', () => {
    it('should handle 500 from Ollama', async () => {
      const config = createTestAIConfig(AIProvider.OLLAMA, 'codellama');
      const provider = new OllamaProvider(config);
      const context = createChatContext([{ role: 'user', content: 'test' }]);

      mockedAxios.post.mockRejectedValueOnce({
        response: {
          status: 500,
          data: { error: 'Internal server error' },
        },
        isAxiosError: true,
      });

      await expect(provider.chat(context)).rejects.toThrow();
    });

    it('should handle 500 with no error message', async () => {
      const config = createTestAIConfig(AIProvider.OLLAMA, 'codellama');
      const provider = new OllamaProvider(config);
      const context = createChatContext([{ role: 'user', content: 'test' }]);

      mockedAxios.post.mockRejectedValueOnce({
        response: {
          status: 500,
          data: {},
        },
        isAxiosError: true,
      });

      await expect(provider.chat(context)).rejects.toThrow();
    });
  });

  describe('HTTP 503 Service Unavailable', () => {
    it('should handle 503 service temporarily unavailable', async () => {
      const config = createTestAIConfig(AIProvider.OLLAMA, 'codellama');
      const provider = new OllamaProvider(config);
      const context = createChatContext([{ role: 'user', content: 'test' }]);

      mockedAxios.post.mockRejectedValueOnce({
        response: {
          status: 503,
          data: { error: 'Service temporarily unavailable' },
        },
        isAxiosError: true,
      });

      await expect(provider.chat(context)).rejects.toThrow();
    });
  });

  describe('HTTP 404 Not Found', () => {
    it('should handle 404 endpoint not found', async () => {
      const config = createTestAIConfig(AIProvider.OLLAMA, 'codellama');
      const provider = new OllamaProvider(config);
      const context = createChatContext([{ role: 'user', content: 'test' }]);

      mockedAxios.post.mockRejectedValueOnce({
        response: {
          status: 404,
          data: { error: 'Endpoint not found' },
        },
        isAxiosError: true,
      });

      await expect(provider.chat(context)).rejects.toThrow();
    });
  });

  describe('Network Errors', () => {
    it('should handle ECONNREFUSED', async () => {
      const config = createTestAIConfig(AIProvider.OLLAMA, 'codellama');
      const provider = new OllamaProvider(config);
      const context = createChatContext([{ role: 'user', content: 'test' }]);

      mockedAxios.post.mockRejectedValueOnce({
        code: 'ECONNREFUSED',
        message: 'connect ECONNREFUSED 127.0.0.1:11434',
        isAxiosError: true,
      });

      await expect(provider.chat(context)).rejects.toThrow();
    });

    it('should handle ETIMEDOUT', async () => {
      const config = createTestAIConfig(AIProvider.OLLAMA, 'codellama');
      const provider = new OllamaProvider(config);
      const context = createChatContext([{ role: 'user', content: 'test' }]);

      mockedAxios.post.mockRejectedValueOnce({
        code: 'ETIMEDOUT',
        message: 'timeout of 60000ms exceeded',
        isAxiosError: true,
      });

      await expect(provider.chat(context)).rejects.toThrow();
    });

    it('should handle ENOTFOUND DNS errors', async () => {
      const config = createTestAIConfig(AIProvider.OLLAMA, 'codellama');
      config.apiUrl = 'http://invalid-host:11434';
      const provider = new OllamaProvider(config);
      const context = createChatContext([{ role: 'user', content: 'test' }]);

      mockedAxios.post.mockRejectedValueOnce({
        code: 'ENOTFOUND',
        message: 'getaddrinfo ENOTFOUND invalid-host',
        isAxiosError: true,
      });

      await expect(provider.chat(context)).rejects.toThrow();
    });

    it('should handle ECONNABORTED', async () => {
      const config = createTestAIConfig(AIProvider.OLLAMA, 'codellama');
      const provider = new OllamaProvider(config);
      const context = createChatContext([{ role: 'user', content: 'test' }]);

      mockedAxios.post.mockRejectedValueOnce({
        code: 'ECONNABORTED',
        message: 'Connection aborted',
        isAxiosError: true,
      });

      await expect(provider.chat(context)).rejects.toThrow();
    });
  });

  describe('Non-Axios Errors', () => {
    it('should handle generic Error objects', async () => {
      const config = createTestAIConfig(AIProvider.OLLAMA, 'codellama');
      const provider = new OllamaProvider(config);
      const context = createChatContext([{ role: 'user', content: 'test' }]);

      mockedAxios.post.mockRejectedValueOnce(new Error('Generic error'));

      await expect(provider.chat(context)).rejects.toThrow();
    });

    it('should handle unknown error types', async () => {
      const config = createTestAIConfig(AIProvider.OLLAMA, 'codellama');
      const provider = new OllamaProvider(config);
      const context = createChatContext([{ role: 'user', content: 'test' }]);

      mockedAxios.post.mockRejectedValueOnce('String error');

      await expect(provider.chat(context)).rejects.toThrow();
    });

    it('should handle null/undefined errors', async () => {
      const config = createTestAIConfig(AIProvider.OLLAMA, 'codellama');
      const provider = new OllamaProvider(config);
      const context = createChatContext([{ role: 'user', content: 'test' }]);

      mockedAxios.post.mockRejectedValueOnce(null);

      await expect(provider.chat(context)).rejects.toThrow();
    });
  });
});

