import React, { useState } from 'react';
import { AIProvider } from '@openpilot/core';
import './Settings.css';

const Settings: React.FC = () => {
  const [provider, setProvider] = useState<AIProvider>(AIProvider.OLLAMA);
  const [model, setModel] = useState('codellama');
  const [apiKey, setApiKey] = useState('');
  const [apiUrl, setApiUrl] = useState('');
  const [temperature, setTemperature] = useState(0.7);
  const [maxTokens, setMaxTokens] = useState(2048);

  const handleSave = () => {
    // Save settings
    alert('Settings saved!');
  };

  return (
    <div className="settings">
      <div className="settings-header">
        <h2>Settings</h2>
      </div>

      <div className="settings-content">
        <div className="setting-group">
          <label>AI Provider</label>
          <select value={provider} onChange={(e) => setProvider(e.target.value as AIProvider)}>
            <option value={AIProvider.OLLAMA}>Ollama (Local)</option>
            <option value={AIProvider.OPENAI}>OpenAI</option>
            <option value={AIProvider.GROK}>Grok</option>
            <option value={AIProvider.TOGETHER}>Together AI</option>
            <option value={AIProvider.HUGGINGFACE}>Hugging Face</option>
            <option value={AIProvider.CUSTOM}>Custom</option>
          </select>
        </div>

        <div className="setting-group">
          <label>Model</label>
          <input
            type="text"
            value={model}
            onChange={(e) => setModel(e.target.value)}
            placeholder="e.g., codellama, gpt-4"
          />
        </div>

        {provider !== AIProvider.OLLAMA && (
          <>
            <div className="setting-group">
              <label>API Key</label>
              <input
                type="password"
                value={apiKey}
                onChange={(e) => setApiKey(e.target.value)}
                placeholder="Your API key"
              />
            </div>

            <div className="setting-group">
              <label>API URL (Optional)</label>
              <input
                type="text"
                value={apiUrl}
                onChange={(e) => setApiUrl(e.target.value)}
                placeholder="Custom API endpoint"
              />
            </div>
          </>
        )}

        <div className="setting-group">
          <label>Temperature: {temperature}</label>
          <input
            type="range"
            min="0"
            max="2"
            step="0.1"
            value={temperature}
            onChange={(e) => setTemperature(parseFloat(e.target.value))}
          />
        </div>

        <div className="setting-group">
          <label>Max Tokens</label>
          <input
            type="number"
            value={maxTokens}
            onChange={(e) => setMaxTokens(parseInt(e.target.value))}
            min="128"
            max="8192"
          />
        </div>

        <button className="save-button" onClick={handleSave}>
          Save Settings
        </button>
      </div>
    </div>
  );
};

export default Settings;
