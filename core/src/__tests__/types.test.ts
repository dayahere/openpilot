import { AIProvider, AIConfigSchema } from '../types';

describe('Core Types', () => {
  describe('AIProvider', () => {
    it('includes GEMINI provider', () => {
      const providers = Object.values(AIProvider);
      expect(providers).toContain(AIProvider.GEMINI);
      expect(AIProvider.GEMINI).toBe('gemini');
    });

    it('includes all expected providers', () => {
      expect(AIProvider.OLLAMA).toBe('ollama');
      expect(AIProvider.OPENAI).toBe('openai');
      expect(AIProvider.GROK).toBe('grok');
      expect(AIProvider.TOGETHER).toBe('together');
      expect(AIProvider.HUGGINGFACE).toBe('huggingface');
      expect(AIProvider.CUSTOM).toBe('custom');
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
        AIProvider.OLLAMA,
        AIProvider.OPENAI,
        AIProvider.GROK,
        AIProvider.TOGETHER,
        AIProvider.HUGGINGFACE,
        AIProvider.CUSTOM,
        AIProvider.GEMINI,
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
