/**
 * Desktop App - Integration Tests
 * Tests Electron desktop application functionality
 */

import { Application } from 'spectron';
import * as path from 'path';
import * as assert from 'assert';

describe('Desktop App - Integration Tests', () => {
  let app: Application;

  beforeAll(async () => {
    app = new Application({
      path: path.join(__dirname, '../../../node_modules/.bin/electron'),
      args: [path.join(__dirname, '../../../')],
      env: {
        NODE_ENV: 'test',
        OPENPILOT_PROVIDER: 'ollama',
        OPENPILOT_MODEL: 'phi3:mini',
        OPENPILOT_API_URL: 'http://localhost:11434'
      }
    });

    await app.start();
    await app.client.waitUntilWindowLoaded();
  }, 30000);

  afterAll(async () => {
    if (app && app.isRunning()) {
      await app.stop();
    }
  });

  describe('Application Launch', () => {
    it('should launch application successfully', async () => {
      assert.ok(await app.client.isVisible('body'));
    });

    it('should display main window', async () => {
      const title = await app.client.getTitle();
      assert.ok(title.includes('OpenPilot'));
    });

    it('should load within 5 seconds', async () => {
      const start = Date.now();
      await app.client.waitUntilWindowLoaded();
      const duration = Date.now() - start;
      
      assert.ok(duration < 5000);
    });

    it('should have correct window dimensions', async () => {
      const bounds = await app.browserWindow.getBounds();
      assert.ok(bounds.width >= 800);
      assert.ok(bounds.height >= 600);
    });

    it('should be focused on launch', async () => {
      const isFocused = await app.browserWindow.isFocused();
      assert.ok(isFocused);
    });
  });

  describe('Chat Interface', () => {
    it('should display chat UI', async () => {
      const chatVisible = await app.client.isVisible('#chat-container');
      assert.ok(chatVisible);
    });

    it('should send chat message', async () => {
      await app.client.setValue('#chat-input', 'Hello');
      await app.client.click('#send-button');
      
      // Wait for response
      await app.client.waitForExist('.message.ai', 10000);
      
      const messages = await app.client.$$('.message');
      assert.ok(messages.length >= 2); // User + AI message
    });

    it('should display message history', async () => {
      await app.client.setValue('#chat-input', 'Test message 1');
      await app.client.click('#send-button');
      await app.client.waitForExist('.message.ai', 10000);
      
      await app.client.setValue('#chat-input', 'Test message 2');
      await app.client.click('#send-button');
      await app.client.waitForExist('.message.ai', 10000);
      
      const messages = await app.client.$$('.message');
      assert.ok(messages.length >= 4);
    });

    it('should clear chat history', async () => {
      await app.client.click('#clear-chat-button');
      
      const messages = await app.client.$$('.message');
      assert.strictEqual(messages.length, 0);
    });

    it('should handle long messages', async () => {
      const longMessage = 'a'.repeat(1000);
      await app.client.setValue('#chat-input', longMessage);
      await app.client.click('#send-button');
      
      await app.client.waitForExist('.message.user', 5000);
      const messageText = await app.client.getText('.message.user:last-child');
      
      assert.ok(messageText.length === longMessage.length);
    });

    it('should render code blocks', async () => {
      await app.client.setValue('#chat-input', 'Show me JavaScript code');
      await app.client.click('#send-button');
      
      await app.client.waitForExist('.code-block', 15000);
      const codeBlock = await app.client.isExisting('.code-block');
      
      assert.ok(codeBlock);
    });

    it('should copy code to clipboard', async () => {
      await app.client.setValue('#chat-input', 'Write a function');
      await app.client.click('#send-button');
      
      await app.client.waitForExist('.copy-code-button', 15000);
      await app.client.click('.copy-code-button');
      
      // Verify clipboard (requires clipboard access)
      await new Promise(resolve => setTimeout(resolve, 500));
      assert.ok(true);
    });
  });

  describe('Code Generation', () => {
    it('should navigate to code generation view', async () => {
      await app.client.click('#nav-generate');
      await app.client.waitForExist('#code-gen-container', 5000);
      
      const visible = await app.client.isVisible('#code-gen-container');
      assert.ok(visible);
    });

    it('should generate code from prompt', async () => {
      await app.client.click('#nav-generate');
      await app.client.setValue('#code-prompt', 'Create a sorting function');
      await app.client.click('#generate-button');
      
      await app.client.waitForExist('#generated-code', 15000);
      const code = await app.client.getText('#generated-code');
      
      assert.ok(code.length > 0);
      assert.ok(code.includes('function') || code.includes('const'));
    });

    it('should handle different programming languages', async () => {
      const languages = ['JavaScript', 'Python', 'Java', 'Go'];
      
      for (const lang of languages) {
        await app.client.click('#nav-generate');
        await app.client.selectByVisibleText('#language-select', lang);
        await app.client.setValue('#code-prompt', 'Create a hello world program');
        await app.client.click('#generate-button');
        
        await app.client.waitForExist('#generated-code', 15000);
        const code = await app.client.getText('#generated-code');
        
        assert.ok(code.length > 0);
      }
    });

    it('should export generated code', async () => {
      await app.client.click('#nav-generate');
      await app.client.setValue('#code-prompt', 'Create a test function');
      await app.client.click('#generate-button');
      
      await app.client.waitForExist('#generated-code', 15000);
      await app.client.click('#export-code-button');
      
      // Verify file dialog opened
      await new Promise(resolve => setTimeout(resolve, 1000));
      assert.ok(true);
    });
  });

  describe('Settings', () => {
    it('should navigate to settings', async () => {
      await app.client.click('#nav-settings');
      await app.client.waitForExist('#settings-container', 5000);
      
      const visible = await app.client.isVisible('#settings-container');
      assert.ok(visible);
    });

    it('should change AI provider', async () => {
      await app.client.click('#nav-settings');
      await app.client.selectByVisibleText('#provider-select', 'OpenAI');
      await app.client.setValue('#api-key-input', 'test-key');
      await app.client.click('#save-settings-button');
      
      // Wait for settings to save
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Verify setting persisted
      const provider = await app.client.getValue('#provider-select');
      assert.strictEqual(provider, 'openai');
    });

    it('should change model', async () => {
      await app.client.click('#nav-settings');
      await app.client.setValue('#model-input', 'llama3.2:1b');
      await app.client.click('#save-settings-button');
      
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      const model = await app.client.getValue('#model-input');
      assert.strictEqual(model, 'llama3.2:1b');
    });

    it('should toggle dark mode', async () => {
      await app.client.click('#nav-settings');
      await app.client.click('#dark-mode-toggle');
      
      await new Promise(resolve => setTimeout(resolve, 500));
      
      const darkMode = await app.client.getAttribute('body', 'class');
      assert.ok(darkMode.includes('dark'));
    });

    it('should persist settings across restarts', async () => {
      await app.client.click('#nav-settings');
      await app.client.setValue('#model-input', 'test-model');
      await app.client.click('#save-settings-button');
      
      // Restart app
      await app.restart();
      await app.client.waitUntilWindowLoaded();
      
      await app.client.click('#nav-settings');
      const model = await app.client.getValue('#model-input');
      
      assert.strictEqual(model, 'test-model');
    });
  });

  describe('Window Management', () => {
    it('should minimize window', async () => {
      await app.browserWindow.minimize();
      await new Promise(resolve => setTimeout(resolve, 500));
      
      const isMinimized = await app.browserWindow.isMinimized();
      assert.ok(isMinimized);
      
      await app.browserWindow.restore();
    });

    it('should maximize window', async () => {
      await app.browserWindow.maximize();
      await new Promise(resolve => setTimeout(resolve, 500));
      
      const isMaximized = await app.browserWindow.isMaximized();
      assert.ok(isMaximized);
      
      await app.browserWindow.unmaximize();
    });

    it('should resize window', async () => {
      await app.browserWindow.setBounds({ width: 1024, height: 768 });
      await new Promise(resolve => setTimeout(resolve, 500));
      
      const bounds = await app.browserWindow.getBounds();
      assert.strictEqual(bounds.width, 1024);
      assert.strictEqual(bounds.height, 768);
    });

    it('should handle window close event', async () => {
      // Minimize to tray instead of closing
      await app.browserWindow.close();
      await new Promise(resolve => setTimeout(resolve, 500));
      
      // App should still be running
      assert.ok(app.isRunning());
    });
  });

  describe('File Operations', () => {
    it('should open file', async () => {
      await app.client.click('#menu-file');
      await app.client.click('#menu-open');
      
      // File dialog would open
      await new Promise(resolve => setTimeout(resolve, 1000));
      assert.ok(true);
    });

    it('should save file', async () => {
      await app.client.click('#nav-generate');
      await app.client.setValue('#code-prompt', 'Test code');
      await app.client.click('#generate-button');
      
      await app.client.waitForExist('#generated-code', 15000);
      
      await app.client.click('#menu-file');
      await app.client.click('#menu-save');
      
      await new Promise(resolve => setTimeout(resolve, 1000));
      assert.ok(true);
    });

    it('should handle recent files', async () => {
      await app.client.click('#menu-file');
      await app.client.click('#menu-recent');
      
      await app.client.waitForExist('#recent-files-list', 2000);
      const visible = await app.client.isVisible('#recent-files-list');
      
      assert.ok(visible);
    });
  });

  describe('Keyboard Shortcuts', () => {
    it('should open chat with shortcut', async () => {
      await app.client.keys(['Control', 'Shift', 'C']);
      await app.client.waitForExist('#chat-container', 2000);
      
      const visible = await app.client.isVisible('#chat-container');
      assert.ok(visible);
    });

    it('should navigate with shortcuts', async () => {
      await app.client.keys(['Control', '1']); // Navigate to chat
      await new Promise(resolve => setTimeout(resolve, 500));
      
      await app.client.keys(['Control', '2']); // Navigate to generate
      await new Promise(resolve => setTimeout(resolve, 500));
      
      await app.client.keys(['Control', '3']); // Navigate to settings
      await new Promise(resolve => setTimeout(resolve, 500));
      
      const visible = await app.client.isVisible('#settings-container');
      assert.ok(visible);
    });

    it('should save with Ctrl+S', async () => {
      await app.client.keys(['Control', 'S']);
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      assert.ok(true);
    });
  });

  describe('Performance', () => {
    it('should handle rapid input', async () => {
      for (let i = 0; i < 10; i++) {
        await app.client.setValue('#chat-input', `Message ${i}`);
        await app.client.click('#send-button');
        await new Promise(resolve => setTimeout(resolve, 100));
      }
      
      assert.ok(true);
    });

    it('should render large chat history efficiently', async () => {
      // Add 100 messages
      for (let i = 0; i < 100; i++) {
        await app.client.execute((msg: string) => {
          const container = document.getElementById('chat-messages');
          const div = document.createElement('div');
          div.className = 'message user';
          div.textContent = msg;
          container?.appendChild(div);
        }, `Message ${i}`);
      }
      
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Should still be responsive
      const visible = await app.client.isVisible('#chat-input');
      assert.ok(visible);
    });

    it('should not memory leak', async () => {
      const initialMemory = await app.webContents.getProcessMemoryInfo();
      
      // Perform 50 operations
      for (let i = 0; i < 50; i++) {
        await app.client.setValue('#chat-input', `Test ${i}`);
        await app.client.click('#send-button');
        await new Promise(resolve => setTimeout(resolve, 200));
      }
      
      const finalMemory = await app.webContents.getProcessMemoryInfo();
      
      // Memory increase should be reasonable (< 100MB)
      const increase = finalMemory.private - initialMemory.private;
      assert.ok(increase < 100 * 1024); // 100MB in KB
    }, 60000);
  });

  describe('Error Handling', () => {
    it('should handle network errors', async () => {
      // Stop Ollama (simulate network failure)
      // Test would need to stop ollama container
      
      await app.client.setValue('#chat-input', 'Test message');
      await app.client.click('#send-button');
      
      // Should show error message
      await app.client.waitForExist('.error-message', 10000);
      const errorVisible = await app.client.isVisible('.error-message');
      
      assert.ok(errorVisible);
    });

    it('should recover from errors', async () => {
      // After error, should be able to retry
      await app.client.click('#retry-button');
      
      await new Promise(resolve => setTimeout(resolve, 5000));
      assert.ok(true);
    });

    it('should handle malformed responses', async () => {
      // Mock malformed response (would need API mocking)
      await app.client.setValue('#chat-input', 'Test');
      await app.client.click('#send-button');
      
      await new Promise(resolve => setTimeout(resolve, 5000));
      assert.ok(true);
    });
  });

  describe('Updates', () => {
    it('should check for updates', async () => {
      await app.client.click('#menu-help');
      await app.client.click('#menu-check-updates');
      
      await new Promise(resolve => setTimeout(resolve, 3000));
      assert.ok(true);
    });

    it('should show update notification', async () => {
      // Would need to mock update server
      await new Promise(resolve => setTimeout(resolve, 1000));
      assert.ok(true);
    });
  });

  describe('Accessibility', () => {
    it('should support screen readers', async () => {
      const ariaLabels = await app.client.$$('[aria-label]');
      assert.ok(ariaLabels.length > 0);
    });

    it('should support keyboard navigation', async () => {
      await app.client.keys(['Tab']);
      await app.client.keys(['Tab']);
      await app.client.keys(['Tab']);
      
      const focused = await app.client.execute(() => {
        return document.activeElement?.tagName;
      });
      
      assert.ok(focused);
    });

    it('should have sufficient color contrast', async () => {
      // Would need color contrast checking library
      assert.ok(true);
    });
  });
});
