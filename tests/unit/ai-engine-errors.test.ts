/**
 * AI Engine - Error Handling Tests
 * Coverage: Error types, error messages, provider error handling
 */

import { describe, it, expect } from '@jest/globals';
import { AIProviderError } from '@openpilot/core';

describe('AI Engine - Error Handling', () => {
  describe('AIProviderError', () => {
    it('should create error with message', () => {
      const error = new AIProviderError('Test error');
      
      expect(error.message).toBe('Test error');
      expect(error.name).toBe('AIProviderError');
    });

    it('should create error with status', () => {
      const error = new AIProviderError('HTTP error', {
        status: 401,
      });
      
      expect(error.message).toBe('HTTP error');
      expect(error.details?.status).toBe(401);
    });

    it('should create error with data', () => {
      const error = new AIProviderError('API error', {
        data: { error: 'Invalid request' },
      });
      
      expect(error.details?.data).toEqual({ error: 'Invalid request' });
    });

    it('should handle error without details', () => {
      const error = new AIProviderError('Simple error');
      
      expect(error.details).toBeUndefined();
    });

    it('should be instance of Error', () => {
      const error = new AIProviderError('Test');
      
      expect(error instanceof Error).toBe(true);
      expect(error instanceof AIProviderError).toBe(true);
    });
  });

  describe('HTTP Status Code Errors', () => {
    it('should handle 401 Unauthorized', () => {
      const error = new AIProviderError('Unauthorized', {
        status: 401,
        data: { error: 'Invalid credentials' },
      });

      expect(error.details?.status).toBe(401);
      expect(error.message).toContain('Unauthorized');
    });

    it('should handle 403 Forbidden', () => {
      const error = new AIProviderError('Forbidden', {
        status: 403,
      });

      expect(error.details?.status).toBe(403);
    });

    it('should handle 429 Rate Limit', () => {
      const error = new AIProviderError('Rate limit exceeded', {
        status: 429,
        data: { 'retry-after': 60 },
      });

      expect(error.details?.status).toBe(429);
      expect(error.details?.data).toHaveProperty('retry-after');
    });

    it('should handle 500 Internal Server Error', () => {
      const error = new AIProviderError('Internal server error', {
        status: 500,
        data: { error: 'Database connection failed' },
      });

      expect(error.details?.status).toBe(500);
    });

    it('should handle 503 Service Unavailable', () => {
      const error = new AIProviderError('Service unavailable', {
        status: 503,
      });

      expect(error.details?.status).toBe(503);
    });

    it('should handle 404 Not Found', () => {
      const error = new AIProviderError('Endpoint not found', {
        status: 404,
      });

      expect(error.details?.status).toBe(404);
    });
  });

  describe('Network Errors', () => {
    it('should handle connection refused', () => {
      const error = new AIProviderError('Connection refused', {
        code: 'ECONNREFUSED',
      });

      expect(error.message).toContain('Connection refused');
      expect(error.details?.code).toBe('ECONNREFUSED');
    });

    it('should handle connection timeout', () => {
      const error = new AIProviderError('Connection timeout', {
        code: 'ETIMEDOUT',
      });

      expect(error.details?.code).toBe('ETIMEDOUT');
    });

    it('should handle DNS resolution failure', () => {
      const error = new AIProviderError('DNS lookup failed', {
        code: 'ENOTFOUND',
      });

      expect(error.details?.code).toBe('ENOTFOUND');
    });

    it('should handle connection abort', () => {
      const error = new AIProviderError('Connection aborted', {
        code: 'ECONNABORTED',
      });

      expect(error.details?.code).toBe('ECONNABORTED');
    });

    it('should handle network unreachable', () => {
      const error = new AIProviderError('Network unreachable', {
        code: 'ENETUNREACH',
      });

      expect(error.details?.code).toBe('ENETUNREACH');
    });
  });

  describe('Error Message Formatting', () => {
    it('should format error with status and message', () => {
      const error = new AIProviderError('Request failed: Unauthorized', {
        status: 401,
      });

      expect(error.message).toContain('Unauthorized');
      expect(error.details?.status).toBe(401);
    });

    it('should include error details in message', () => {
      const error = new AIProviderError('API request failed: Invalid API key', {
        status: 401,
        data: { error: 'api_key_invalid' },
      });

      expect(error.message).toContain('Invalid API key');
      expect(error.details?.data?.error).toBe('api_key_invalid');
    });

    it('should handle errors without status', () => {
      const error = new AIProviderError('Unknown error occurred');

      expect(error.message).toBe('Unknown error occurred');
      expect(error.details).toBeUndefined();
    });

    it('should handle empty error messages', () => {
      const error = new AIProviderError('', {
        status: 500,
      });

      expect(error.message).toBe('');
      expect(error.details?.status).toBe(500);
    });
  });

  describe('Error Details', () => {
    it('should preserve error details', () => {
      const details = {
        status: 400,
        data: { errors: ['Invalid field'] },
        code: 'VALIDATION_ERROR',
        timestamp: new Date().toISOString(),
      };

      const error = new AIProviderError('Validation failed', details);

      expect(error.details).toEqual(details);
    });

    it('should handle null details', () => {
      const error = new AIProviderError('Error', null as any);

      expect(error.details).toBeNull();
    });

    it('should handle undefined details', () => {
      const error = new AIProviderError('Error', undefined);

      expect(error.details).toBeUndefined();
    });

    it('should handle complex nested details', () => {
      const error = new AIProviderError('Complex error', {
        status: 400,
        data: {
          errors: [
            { field: 'email', message: 'Invalid format' },
            { field: 'password', message: 'Too short' },
          ],
        },
      });

      expect(error.details?.data?.errors).toHaveLength(2);
    });
  });

  describe('Error Serialization', () => {
    it('should convert error to JSON', () => {
      const error = new AIProviderError('Test error', {
        status: 500,
      });

      const json = JSON.parse(JSON.stringify({
        name: error.name,
        message: error.message,
        details: error.details,
      }));

      expect(json.name).toBe('AIProviderError');
      expect(json.message).toBe('Test error');
      expect(json.details.status).toBe(500);
    });

    it('should preserve error stack', () => {
      const error = new AIProviderError('Stack test');

      expect(error.stack).toBeDefined();
      expect(error.stack).toContain('AIProviderError');
    });

    it('should have string representation', () => {
      const error = new AIProviderError('String test', {
        status: 404,
      });

      const str = error.toString();
      expect(str).toContain('AIProviderError');
      expect(str).toContain('String test');
    });
  });

  describe('Provider-Specific Errors', () => {
    it('should handle OpenAI API errors', () => {
      const error = new AIProviderError('OpenAI API error', {
        provider: 'openai',
        status: 401,
        data: {
          error: {
            message: 'Invalid API key',
            type: 'invalid_request_error',
          },
        },
      });

      expect(error.details?.provider).toBe('openai');
      expect(error.details?.data?.error?.type).toBe('invalid_request_error');
    });

    it('should handle Anthropic API errors', () => {
      const error = new AIProviderError('Anthropic API error', {
        provider: 'anthropic',
        status: 400,
        data: {
          type: 'error',
          error: { message: 'Invalid model' },
        },
      });

      expect(error.details?.provider).toBe('anthropic');
    });

    it('should handle Ollama errors', () => {
      const error = new AIProviderError('Ollama error', {
        provider: 'ollama',
        status: 404,
        data: { error: 'model not found' },
      });

      expect(error.details?.provider).toBe('ollama');
      expect(error.details?.status).toBe(404);
    });

    it('should handle generic provider errors', () => {
      const error = new AIProviderError('Provider error', {
        provider: 'custom',
        message: 'Custom provider failed',
      });

      expect(error.details?.provider).toBe('custom');
    });
  });
});
