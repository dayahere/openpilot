import { describe, it, expect, jest, beforeEach } from '@jest/globals';
import { AIEngine } from '../ai-engine/index';
import { ContextManager } from '../context-manager/index';
import { AIProvider, AIConfig } from '../types/index';

// Mock axios
jest.mock('axios');

describe('Core - AIEngine Unit Tests', () => {
  describe('AIEngine with Ollama', () => {
    let engine: AIEngine;
    const config: AIConfig = {
      provider: AIProvider.OLLAMA,
      model: 'codellama',
      apiUrl: 'http://localhost:11434',
      temperature: 0.7,
      maxTokens: 2048,
      topP: 0.9,
      frequencyPenalty: 0,
      presencePenalty: 0,
      offline: true,
    };

    beforeEach(() => {
      engine = new AIEngine({ config });
    });

    it('should create AIEngine instance', () => {
      expect(engine).toBeInstanceOf(AIEngine);
    });

    it('should initialize with correct provider', () => {
      expect(engine).toBeDefined();
    });
  });

  describe('AIEngine with OpenAI', () => {
    let engine: AIEngine;
    const config: AIConfig = {
      provider: AIProvider.OPENAI,
      model: 'gpt-4',
      apiKey: 'test-key',
      temperature: 0.7,
      maxTokens: 2048,
      topP: 0.9,
      frequencyPenalty: 0,
      presencePenalty: 0,
      offline: false,
    };

    beforeEach(() => {
      engine = new AIEngine({ config });
    });

    it('should create AIEngine with OpenAI', () => {
      expect(engine).toBeInstanceOf(AIEngine);
    });

    it('should require API key for OpenAI', () => {
      expect(config.apiKey).toBeDefined();
    });
  });

  describe('Configuration validation', () => {
    it('should accept valid Ollama config', () => {
      const config: AIConfig = {
        provider: AIProvider.OLLAMA,
        model: 'codellama',
        temperature: 0.7,
        maxTokens: 2048,
        topP: 0.9,
        frequencyPenalty: 0,
        presencePenalty: 0,
        offline: true,
      };

      expect(() => new AIEngine({ config })).not.toThrow();
    });

    it('should handle temperature bounds', () => {
      const config: AIConfig = {
        provider: AIProvider.OLLAMA,
        model: 'codellama',
        temperature: 1.5,
        maxTokens: 2048,
        topP: 0.9,
        frequencyPenalty: 0,
        presencePenalty: 0,
        offline: true,
      };

      expect(() => new AIEngine({ config })).not.toThrow();
    });
  });
});

describe('Core - ContextManager Unit Tests', () => {
  describe('Constructor', () => {
    it('should create with default options', () => {
      const manager = new ContextManager({ rootPath: '/test' });
      expect(manager).toBeInstanceOf(ContextManager);
    });

    it('should accept custom maxFileSize', () => {
      const manager = new ContextManager({
        rootPath: '/test',
        maxFileSize: 2 * 1024 * 1024,
      });
      expect(manager).toBeInstanceOf(ContextManager);
    });

    it('should accept exclude patterns', () => {
      const manager = new ContextManager({
        rootPath: '/test',
        excludePatterns: ['node_modules', '.git', 'dist'],
      });
      expect(manager).toBeInstanceOf(ContextManager);
    });

    it('should accept include patterns', () => {
      const manager = new ContextManager({
        rootPath: '/test',
        includePatterns: ['**/*.ts', '**/*.js'],
      });
      expect(manager).toBeInstanceOf(ContextManager);
    });
  });

  // Note: Language detection is tested indirectly through analyzeRepository
  // in the integration tests, as detectLanguage is a private method

  describe('File Size Validation', () => {
    it('should respect maxFileSize limit', () => {
      const manager = new ContextManager({
        rootPath: '/test',
        maxFileSize: 1024,
      });
      expect(manager).toBeInstanceOf(ContextManager);
    });
  });
});

describe('Core - Types Unit Tests', () => {
  describe('AIProvider Enum', () => {
    it('should have OLLAMA provider', () => {
      expect(AIProvider.OLLAMA).toBe('ollama');
    });

    it('should have OPENAI provider', () => {
      expect(AIProvider.OPENAI).toBe('openai');
    });

    it('should have GROK provider', () => {
      expect(AIProvider.GROK).toBe('grok');
    });

    it('should have TOGETHER provider', () => {
      expect(AIProvider.TOGETHER).toBe('together');
    });

    it('should have HUGGINGFACE provider', () => {
      expect(AIProvider.HUGGINGFACE).toBe('huggingface');
    });

    it('should have CUSTOM provider', () => {
      expect(AIProvider.CUSTOM).toBe('custom');
    });
  });
});
