import * as vscode from 'vscode';
import { AIConfig, AIProvider } from '@openpilot/core';

export class ConfigurationManager {
  getAIConfig(): AIConfig {
    const config = vscode.workspace.getConfiguration('openpilot');

    return {
      provider: (config.get('provider') as AIProvider) || AIProvider.OLLAMA,
      model: config.get('model') || 'codellama',
      apiKey: config.get('apiKey'),
      apiUrl: config.get('apiUrl'),
      temperature: config.get('temperature') || 0.7,
      maxTokens: config.get('maxTokens') || 2048,
      topP: 0.9,
      frequencyPenalty: 0,
      presencePenalty: 0,
      offline: config.get('offline') || false,
    };
  }
}
