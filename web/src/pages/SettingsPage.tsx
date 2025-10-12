import React, { useState } from 'react';

const SettingsPage: React.FC = () => {
  const [apiKey, setApiKey] = useState('');
  const [model, setModel] = useState('gpt-4');
  const [theme, setTheme] = useState('dark');

  const handleSave = () => {
    localStorage.setItem('openpilot-settings', JSON.stringify({ apiKey, model, theme }));
    alert('Settings saved!');
  };

  return (
    <div className="settings-page">
      <h2>Settings</h2>
      <div className="settings-container">
        <div className="setting-group">
          <label>API Key:</label>
          <input
            type="password"
            value={apiKey}
            onChange={(e) => setApiKey(e.target.value)}
            placeholder="Enter your API key"
          />
        </div>
        
        <div className="setting-group">
          <label>Model:</label>
          <select value={model} onChange={(e) => setModel(e.target.value)}>
            <option value="gpt-4">GPT-4</option>
            <option value="gpt-3.5-turbo">GPT-3.5 Turbo</option>
            <option value="claude-2">Claude 2</option>
          </select>
        </div>
        
        <div className="setting-group">
          <label>Theme:</label>
          <select value={theme} onChange={(e) => setTheme(e.target.value)}>
            <option value="dark">Dark</option>
            <option value="light">Light</option>
          </select>
        </div>
        
        <button className="save-button" onClick={handleSave}>
          Save Settings
        </button>
      </div>
    </div>
  );
};

export default SettingsPage;
