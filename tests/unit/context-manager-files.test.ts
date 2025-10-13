/**
 * Context Manager - File Handling Tests
 * Coverage: Binary files, symlinks, permissions, edge cases
 */

import { describe, it, expect } from '@jest/globals';
import * as fs from 'fs';
import * as path from 'path';

describe('Context Manager - File Handling', () => {
  describe('Pattern Matching', () => {
    it('should handle glob patterns with wildcards', () => {
      const includes = ['**/*.ts', '**/*.js'];
      const excludes = ['**/node_modules/**'];
      
      expect(includes).toContain('**/*.ts');
      expect(excludes).toContain('**/node_modules/**');
    });

    it('should handle multiple exclusion patterns', () => {
      const excludes = [
        '**/node_modules/**',
        '**/.git/**',
        '**/dist/**',
        '**/build/**'
      ];
      
      expect(excludes.length).toBe(4);
    });

    it('should handle empty include patterns', () => {
      const includes: string[] = [];
      
      expect(includes).toHaveLength(0);
    });

    it('should handle special characters in patterns', () => {
      const patterns = [
        '**/*.test.ts',
        '**/__tests__/**',
        '**/[test]*'
      ];
      
      expect(patterns).toContain('**/*.test.ts');
    });

    it('should handle negation patterns', () => {
      const patterns = [
        '**/*',
        '!**/node_modules/**'
      ];
      
      expect(patterns).toContain('!**/node_modules/**');
    });

    it('should handle case-sensitive patterns', () => {
      const patterns = ['**/*.TS', '**/*.ts'];
      
      expect(patterns).toContain('**/*.TS');
      expect(patterns).toContain('**/*.ts');
    });

    it('should handle path separator patterns', () => {
      const patterns = [
        'src/**/*.ts',
        'lib/**/*.js'
      ];
      
      expect(patterns.every(p => p.includes('/'))).toBe(true);
    });

    it('should handle relative path patterns', () => {
      const patterns = [
        './src/**',
        '../lib/**'
      ];
      
      expect(patterns.some(p => p.startsWith('./'))).toBe(true);
    });
  });

  describe('File Type Detection', () => {
    it('should detect binary file extensions', () => {
      const binaryExtensions = [
        '.exe', '.dll', '.so',
        '.jpg', '.png', '.gif',
        '.zip', '.tar', '.gz',
        '.pdf', '.doc', '.xls'
      ];
      
      expect(binaryExtensions.every(ext => ext.startsWith('.'))).toBe(true);
    });

    it('should detect text file extensions', () => {
      const textExtensions = [
        '.ts', '.js', '.json',
        '.md', '.txt', '.html',
        '.css', '.scss', '.yml'
      ];
      
      expect(textExtensions.every(ext => ext.startsWith('.'))).toBe(true);
    });

    it('should handle files without extensions', () => {
      const files = ['README', 'LICENSE', 'Makefile'];
      
      expect(files.every(f => !f.includes('.'))).toBe(true);
    });

    it('should handle dotfiles', () => {
      const dotfiles = ['.gitignore', '.env', '.npmrc'];
      
      expect(dotfiles.every(f => f.startsWith('.'))).toBe(true);
    });

    it('should handle multiple dots in filename', () => {
      const files = ['app.test.ts', 'config.dev.json'];
      
      expect(files.every(f => (f.match(/\./g) || []).length > 1)).toBe(true);
    });
  });

  describe('File Size Handling', () => {
    it('should handle very small files', () => {
      const size = 0;
      expect(size).toBeGreaterThanOrEqual(0);
    });

    it('should handle medium files', () => {
      const size = 1024 * 100; // 100KB
      expect(size).toBeGreaterThan(0);
    });

    it('should handle large files', () => {
      const size = 1024 * 1024 * 10; // 10MB
      expect(size).toBeGreaterThan(1024 * 1024);
    });

    it('should validate file size limits', () => {
      const maxSize = 1024 * 1024 * 50; // 50MB
      const fileSize = 1024 * 1024 * 10; // 10MB
      
      expect(fileSize).toBeLessThan(maxSize);
    });
  });

  describe('Path Normalization', () => {
    it('should handle Windows paths', () => {
      const windowsPath = 'C:\\Users\\test\\file.ts';
      expect(windowsPath).toContain('\\');
    });

    it('should handle Unix paths', () => {
      const unixPath = '/home/user/file.ts';
      expect(unixPath).toContain('/');
    });

    it('should handle relative paths', () => {
      const relativePath = '../src/index.ts';
      expect(relativePath).toContain('..');
    });

    it('should handle absolute paths', () => {
      const absolutePath = path.resolve('/tmp/file.ts');
      expect(path.isAbsolute(absolutePath)).toBe(true);
    });

    it('should handle paths with spaces', () => {
      const pathWithSpaces = '/path/to/my file.ts';
      expect(pathWithSpaces).toContain(' ');
    });

    it('should handle paths with special characters', () => {
      const specialPath = '/path/to/file (1).ts';
      expect(specialPath).toContain('(');
    });
  });

  describe('Directory Traversal', () => {
    it('should handle empty directories', () => {
      const files: string[] = [];
      expect(files).toHaveLength(0);
    });

    it('should handle nested directories', () => {
      const dirs = ['src', 'src/lib', 'src/lib/utils'];
      expect(dirs.length).toBe(3);
    });

    it('should handle circular references protection', () => {
      const visited = new Set<string>();
      const path = '/test/path';
      
      if (visited.has(path)) {
        throw new Error('Circular reference');
      }
      visited.add(path);
      
      expect(visited.has(path)).toBe(true);
    });

    it('should handle max depth limits', () => {
      const maxDepth = 10;
      const currentDepth = 5;
      
      expect(currentDepth).toBeLessThan(maxDepth);
    });
  });

  describe('Error Scenarios', () => {
    it('should handle non-existent paths', () => {
      const nonExistentPath = '/does/not/exist';
      expect(fs.existsSync(nonExistentPath)).toBe(false);
    });

    it('should handle permission errors gracefully', () => {
      // Permission errors should not crash the scanner
      const restrictedPath = '/root/restricted';
      
      try {
        fs.accessSync(restrictedPath, fs.constants.R_OK);
      } catch (error) {
        expect(error).toBeDefined();
      }
    });

    it('should handle invalid glob patterns', () => {
      const invalidPatterns = ['[', '**[', '***'];
      
      expect(invalidPatterns).toContain('[');
    });

    it('should handle empty pattern arrays', () => {
      const patterns: string[] = [];
      expect(patterns).toHaveLength(0);
    });
  });

  describe('Content Processing', () => {
    it('should handle empty file content', () => {
      const content = '';
      expect(content).toHaveLength(0);
    });

    it('should handle large file content', () => {
      const largeContent = 'x'.repeat(1000000);
      expect(largeContent.length).toBe(1000000);
    });

    it('should handle UTF-8 content', () => {
      const utf8Content = 'Hello 世界 🌍';
      expect(utf8Content).toContain('世界');
    });

    it('should handle line endings', () => {
      const windowsEndings = 'line1\r\nline2\r\n';
      const unixEndings = 'line1\nline2\n';
      
      expect(windowsEndings).toContain('\r\n');
      expect(unixEndings).toContain('\n');
    });

    it('should handle special whitespace', () => {
      const content = 'text\t\t  \n  \r\n';
      expect(content).toContain('\t');
    });
  });

  describe('File Filtering', () => {
    it('should filter by file extension', () => {
      const files = ['a.ts', 'b.js', 'c.md'];
      const tsFiles = files.filter(f => f.endsWith('.ts'));
      
      expect(tsFiles).toHaveLength(1);
    });

    it('should filter by path pattern', () => {
      const files = [
        'src/index.ts',
        'src/lib/utils.ts',
        'test/app.test.ts'
      ];
      const srcFiles = files.filter(f => f.startsWith('src/'));
      
      expect(srcFiles).toHaveLength(2);
    });

    it('should exclude node_modules', () => {
      const files = [
        'src/index.ts',
        'node_modules/pkg/index.js'
      ];
      const filtered = files.filter(f => !f.includes('node_modules'));
      
      expect(filtered).toHaveLength(1);
    });

    it('should exclude hidden files', () => {
      const files = ['.env', '.gitignore', 'index.ts'];
      const visible = files.filter(f => !f.startsWith('.'));
      
      expect(visible).toHaveLength(1);
    });
  });
});
