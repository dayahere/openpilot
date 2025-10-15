import { AIProvider, AIConfigSchema } from '../types';

describe('Core Types', () => {
  describe('AIProvider', () => {
    it('includes GEMINI provider', () => {
      const providers = Object.values(AIProvider);
      expect(providers).toContain(AIProvider.GEMINI);
      expect(AIProvider.GEMINI).toBe('gemini');
    });

    it('includes all expected providers', () => {
      // Local/Self-hosted
      expect(AIProvider.OLLAMA).toBe('ollama');
      expect(AIProvider.LOCALAI).toBe('localai');
      expect(AIProvider.LLAMACPP).toBe('llamacpp');
      expect(AIProvider.TEXTGEN_WEBUI).toBe('textgen-webui');
      expect(AIProvider.VLLM).toBe('vllm');
      
      // Cloud providers
      expect(AIProvider.OPENAI).toBe('openai');
      expect(AIProvider.ANTHROPIC).toBe('anthropic');
      expect(AIProvider.GROK).toBe('grok');
      expect(AIProvider.GROQ).toBe('groq');
      expect(AIProvider.TOGETHER).toBe('together');
      expect(AIProvider.MISTRAL).toBe('mistral');
      expect(AIProvider.COHERE).toBe('cohere');
      expect(AIProvider.PERPLEXITY).toBe('perplexity');
      expect(AIProvider.DEEPSEEK).toBe('deepseek');
      expect(AIProvider.GEMINI).toBe('gemini');
      expect(AIProvider.HUGGINGFACE).toBe('huggingface');
      expect(AIProvider.CUSTOM).toBe('custom');
    });

    it('supports all local AI providers', () => {
      const localProviders = [
        AIProvider.OLLAMA,
        AIProvider.LOCALAI,
        AIProvider.LLAMACPP,
        AIProvider.TEXTGEN_WEBUI,
        AIProvider.VLLM,
      ];
      
      localProviders.forEach(provider => {
        expect(Object.values(AIProvider)).toContain(provider);
      });
    });

    it('supports all cloud AI providers', () => {
      const cloudProviders = [
        AIProvider.OPENAI,
        AIProvider.ANTHROPIC,
        AIProvider.GROK,
        AIProvider.GROQ,
        AIProvider.TOGETHER,
        AIProvider.MISTRAL,
        AIProvider.COHERE,
        AIProvider.PERPLEXITY,
        AIProvider.DEEPSEEK,
        AIProvider.GEMINI,
        AIProvider.HUGGINGFACE,
      ];
      
      cloudProviders.forEach(provider => {
        expect(Object.values(AIProvider)).toContain(provider);
      });
    });
  });

  describe('AIConfigSchema', () => {
    it('accepts GEMINI as valid provider', () => {
      const config = {
        provider: AIProvider.GEMINI,
        model: 'gemini-1.5-pro',
        temperature: 0.7,
        maxTokens: 2048,
      };

      const result = AIConfigSchema.safeParse(config);
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.provider).toBe('gemini');
      }
    });

    it('accepts all valid providers', () => {
      const providers = [
        // Local
        AIProvider.OLLAMA,
        AIProvider.LOCALAI,
        AIProvider.LLAMACPP,
        AIProvider.TEXTGEN_WEBUI,
        AIProvider.VLLM,
        // Cloud
        AIProvider.OPENAI,
        AIProvider.ANTHROPIC,
        AIProvider.GROK,
        AIProvider.GROQ,
        AIProvider.TOGETHER,
        AIProvider.MISTRAL,
        AIProvider.COHERE,
        AIProvider.PERPLEXITY,
        AIProvider.DEEPSEEK,
        AIProvider.GEMINI,
        AIProvider.HUGGINGFACE,
        AIProvider.CUSTOM,
      ];

      providers.forEach((provider) => {
        const config = {
          provider,
          model: 'test-model',
          temperature: 0.7,
          maxTokens: 2048,
        };
        const result = AIConfigSchema.safeParse(config);
        expect(result.success).toBe(true);
      });
    });

    it('rejects invalid provider', () => {
      const config = {
        provider: 'invalid-provider',
        model: 'test-model',
        temperature: 0.7,
        maxTokens: 2048,
      };

      const result = AIConfigSchema.safeParse(config);
      expect(result.success).toBe(false);
    });

    it('validates temperature range', () => {
      const validConfig = {
        provider: AIProvider.OPENAI,
        model: 'gpt-4',
        temperature: 1.0,
        maxTokens: 2048,
      };
      expect(AIConfigSchema.safeParse(validConfig).success).toBe(true);

      const tooHigh = { ...validConfig, temperature: 2.1 };
      expect(AIConfigSchema.safeParse(tooHigh).success).toBe(false);

      const tooLow = { ...validConfig, temperature: -0.1 };
      expect(AIConfigSchema.safeParse(tooLow).success).toBe(false);
    });
  });
});
