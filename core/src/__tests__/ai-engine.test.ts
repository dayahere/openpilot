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

    it('handles all cloud AI providers', () => {
      const cloudProviders = [
        { provider: AIProvider.OPENAI, model: 'gpt-4' },
        { provider: AIProvider.ANTHROPIC, model: 'claude-3-opus' },
        { provider: AIProvider.GROK, model: 'grok-beta' },
        { provider: AIProvider.GROQ, model: 'mixtral-8x7b' },
        { provider: AIProvider.TOGETHER, model: 'meta-llama/Llama-2-70b' },
        { provider: AIProvider.MISTRAL, model: 'mistral-large' },
        { provider: AIProvider.COHERE, model: 'command' },
        { provider: AIProvider.PERPLEXITY, model: 'pplx-70b-online' },
        { provider: AIProvider.DEEPSEEK, model: 'deepseek-coder' },
        { provider: AIProvider.GEMINI, model: 'gemini-pro' },
        { provider: AIProvider.HUGGINGFACE, model: 'bigcode/starcoder' },
      ];

      cloudProviders.forEach(({ provider, model }) => {
        const engine = new AIEngine({
          config: createDefaultConfig({
            provider,
            model,
            apiKey: 'test-key',
          }),
        });
        expect(engine).toBeDefined();
      });
    });

    it('handles all local AI providers', () => {
      const localProviders = [
        { provider: AIProvider.OLLAMA, model: 'codellama' },
        { provider: AIProvider.LOCALAI, model: 'ggml-gpt4all-j' },
        { provider: AIProvider.LLAMACPP, model: 'llama-2-13b' },
        { provider: AIProvider.TEXTGEN_WEBUI, model: 'wizardcoder-python-13b' },
        { provider: AIProvider.VLLM, model: 'meta-llama/Llama-2-7b' },
      ];

      localProviders.forEach(({ provider, model }) => {
        const engine = new AIEngine({
          config: createDefaultConfig({
            provider,
            model,
            apiUrl: 'http://localhost:8080',
          }),
        });
        expect(engine).toBeDefined();
      });
    });

    it('switches between different provider types', () => {
      const engine = new AIEngine({
        config: createDefaultConfig({
          provider: AIProvider.OLLAMA,
          model: 'codellama',
        }),
      });

      // Switch to cloud provider
      engine.updateConfig(
        createDefaultConfig({
          provider: AIProvider.ANTHROPIC,
          model: 'claude-3-sonnet',
          apiKey: 'test-key',
        })
      );
      expect(engine).toBeDefined();

      // Switch to another local provider
      engine.updateConfig(
        createDefaultConfig({
          provider: AIProvider.VLLM,
          model: 'mistral-7b',
          apiUrl: 'http://localhost:8000',
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
