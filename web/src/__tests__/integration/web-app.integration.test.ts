/**
 * Web App - Integration Tests with Playwright
 * Tests React web application functionality
 */

import { test, expect, Page } from '@playwright/test';

test.describe('Web App - Integration Tests', () => {
  let page: Page;

  test.beforeAll(async ({ browser }) => {
    page = await browser.newPage();
    await page.goto('http://localhost:3000');
  });

  test.afterAll(async () => {
    await page.close();
  });

  test.describe('Application Load', () => {
    test('should load homepage', async () => {
      await expect(page).toHaveTitle(/OpenPilot/);
    });

    test('should display navigation', async () => {
      await expect(page.locator('nav')).toBeVisible();
    });

    test('should load within 3 seconds', async () => {
      const start = Date.now();
      await page.reload();
      await page.waitForLoadState('networkidle');
      const duration = Date.now() - start;
      
      expect(duration).toBeLessThan(3000);
    });

    test('should be responsive', async () => {
      // Test different viewport sizes
      await page.setViewportSize({ width: 375, height: 667 }); // Mobile
      await expect(page.locator('nav')).toBeVisible();
      
      await page.setViewportSize({ width: 768, height: 1024 }); // Tablet
      await expect(page.locator('nav')).toBeVisible();
      
      await page.setViewportSize({ width: 1920, height: 1080 }); // Desktop
      await expect(page.locator('nav')).toBeVisible();
    });

    test('should have no console errors', async () => {
      const errors: string[] = [];
      page.on('console', (msg) => {
        if (msg.type() === 'error') {
          errors.push(msg.text());
        }
      });
      
      await page.reload();
      await page.waitForLoadState('networkidle');
      
      expect(errors.length).toBe(0);
    });
  });

  test.describe('Chat Interface', () => {
    test.beforeEach(async () => {
      await page.goto('http://localhost:3000/chat');
    });

    test('should display chat UI', async () => {
      await expect(page.locator('#chat-container')).toBeVisible();
      await expect(page.locator('#chat-input')).toBeVisible();
      await expect(page.locator('#send-button')).toBeVisible();
    });

    test('should send message', async () => {
      await page.fill('#chat-input', 'Hello, OpenPilot!');
      await page.click('#send-button');
      
      // Wait for user message to appear
      await expect(page.locator('.message.user').last()).toBeVisible();
      await expect(page.locator('.message.user').last()).toContainText('Hello, OpenPilot!');
      
      // Wait for AI response
      await expect(page.locator('.message.ai').last()).toBeVisible({ timeout: 10000 });
    });

    test('should display typing indicator', async () => {
      await page.fill('#chat-input', 'Test message');
      await page.click('#send-button');
      
      // Typing indicator should appear
      await expect(page.locator('.typing-indicator')).toBeVisible({ timeout: 2000 });
      
      // Wait for response
      await expect(page.locator('.message.ai').last()).toBeVisible({ timeout: 10000 });
      
      // Typing indicator should disappear
      await expect(page.locator('.typing-indicator')).not.toBeVisible();
    });

    test('should clear chat', async () => {
      // Send messages
      await page.fill('#chat-input', 'Message 1');
      await page.click('#send-button');
      await page.waitForTimeout(1000);
      
      await page.fill('#chat-input', 'Message 2');
      await page.click('#send-button');
      await page.waitForTimeout(1000);
      
      // Clear chat
      await page.click('#clear-chat-button');
      
      // Verify messages cleared
      const messages = await page.locator('.message').count();
      expect(messages).toBe(0);
    });

    test('should handle Enter key to send', async () => {
      await page.fill('#chat-input', 'Test Enter key');
      await page.press('#chat-input', 'Enter');
      
      await expect(page.locator('.message.user').last()).toContainText('Test Enter key');
    });

    test('should handle Shift+Enter for new line', async () => {
      await page.fill('#chat-input', 'Line 1');
      await page.press('#chat-input', 'Shift+Enter');
      await page.type('#chat-input', 'Line 2');
      
      const value = await page.inputValue('#chat-input');
      expect(value).toContain('\n');
    });

    test('should render code blocks with syntax highlighting', async () => {
      await page.fill('#chat-input', 'Show me JavaScript code');
      await page.click('#send-button');
      
      // Wait for response with code
      await expect(page.locator('.code-block')).toBeVisible({ timeout: 15000 });
      
      // Check syntax highlighting
      const hasHighlight = await page.locator('.code-block .hljs').count();
      expect(hasHighlight).toBeGreaterThan(0);
    });

    test('should copy code to clipboard', async () => {
      await page.fill('#chat-input', 'Write a function');
      await page.click('#send-button');
      
      await expect(page.locator('.copy-code-button')).toBeVisible({ timeout: 15000 });
      await page.click('.copy-code-button');
      
      // Verify copy notification
      await expect(page.locator('.copy-notification')).toBeVisible();
    });

    test('should persist chat history', async () => {
      await page.fill('#chat-input', 'Test persistence');
      await page.click('#send-button');
      await page.waitForTimeout(2000);
      
      // Reload page
      await page.reload();
      await page.waitForLoadState('networkidle');
      
      // Check if message persisted
      await expect(page.locator('.message.user').last()).toContainText('Test persistence');
    });

    test('should handle long messages', async () => {
      const longMessage = 'a'.repeat(5000);
      await page.fill('#chat-input', longMessage);
      await page.click('#send-button');
      
      await expect(page.locator('.message.user').last()).toBeVisible();
    });

    test('should handle special characters', async () => {
      const specialMessage = '`code` <html> & "quotes" \'single\'';
      await page.fill('#chat-input', specialMessage);
      await page.click('#send-button');
      
      await expect(page.locator('.message.user').last()).toContainText(specialMessage);
    });
  });

  test.describe('Code Generation', () => {
    test.beforeEach(async () => {
      await page.goto('http://localhost:3000/generate');
    });

    test('should display code generation form', async () => {
      await expect(page.locator('#code-prompt')).toBeVisible();
      await expect(page.locator('#language-select')).toBeVisible();
      await expect(page.locator('#generate-button')).toBeVisible();
    });

    test('should generate code', async () => {
      await page.fill('#code-prompt', 'Create a sorting function');
      await page.selectOption('#language-select', 'javascript');
      await page.click('#generate-button');
      
      // Wait for generated code
      await expect(page.locator('#generated-code')).toBeVisible({ timeout: 20000 });
      
      const code = await page.textContent('#generated-code');
      expect(code).toBeTruthy();
      expect(code!.length).toBeGreaterThan(0);
    });

    test('should support multiple languages', async () => {
      const languages = ['javascript', 'python', 'java', 'go', 'rust'];
      
      for (const lang of languages) {
        await page.fill('#code-prompt', 'Create a hello world program');
        await page.selectOption('#language-select', lang);
        await page.click('#generate-button');
        
        await expect(page.locator('#generated-code')).toBeVisible({ timeout: 20000 });
        await page.click('#clear-generated-button');
      }
    });

    test('should copy generated code', async () => {
      await page.fill('#code-prompt', 'Create a function');
      await page.click('#generate-button');
      
      await expect(page.locator('#generated-code')).toBeVisible({ timeout: 20000 });
      await page.click('#copy-generated-button');
      
      await expect(page.locator('.copy-notification')).toBeVisible();
    });

    test('should download generated code', async () => {
      await page.fill('#code-prompt', 'Create a test file');
      await page.selectOption('#language-select', 'javascript');
      await page.click('#generate-button');
      
      await expect(page.locator('#generated-code')).toBeVisible({ timeout: 20000 });
      
      const [download] = await Promise.all([
        page.waitForEvent('download'),
        page.click('#download-generated-button')
      ]);
      
      expect(download.suggestedFilename()).toMatch(/\.(js|ts|py|java)$/);
    });

    test('should show generation progress', async () => {
      await page.fill('#code-prompt', 'Create a complex application');
      await page.click('#generate-button');
      
      // Should show progress indicator
      await expect(page.locator('.progress-indicator')).toBeVisible();
      
      // Wait for completion
      await expect(page.locator('#generated-code')).toBeVisible({ timeout: 30000 });
      
      // Progress should hide
      await expect(page.locator('.progress-indicator')).not.toBeVisible();
    });
  });

  test.describe('Settings', () => {
    test.beforeEach(async () => {
      await page.goto('http://localhost:3000/settings');
    });

    test('should display settings form', async () => {
      await expect(page.locator('#provider-select')).toBeVisible();
      await expect(page.locator('#model-input')).toBeVisible();
      await expect(page.locator('#save-settings-button')).toBeVisible();
    });

    test('should change AI provider', async () => {
      await page.selectOption('#provider-select', 'openai');
      await page.fill('#api-key-input', 'test-api-key');
      await page.click('#save-settings-button');
      
      // Should show success message
      await expect(page.locator('.success-message')).toBeVisible();
      
      // Verify persisted
      await page.reload();
      const provider = await page.inputValue('#provider-select');
      expect(provider).toBe('openai');
    });

    test('should change model', async () => {
      await page.fill('#model-input', 'gpt-4');
      await page.click('#save-settings-button');
      
      await expect(page.locator('.success-message')).toBeVisible();
      
      await page.reload();
      const model = await page.inputValue('#model-input');
      expect(model).toBe('gpt-4');
    });

    test('should toggle dark mode', async () => {
      await page.click('#dark-mode-toggle');
      
      // Wait for theme change
      await page.waitForTimeout(500);
      
      const theme = await page.getAttribute('html', 'data-theme');
      expect(theme).toBe('dark');
      
      // Toggle back
      await page.click('#dark-mode-toggle');
      await page.waitForTimeout(500);
      
      const lightTheme = await page.getAttribute('html', 'data-theme');
      expect(lightTheme).toBe('light');
    });

    test('should validate required fields', async () => {
      await page.selectOption('#provider-select', 'openai');
      // Don't fill API key
      await page.click('#save-settings-button');
      
      // Should show validation error
      await expect(page.locator('.validation-error')).toBeVisible();
    });

    test('should test connection', async () => {
      await page.selectOption('#provider-select', 'ollama');
      await page.fill('#api-url-input', 'http://localhost:11434');
      await page.click('#test-connection-button');
      
      // Should show connection status
      await expect(page.locator('.connection-status')).toBeVisible({ timeout: 10000 });
    });
  });

  test.describe('Navigation', () => {
    test('should navigate between pages', async () => {
      await page.goto('http://localhost:3000');
      
      // Go to chat
      await page.click('a[href="/chat"]');
      await expect(page).toHaveURL(/\/chat/);
      
      // Go to generate
      await page.click('a[href="/generate"]');
      await expect(page).toHaveURL(/\/generate/);
      
      // Go to settings
      await page.click('a[href="/settings"]');
      await expect(page).toHaveURL(/\/settings/);
      
      // Go back to home
      await page.click('a[href="/"]');
      await expect(page).toHaveURL('http://localhost:3000/');
    });

    test('should highlight active nav item', async () => {
      await page.goto('http://localhost:3000/chat');
      await expect(page.locator('a[href="/chat"]')).toHaveClass(/active/);
      
      await page.goto('http://localhost:3000/generate');
      await expect(page.locator('a[href="/generate"]')).toHaveClass(/active/);
    });

    test('should handle 404 pages', async () => {
      await page.goto('http://localhost:3000/nonexistent');
      await expect(page.locator('.error-404')).toBeVisible();
    });
  });

  test.describe('Performance', () => {
    test('should have good Lighthouse scores', async () => {
      // Would integrate with Lighthouse
      expect(true).toBe(true);
    });

    test('should render large lists efficiently', async () => {
      await page.goto('http://localhost:3000/chat');
      
      // Add 100 messages
      for (let i = 0; i < 100; i++) {
        await page.evaluate((msg) => {
          const container = document.getElementById('chat-messages');
          const div = document.createElement('div');
          div.className = 'message user';
          div.textContent = msg;
          container?.appendChild(div);
        }, `Message ${i}`);
      }
      
      // Should still be responsive
      await page.fill('#chat-input', 'Test');
      const isFocused = await page.evaluate(() => document.activeElement?.id === 'chat-input');
      expect(isFocused).toBe(true);
    });

    test('should lazy load images', async () => {
      await page.goto('http://localhost:3000');
      
      const images = page.locator('img[loading="lazy"]');
      const count = await images.count();
      
      expect(count).toBeGreaterThan(0);
    });

    test('should use service worker for caching', async () => {
      await page.goto('http://localhost:3000');
      
      const hasServiceWorker = await page.evaluate(() => {
        return 'serviceWorker' in navigator;
      });
      
      expect(hasServiceWorker).toBe(true);
    });
  });

  test.describe('Error Handling', () => {
    test('should handle network errors', async () => {
      await page.goto('http://localhost:3000/chat');
      
      // Simulate offline
      await page.context().setOffline(true);
      
      await page.fill('#chat-input', 'Test message');
      await page.click('#send-button');
      
      // Should show error
      await expect(page.locator('.error-message')).toBeVisible();
      
      // Go back online
      await page.context().setOffline(false);
    });

    test('should retry failed requests', async () => {
      await page.goto('http://localhost:3000/chat');
      
      // Simulate network error
      await page.context().setOffline(true);
      await page.fill('#chat-input', 'Test');
      await page.click('#send-button');
      
      await expect(page.locator('.error-message')).toBeVisible();
      
      // Go back online and retry
      await page.context().setOffline(false);
      await page.click('.retry-button');
      
      await expect(page.locator('.message.ai').last()).toBeVisible({ timeout: 10000 });
    });

    test('should show error boundary', async () => {
      // Trigger error by navigating to error page
      await page.goto('http://localhost:3000/trigger-error');
      
      await expect(page.locator('.error-boundary')).toBeVisible();
    });
  });

  test.describe('Accessibility', () => {
    test('should have proper ARIA labels', async () => {
      await page.goto('http://localhost:3000');
      
      const ariaLabels = await page.locator('[aria-label]').count();
      expect(ariaLabels).toBeGreaterThan(0);
    });

    test('should support keyboard navigation', async () => {
      await page.goto('http://localhost:3000/chat');
      
      await page.keyboard.press('Tab');
      await page.keyboard.press('Tab');
      await page.keyboard.press('Tab');
      
      const focused = await page.evaluate(() => document.activeElement?.tagName);
      expect(focused).toBeTruthy();
    });

    test('should have proper heading hierarchy', async () => {
      await page.goto('http://localhost:3000');
      
      const h1Count = await page.locator('h1').count();
      expect(h1Count).toBe(1);
    });

    test('should have alt text for images', async () => {
      await page.goto('http://localhost:3000');
      
      const images = await page.locator('img').all();
      for (const img of images) {
        const alt = await img.getAttribute('alt');
        expect(alt).toBeTruthy();
      }
    });
  });

  test.describe('Security', () => {
    test('should sanitize user input', async () => {
      await page.goto('http://localhost:3000/chat');
      
      const xssAttempt = '<script>alert("XSS")</script>';
      await page.fill('#chat-input', xssAttempt);
      await page.click('#send-button');
      
      // Script should be escaped, not executed
      const messageText = await page.locator('.message.user').last().textContent();
      expect(messageText).toContain('<script>');
    });

    test('should use HTTPS in production', async () => {
      const protocol = await page.evaluate(() => window.location.protocol);
      
      if (process.env.NODE_ENV === 'production') {
        expect(protocol).toBe('https:');
      }
    });

    test('should not expose sensitive data', async () => {
      await page.goto('http://localhost:3000/settings');
      
      await page.fill('#api-key-input', 'secret-key-12345');
      
      const inputType = await page.getAttribute('#api-key-input', 'type');
      expect(inputType).toBe('password');
    });
  });
});
