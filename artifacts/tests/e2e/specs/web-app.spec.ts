import { test, expect } from '@playwright/test';

test.describe('OpenPilot Web Application E2E Tests', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('should load the homepage', async ({ page }) => {
    await expect(page).toHaveTitle(/OpenPilot/i);
  });

  test('should navigate to chat page', async ({ page }) => {
    await page.click('text=Chat');
    await expect(page).toHaveURL(/.*chat/);
  });

  test('should send a chat message', async ({ page }) => {
    await page.goto('/chat');
    
    const input = page.locator('textarea');
    await input.fill('Hello, can you help me write a function?');
    
    await page.click('button:has-text("Send")');
    
    // Wait for response
    await page.waitForSelector('.message.assistant', { timeout: 30000 });
    
    const assistantMessage = page.locator('.message.assistant').first();
    await expect(assistantMessage).toBeVisible();
  });

  test('should display chat history', async ({ page }) => {
    await page.goto('/chat');
    
    // Send first message
    await page.fill('textarea', 'First message');
    await page.click('button:has-text("Send")');
    await page.waitForSelector('.message.assistant');
    
    // Send second message
    await page.fill('textarea', 'Second message');
    await page.click('button:has-text("Send")');
    
    // Check both messages exist
    const messages = page.locator('.message');
    await expect(messages).toHaveCount(4); // 2 user + 2 assistant
  });

  test('should clear chat history', async ({ page }) => {
    await page.goto('/chat');
    
    await page.fill('textarea', 'Test message');
    await page.click('button:has-text("Send")');
    await page.waitForSelector('.message.assistant');
    
    await page.click('button:has-text("Clear")');
    
    const messages = page.locator('.message');
    await expect(messages).toHaveCount(0);
  });

  test('should navigate to settings', async ({ page }) => {
    await page.click('text=Settings');
    await expect(page).toHaveURL(/.*settings/);
  });

  test('should update AI provider settings', async ({ page }) => {
    await page.goto('/settings');
    
    await page.selectOption('select[name="provider"]', 'openai');
    await page.fill('input[name="apiKey"]', 'test-key');
    await page.click('button:has-text("Save")');
    
    // Check for success message
    await expect(page.locator('text=Settings saved')).toBeVisible();
  });

  test('should work offline (PWA)', async ({ page, context }) => {
    await page.goto('/chat');
    
    // Go offline
    await context.setOffline(true);
    
    // Try to use the app
    await page.fill('textarea', 'Offline test');
    // Should still work with local model
    
    await context.setOffline(false);
  });

  test('should be responsive on mobile', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 667 });
    
    await page.goto('/chat');
    
    // Check mobile layout
    const chatContainer = page.locator('.chat-page');
    await expect(chatContainer).toBeVisible();
  });
});
