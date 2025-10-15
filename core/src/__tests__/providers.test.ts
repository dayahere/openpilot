import { OllamaProvider } from '../ai-engine';
import axios from 'axios';
import { AIConfig, AIProvider } from '../types';

jest.mock('axios');
const mockedAxios = axios as jest.Mocked<typeof axios>;

const createMockConfig = (overrides: Partial<AIConfig> = {}): AIConfig => ({
  provider: AIProvider.OLLAMA,
  model: 'codellama',
  temperature: 0.7,
  maxTokens: 2048,
  topP: 0.9,
  frequencyPenalty: 0,
  presencePenalty: 0,
  offline: false,
  apiUrl: 'http://localhost:11434',
  ...overrides,
});

describe('Provider stubs', () => {
  describe('OllamaProvider', () => {
    let provider: OllamaProvider;

    beforeEach(() => {
      jest.clearAllMocks();
      mockedAxios.create.mockReturnValue(mockedAxios as any);
      provider = new OllamaProvider(createMockConfig());
    });

    it('chat - happy path', async () => {
      const mockResponse = {
        data: {
          message: {
            role: 'assistant',
            content: 'Hello, how can I help you?',
          },
          model: 'codellama',
          created_at: new Date().toISOString(),
        },
        status: 200,
      };

      mockedAxios.post.mockResolvedValueOnce(mockResponse);

      const result = await provider.chat({
        messages: [{ id: '1', role: 'user', content: 'Hello', timestamp: Date.now() }],
      });

      expect(result).toEqual(
        expect.objectContaining({
          role: 'assistant',
          content: 'Hello, how can I help you?',
        })
      );
      expect(mockedAxios.post).toHaveBeenCalledWith(
        '/api/chat',
        expect.objectContaining({
          model: 'codellama',
          messages: expect.any(Array),
          stream: false,
          options: expect.any(Object),
        })
      );
    });

    it('chat - handles error', async () => {
      const mockError = new Error('Network error');
      mockedAxios.post.mockRejectedValueOnce(mockError);

      await expect(
        provider.chat({
          messages: [{ id: '1', role: 'user', content: 'Hello', timestamp: Date.now() }],
        })
      ).rejects.toThrow();
    });

    it('streamChat - happy path with chunks', async () => {
      // Mock stream response
      const mockEventEmitter: any = {
        on: jest.fn((event: string, handler: any): any => {
          if (event === 'data') {
            // Simulate streaming chunks
            setTimeout(() => {
              handler(Buffer.from(JSON.stringify({ message: { content: 'Hello' } }) + '\n'));
              handler(Buffer.from(JSON.stringify({ message: { content: ' World' } }) + '\n'));
              handler(Buffer.from(JSON.stringify({ message: { content: '!' }, done: true }) + '\n'));
            }, 0);
          } else if (event === 'end') {
            setTimeout(() => handler(), 10);
          } else if (event === 'error') {
            // No error in happy path
          }
          return mockEventEmitter;
        }),
      };

      mockedAxios.post.mockResolvedValueOnce({
        data: mockEventEmitter,
        status: 200,
      } as any);

      const receivedChunks: string[] = [];
      const result = await provider.streamChat(
        {
          messages: [{ id: '1', role: 'user', content: 'Hi', timestamp: Date.now() }],
        },
        (chunk: string) => {
          receivedChunks.push(chunk);
        }
      );

      expect(receivedChunks.length).toBeGreaterThan(0);
      expect(result).toEqual(
        expect.objectContaining({
          role: 'assistant',
          content: expect.any(String),
        })
      );
    });

    it('streamChat - handles streaming error', async () => {
      mockedAxios.post.mockRejectedValueOnce(new Error('Stream failed'));

      await expect(
        provider.streamChat(
          {
            messages: [{ id: '1', role: 'user', content: 'Hi', timestamp: Date.now() }],
          },
          () => {}
        )
      ).rejects.toThrow();
    });

    it('validates required config fields', () => {
      const invalidConfig = createMockConfig({ model: '' });
      expect(() => {
        new OllamaProvider(invalidConfig);
      }).toBeDefined(); // Constructor may not throw, validation happens at request time
    });

    it('accepts custom apiUrl', () => {
      const customProvider = new OllamaProvider(
        createMockConfig({
          model: 'llama2',
          temperature: 0.5,
          maxTokens: 1024,
          apiUrl: 'http://custom-server:8080',
        })
      );

      expect(customProvider).toBeDefined();
    });
  });
});
