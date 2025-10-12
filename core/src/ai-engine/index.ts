import axios, { AxiosInstance } from 'axios';
import {
  AIConfig,
  AIProvider,
  AIResponse,
  ChatContext,
  CompletionRequest,
  CompletionResponse,
  AIProviderError,
  TokenUsage,
} from '../types';

export interface AIEngineOptions {
  config: AIConfig;
  onEvent?: (event: string, data: unknown) => void;
}

export abstract class BaseAIProvider {
  protected client: AxiosInstance;
  protected config: AIConfig;

  constructor(config: AIConfig) {
    this.config = config;
    this.client = axios.create({
      baseURL: config.apiUrl,
      headers: {
        'Content-Type': 'application/json',
        ...(config.apiKey && { Authorization: `Bearer ${config.apiKey}` }),
      },
      timeout: 60000,
    });
  }

  abstract chat(context: ChatContext): Promise<AIResponse>;
  abstract complete(request: CompletionRequest): Promise<CompletionResponse>;
  abstract streamChat(
    context: ChatContext,
    onChunk: (chunk: string) => void
  ): Promise<AIResponse>;

  protected async handleError(error: unknown): Promise<never> {
    if (axios.isAxiosError(error)) {
      throw new AIProviderError(
        `API request failed: ${error.message}`,
        {
          status: error.response?.status,
          data: error.response?.data,
        }
      );
    }
    
    if (error instanceof Error) {
      throw new AIProviderError(error.message);
    }
    
    throw new AIProviderError('Unknown error occurred');
  }
}

// Ollama Provider
export class OllamaProvider extends BaseAIProvider {
  constructor(config: AIConfig) {
    super({
      ...config,
      apiUrl: config.apiUrl || 'http://localhost:11434',
    });
  }

  async chat(context: ChatContext): Promise<AIResponse> {
    try {
      const response = await this.client.post('/api/chat', {
        model: this.config.model,
        messages: context.messages.map((m) => ({
          role: m.role,
          content: this.enrichContent(m.content, context),
        })),
        stream: false,
        options: {
          temperature: this.config.temperature,
          top_p: this.config.topP,
          num_predict: this.config.maxTokens,
        },
      });

      return {
        id: `ollama-${Date.now()}`,
        content: response.data.message.content,
        role: 'assistant',
        timestamp: Date.now(),
        model: this.config.model,
      };
    } catch (error) {
      return this.handleError(error);
    }
  }

  async complete(request: CompletionRequest): Promise<CompletionResponse> {
    try {
      const prompt = this.buildCompletionPrompt(request);
      const response = await this.client.post('/api/generate', {
        model: this.config.model,
        prompt,
        stream: false,
        options: {
          temperature: this.config.temperature,
          top_p: this.config.topP,
          num_predict: this.config.maxTokens,
        },
      });

      return {
        completions: [
          {
            text: response.data.response,
            confidence: 0.8,
            offset: 0,
          },
        ],
      };
    } catch (error) {
      return this.handleError(error);
    }
  }

  async streamChat(
    context: ChatContext,
    onChunk: (chunk: string) => void
  ): Promise<AIResponse> {
    try {
      const response = await this.client.post(
        '/api/chat',
        {
          model: this.config.model,
          messages: context.messages.map((m) => ({
            role: m.role,
            content: this.enrichContent(m.content, context),
          })),
          stream: true,
        },
        {
          responseType: 'stream',
        }
      );

      let fullContent = '';
      const stream = response.data;

      return new Promise((resolve, reject) => {
        stream.on('data', (chunk: Buffer) => {
          const lines = chunk.toString().split('\n').filter(Boolean);
          lines.forEach((line) => {
            try {
              const data = JSON.parse(line);
              if (data.message?.content) {
                fullContent += data.message.content;
                onChunk(data.message.content);
              }
            } catch (e) {
              // Ignore parse errors for incomplete chunks
            }
          });
        });

        stream.on('end', () => {
          resolve({
            id: `ollama-${Date.now()}`,
            content: fullContent,
            role: 'assistant',
            timestamp: Date.now(),
            model: this.config.model,
          });
        });

        stream.on('error', reject);
      });
    } catch (error) {
      return this.handleError(error);
    }
  }

  private enrichContent(content: string, context: ChatContext): string {
    if (!context.codeContext) return content;

    const { codeContext } = context;
    return `${content}

Code Context:
File: ${codeContext.fileName}
Language: ${codeContext.language}
Lines ${codeContext.lineStart}-${codeContext.lineEnd}:
\`\`\`${codeContext.language}
${codeContext.selectedCode}
\`\`\`
${codeContext.surroundingCode ? `\nSurrounding code:\n\`\`\`${codeContext.language}\n${codeContext.surroundingCode}\n\`\`\`` : ''}`;
  }

  private buildCompletionPrompt(request: CompletionRequest): string {
    const { context, prompt } = request;
    return `You are an expert code completion assistant. Complete the following code:

Language: ${context.language}
File: ${context.fileName}

Code:
\`\`\`${context.language}
${context.selectedCode}
\`\`\`

${prompt}

Provide only the code completion, no explanations.`;
  }
}

// OpenAI Provider
export class OpenAIProvider extends BaseAIProvider {
  constructor(config: AIConfig) {
    super({
      ...config,
      apiUrl: config.apiUrl || 'https://api.openai.com/v1',
    });
  }

  async chat(context: ChatContext): Promise<AIResponse> {
    try {
      const response = await this.client.post('/chat/completions', {
        model: this.config.model,
        messages: this.formatMessages(context),
        temperature: this.config.temperature,
        max_tokens: this.config.maxTokens,
        top_p: this.config.topP,
        frequency_penalty: this.config.frequencyPenalty,
        presence_penalty: this.config.presencePenalty,
      });

      const choice = response.data.choices[0];
      return {
        id: response.data.id,
        content: choice.message.content,
        role: 'assistant',
        timestamp: Date.now(),
        model: response.data.model,
        usage: this.extractUsage(response.data.usage),
      };
    } catch (error) {
      return this.handleError(error);
    }
  }

  async complete(request: CompletionRequest): Promise<CompletionResponse> {
    try {
      const prompt = this.buildCompletionPrompt(request);
      const response = await this.client.post('/chat/completions', {
        model: this.config.model,
        messages: [{ role: 'user', content: prompt }],
        temperature: this.config.temperature,
        max_tokens: this.config.maxTokens,
      });

      return {
        completions: [
          {
            text: response.data.choices[0].message.content,
            confidence: 0.9,
            offset: 0,
          },
        ],
      };
    } catch (error) {
      return this.handleError(error);
    }
  }

  async streamChat(
    context: ChatContext,
    onChunk: (chunk: string) => void
  ): Promise<AIResponse> {
    try {
      const response = await this.client.post(
        '/chat/completions',
        {
          model: this.config.model,
          messages: this.formatMessages(context),
          temperature: this.config.temperature,
          max_tokens: this.config.maxTokens,
          stream: true,
        },
        {
          responseType: 'stream',
        }
      );

      let fullContent = '';
      let responseId = '';
      const stream = response.data;

      return new Promise((resolve, reject) => {
        stream.on('data', (chunk: Buffer) => {
          const lines = chunk
            .toString()
            .split('\n')
            .filter((line) => line.trim().startsWith('data: '));

          lines.forEach((line) => {
            const data = line.replace('data: ', '');
            if (data === '[DONE]') return;

            try {
              const parsed = JSON.parse(data);
              responseId = parsed.id;
              const content = parsed.choices[0]?.delta?.content || '';
              if (content) {
                fullContent += content;
                onChunk(content);
              }
            } catch (e) {
              // Ignore parse errors
            }
          });
        });

        stream.on('end', () => {
          resolve({
            id: responseId,
            content: fullContent,
            role: 'assistant',
            timestamp: Date.now(),
            model: this.config.model,
          });
        });

        stream.on('error', reject);
      });
    } catch (error) {
      return this.handleError(error);
    }
  }

  private formatMessages(context: ChatContext): Array<{ role: string; content: string }> {
    const messages = context.messages.map((m) => ({
      role: m.role,
      content: m.content,
    }));

    // Add code context as system message if available
    if (context.codeContext) {
      const codeMessage: { role: 'system' | 'user' | 'assistant'; content: string } = {
        role: 'system' as const,
        content: `Code context - File: ${context.codeContext.fileName}, Language: ${context.codeContext.language}\n\`\`\`${context.codeContext.language}\n${context.codeContext.selectedCode}\n\`\`\``,
      };
      messages.unshift(codeMessage);
    }

    return messages;
  }

  private buildCompletionPrompt(request: CompletionRequest): string {
    const { context, prompt } = request;
    return `Complete this ${context.language} code:\n\`\`\`${context.language}\n${context.selectedCode}\n\`\`\`\n\n${prompt}`;
  }

  private extractUsage(usage: any): TokenUsage | undefined {
    if (!usage) return undefined;
    return {
      promptTokens: usage.prompt_tokens,
      completionTokens: usage.completion_tokens,
      totalTokens: usage.total_tokens,
    };
  }
}

// AI Engine
export class AIEngine {
  private provider: BaseAIProvider;
  private config: AIConfig;

  constructor(options: AIEngineOptions) {
    this.config = options.config;
    this.provider = this.createProvider(options.config);
  }

  private createProvider(config: AIConfig): BaseAIProvider {
    switch (config.provider) {
      case AIProvider.OLLAMA:
        return new OllamaProvider(config);
      case AIProvider.OPENAI:
      case AIProvider.GROK:
      case AIProvider.TOGETHER:
      case AIProvider.CUSTOM:
        return new OpenAIProvider(config);
      default:
        throw new Error(`Unsupported AI provider: ${config.provider}`);
    }
  }

  async chat(context: ChatContext): Promise<AIResponse> {
    return this.provider.chat(context);
  }

  async complete(request: CompletionRequest): Promise<CompletionResponse> {
    return this.provider.complete(request);
  }

  async streamChat(
    context: ChatContext,
    onChunk: (chunk: string) => void
  ): Promise<AIResponse> {
    return this.provider.streamChat(context, onChunk);
  }

  updateConfig(config: Partial<AIConfig>): void {
    this.config = { ...this.config, ...config };
    this.provider = this.createProvider(this.config);
  }

  getConfig(): AIConfig {
    return { ...this.config };
  }
}
