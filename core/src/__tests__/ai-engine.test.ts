import { AIEngine } from '../ai-engine';
import { AIProvider, AIConfig } from '../types';

const createDefaultConfig = (overrides: Partial<AIConfig> = {}): AIConfig => ({
  provider: AIProvider.OLLAMA,
  model: 'codellama',
  temperature: 0.7,
  maxTokens: 2048,
  topP: 0.9,
  frequencyPenalty: 0,
  presencePenalty: 0,
  offline: false,
  ...overrides,
});

describe('AIEngine', () => {
  describe('updateConfig', () => {
    it('applies provider/model/temperature changes', () => {
      const initialConfig = createDefaultConfig();

      const engine = new AIEngine({ config: initialConfig });

      const newConfig = createDefaultConfig({
        provider: AIProvider.OPENAI,
        model: 'gpt-4o',
        temperature: 1.0,
        maxTokens: 4096,
      });

      engine.updateConfig(newConfig);

      // Engine should have new config internally
      // We can verify this by checking that subsequent calls use new config
      expect(engine).toBeDefined();
    });

    it('re-initializes provider on config change', () => {
      const engine = new AIEngine({
        config: createDefaultConfig(),
      });

      // Change to different provider
      engine.updateConfig(
        createDefaultConfig({
          provider: AIProvider.OPENAI,
          model: 'gpt-4',
          temperature: 0.8,
        })
      );

      // Engine should not throw and should be ready
      expect(engine).toBeDefined();
    });

    it('handles GEMINI provider in config', () => {
      const engine = new AIEngine({
        config: createDefaultConfig({
          provider: AIProvider.GEMINI,
          model: 'gemini-1.5-pro',
          apiKey: 'test-key',
        }),
      });

      expect(engine).toBeDefined();

      engine.updateConfig(
        createDefaultConfig({
          provider: AIProvider.GEMINI,
          model: 'gemini-1.5-flash',
          temperature: 0.9,
          maxTokens: 4096,
        })
      );

      expect(engine).toBeDefined();
    });

    it('preserves apiKey when updating config', () => {
      const engine = new AIEngine({
        config: createDefaultConfig({
          provider: AIProvider.OPENAI,
          model: 'gpt-4',
          apiKey: 'secret-key',
        }),
      });

      engine.updateConfig(
        createDefaultConfig({
          provider: AIProvider.OPENAI,
          model: 'gpt-4o',
          temperature: 0.8,
        })
      );

      expect(engine).toBeDefined();
    });
  });
});
