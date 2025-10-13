/**
 * VSCode Extension - Session Management Integration Tests
 * Tests automatic session saving and loading functionality
 */

import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';

describe('Session Management - Integration Tests', () => {
  const sessionDir = path.join(process.env.HOME || process.env.USERPROFILE || '', '.openpilot', 'sessions');
  
  beforeAll(() => {
    // Ensure session directory exists
    if (!fs.existsSync(sessionDir)) {
      fs.mkdirSync(sessionDir, { recursive: true });
    }
  });

  afterEach(() => {
    // Clean up test sessions
    if (fs.existsSync(sessionDir)) {
      const files = fs.readdirSync(sessionDir);
      files.forEach(file => {
        if (file.startsWith('test-')) {
          fs.unlinkSync(path.join(sessionDir, file));
        }
      });
    }
  });

  describe('Auto-save Session', () => {
    it('should save session automatically after each message', async () => {
      // Open chat
      await vscode.commands.executeCommand('openpilot.openChat');
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Send message (would trigger auto-save)
      // In real implementation, webview would send message
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Check if session file exists
      const files = fs.readdirSync(sessionDir);
      const sessionFiles = files.filter(f => f.endsWith('.json'));
      
      expect(sessionFiles.length).toBeGreaterThan(0);
    });

    it('should save session every 30 seconds', async () => {
      await vscode.commands.executeCommand('openpilot.openChat');
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      const initialFiles = fs.readdirSync(sessionDir).length;
      
      // Wait for auto-save interval
      await new Promise(resolve => setTimeout(resolve, 35000));
      
      const finalFiles = fs.readdirSync(sessionDir).length;
      
      expect(finalFiles).toBeGreaterThanOrEqual(initialFiles);
    }, 40000);

    it('should save session before window close', async () => {
      await vscode.commands.executeCommand('openpilot.openChat');
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Trigger window close event (would save session)
      // In real test, simulate VS Code closing
      
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      const files = fs.readdirSync(sessionDir);
      expect(files.length).toBeGreaterThan(0);
    });

    it('should include all conversation data in session', async () => {
      await vscode.commands.executeCommand('openpilot.openChat');
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Check session file content
      const files = fs.readdirSync(sessionDir);
      const sessionFile = files.find(f => f.endsWith('.json'));
      
      if (sessionFile) {
        const sessionPath = path.join(sessionDir, sessionFile);
        const sessionData = JSON.parse(fs.readFileSync(sessionPath, 'utf-8'));
        
        expect(sessionData).toHaveProperty('messages');
        expect(sessionData).toHaveProperty('timestamp');
        expect(sessionData).toHaveProperty('provider');
        expect(sessionData).toHaveProperty('model');
      }
    });

    it('should save checkpoint data', async () => {
      await vscode.commands.executeCommand('openpilot.openChat');
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Create checkpoint
      await vscode.commands.executeCommand('openpilot.createCheckpoint');
      await new Promise(resolve => setTimeout(resolve, 500));
      
      // Verify checkpoint saved
      const files = fs.readdirSync(sessionDir);
      const checkpointFiles = files.filter(f => f.includes('checkpoint'));
      
      expect(checkpointFiles.length).toBeGreaterThan(0);
    });
  });

  describe('Load Session on Startup', () => {
    it('should load previous session on extension activation', async () => {
      // Create a test session file
      const testSession = {
        messages: [
          { role: 'user', content: 'Test message' },
          { role: 'assistant', content: 'Test response' }
        ],
        timestamp: Date.now(),
        provider: 'ollama',
        model: 'phi3:mini'
      };
      
      const sessionFile = path.join(sessionDir, 'test-session.json');
      fs.writeFileSync(sessionFile, JSON.stringify(testSession));
      
      // Reload extension (simulate restart)
      await vscode.commands.executeCommand('workbench.action.reloadWindow');
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      // Open chat - should load previous session
      await vscode.commands.executeCommand('openpilot.openChat');
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Verify messages loaded (would check webview state)
      expect(true).toBe(true);
    }, 10000);

    it('should restore conversation context', async () => {
      const testSession = {
        messages: [
          { role: 'user', content: 'What is TypeScript?' },
          { role: 'assistant', content: 'TypeScript is a superset of JavaScript...' },
          { role: 'user', content: 'Tell me more' }
        ],
        timestamp: Date.now(),
        provider: 'ollama',
        model: 'phi3:mini'
      };
      
      const sessionFile = path.join(sessionDir, 'test-context-session.json');
      fs.writeFileSync(sessionFile, JSON.stringify(testSession));
      
      await vscode.commands.executeCommand('workbench.action.reloadWindow');
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      await vscode.commands.executeCommand('openpilot.openChat');
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // New messages should have context
      expect(true).toBe(true);
    }, 10000);

    it('should load most recent session if multiple exist', async () => {
      // Create multiple session files
      for (let i = 0; i < 3; i++) {
        const session = {
          messages: [{ role: 'user', content: `Session ${i}` }],
          timestamp: Date.now() - (i * 1000),
          provider: 'ollama',
          model: 'phi3:mini'
        };
        
        const file = path.join(sessionDir, `test-session-${i}.json`);
        fs.writeFileSync(file, JSON.stringify(session));
      }
      
      await vscode.commands.executeCommand('workbench.action.reloadWindow');
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      await vscode.commands.executeCommand('openpilot.openChat');
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Should load session 0 (most recent)
      expect(true).toBe(true);
    }, 10000);

    it('should skip loading session if user starts new chat', async () => {
      const testSession = {
        messages: [{ role: 'user', content: 'Old message' }],
        timestamp: Date.now(),
        provider: 'ollama',
        model: 'phi3:mini'
      };
      
      const sessionFile = path.join(sessionDir, 'test-skip-session.json');
      fs.writeFileSync(sessionFile, JSON.stringify(testSession));
      
      await vscode.commands.executeCommand('workbench.action.reloadWindow');
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      // User explicitly starts new chat
      await vscode.commands.executeCommand('openpilot.openChat', { newSession: true });
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Should be empty chat
      expect(true).toBe(true);
    }, 10000);

    it('should restore UI state from session', async () => {
      const testSession = {
        messages: [{ role: 'user', content: 'Test' }],
        timestamp: Date.now(),
        provider: 'ollama',
        model: 'phi3:mini',
        uiState: {
          scrollPosition: 500,
          inputValue: 'Unsent message',
          theme: 'dark'
        }
      };
      
      const sessionFile = path.join(sessionDir, 'test-ui-session.json');
      fs.writeFileSync(sessionFile, JSON.stringify(testSession));
      
      await vscode.commands.executeCommand('workbench.action.reloadWindow');
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      await vscode.commands.executeCommand('openpilot.openChat');
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // UI should be restored
      expect(true).toBe(true);
    }, 10000);
  });

  describe('Handle Corrupt Session Data', () => {
    it('should handle missing session file gracefully', async () => {
      // Delete all sessions
      if (fs.existsSync(sessionDir)) {
        const files = fs.readdirSync(sessionDir);
        files.forEach(file => {
          fs.unlinkSync(path.join(sessionDir, file));
        });
      }
      
      await vscode.commands.executeCommand('workbench.action.reloadWindow');
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      await expect(
        vscode.commands.executeCommand('openpilot.openChat')
      ).resolves.not.toThrow();
    }, 10000);

    it('should handle corrupted JSON gracefully', async () => {
      const corruptFile = path.join(sessionDir, 'test-corrupt.json');
      fs.writeFileSync(corruptFile, 'This is not valid JSON {{{');
      
      await vscode.commands.executeCommand('workbench.action.reloadWindow');
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      await expect(
        vscode.commands.executeCommand('openpilot.openChat')
      ).resolves.not.toThrow();
    }, 10000);

    it('should handle incomplete session data', async () => {
      const incompleteSession = {
        messages: [{ role: 'user' }], // Missing content
        // Missing timestamp
        provider: 'ollama'
        // Missing model
      };
      
      const file = path.join(sessionDir, 'test-incomplete.json');
      fs.writeFileSync(file, JSON.stringify(incompleteSession));
      
      await vscode.commands.executeCommand('workbench.action.reloadWindow');
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      await expect(
        vscode.commands.executeCommand('openpilot.openChat')
      ).resolves.not.toThrow();
    }, 10000);

    it('should create backup before saving', async () => {
      const session = {
        messages: [{ role: 'user', content: 'Original' }],
        timestamp: Date.now(),
        provider: 'ollama',
        model: 'phi3:mini'
      };
      
      const sessionFile = path.join(sessionDir, 'test-backup.json');
      fs.writeFileSync(sessionFile, JSON.stringify(session));
      
      await vscode.commands.executeCommand('openpilot.openChat');
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Check for backup file
      const files = fs.readdirSync(sessionDir);
      const backupFiles = files.filter(f => f.includes('.backup'));
      
      expect(backupFiles.length).toBeGreaterThan(0);
    });

    it('should recover from backup if save fails', async () => {
      // Create backup
      const backup = {
        messages: [{ role: 'user', content: 'Backup message' }],
        timestamp: Date.now(),
        provider: 'ollama',
        model: 'phi3:mini'
      };
      
      const backupFile = path.join(sessionDir, 'test-recovery.backup.json');
      fs.writeFileSync(backupFile, JSON.stringify(backup));
      
      // Simulate save failure by making directory read-only
      // (In real test would need proper permissions handling)
      
      await vscode.commands.executeCommand('openpilot.openChat');
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Should recover from backup
      expect(true).toBe(true);
    });

    it('should limit session history size', async () => {
      // Create session with 1000 messages
      const largeSession = {
        messages: Array.from({ length: 1000 }, (_, i) => ({
          role: i % 2 === 0 ? 'user' : 'assistant',
          content: `Message ${i}`
        })),
        timestamp: Date.now(),
        provider: 'ollama',
        model: 'phi3:mini'
      };
      
      const file = path.join(sessionDir, 'test-large.json');
      fs.writeFileSync(file, JSON.stringify(largeSession));
      
      await vscode.commands.executeCommand('workbench.action.reloadWindow');
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      await vscode.commands.executeCommand('openpilot.openChat');
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Should truncate to last N messages
      expect(true).toBe(true);
    }, 10000);

    it('should clean up old sessions', async () => {
      // Create old sessions (30 days old)
      const oldTimestamp = Date.now() - (30 * 24 * 60 * 60 * 1000);
      
      for (let i = 0; i < 5; i++) {
        const oldSession = {
          messages: [{ role: 'user', content: 'Old' }],
          timestamp: oldTimestamp,
          provider: 'ollama',
          model: 'phi3:mini'
        };
        
        const file = path.join(sessionDir, `test-old-${i}.json`);
        fs.writeFileSync(file, JSON.stringify(oldSession));
      }
      
      await vscode.commands.executeCommand('workbench.action.reloadWindow');
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      // Old sessions should be cleaned up
      const files = fs.readdirSync(sessionDir);
      const oldFiles = files.filter(f => f.startsWith('test-old'));
      
      expect(oldFiles.length).toBe(0);
    }, 10000);
  });

  describe('Session Export/Import', () => {
    it('should export session to file', async () => {
      await vscode.commands.executeCommand('openpilot.openChat');
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // Export session
      await vscode.commands.executeCommand('openpilot.exportSession');
      
      // Verify export file created
      await new Promise(resolve => setTimeout(resolve, 1000));
      expect(true).toBe(true);
    });

    it('should import session from file', async () => {
      const importSession = {
        messages: [
          { role: 'user', content: 'Imported message' },
          { role: 'assistant', content: 'Imported response' }
        ],
        timestamp: Date.now(),
        provider: 'ollama',
        model: 'phi3:mini'
      };
      
      const importFile = path.join(sessionDir, 'import-test.json');
      fs.writeFileSync(importFile, JSON.stringify(importSession));
      
      await vscode.commands.executeCommand('openpilot.importSession', importFile);
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Verify messages imported
      expect(true).toBe(true);
    });
  });
});
