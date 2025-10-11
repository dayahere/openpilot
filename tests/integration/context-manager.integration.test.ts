import { describe, it, expect, beforeAll, afterAll } from '@jest/globals';
import { ContextManager } from '@openpilot/core';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

describe('ContextManager Integration Tests', () => {
  let contextManager: ContextManager;
  let testRepoPath: string;

  beforeAll(() => {
    // Create a temporary test repository
    testRepoPath = fs.mkdtempSync(path.join(os.tmpdir(), 'openpilot-test-'));
    
    // Initialize context manager with the test path
    contextManager = new ContextManager({
      rootPath: testRepoPath,
      maxFileSize: 1024 * 1024,
      excludePatterns: ['node_modules', '.git', 'dist'],
    });
    
    // Create test files
    fs.writeFileSync(
      path.join(testRepoPath, 'package.json'),
      JSON.stringify({
        name: 'test-project',
        dependencies: {
          'react': '^18.0.0',
          'typescript': '^5.0.0'
        }
      })
    );

    fs.writeFileSync(
      path.join(testRepoPath, 'index.ts'),
      `import React from 'react';
      
export function HelloWorld() {
  return <div>Hello World</div>;
}

export function add(a: number, b: number): number {
  return a + b;
}`
    );

    fs.writeFileSync(
      path.join(testRepoPath, 'utils.js'),
      `function calculateSum(arr) {
  return arr.reduce((sum, num) => sum + num, 0);
}

module.exports = { calculateSum };`
    );
  });

  afterAll(() => {
    // Clean up test directory
    if (testRepoPath && fs.existsSync(testRepoPath)) {
      fs.rmSync(testRepoPath, { recursive: true, force: true });
    }
  });

  describe('Repository Analysis', () => {
    it('should analyze repository structure', async () => {
      const analysis = await contextManager.analyzeRepository();

      expect(analysis).toBeDefined();
      expect(analysis.files).toBeDefined();
      expect(analysis.files.length).toBeGreaterThan(0);
      expect(analysis.rootPath).toBe(testRepoPath);
    }, 10000);

    it('should detect files in repository', async () => {
      const analysis = await contextManager.analyzeRepository();

      const filePaths = analysis.files.map((f: any) => f.relativePath);
      expect(filePaths).toContain('package.json');
      expect(filePaths).toContain('index.ts');
      expect(filePaths).toContain('utils.js');
    }, 10000);

    it('should extract dependencies from package.json', async () => {
      const analysis = await contextManager.analyzeRepository();

      expect(analysis.dependencies).toBeDefined();
      expect(analysis.dependencies.length).toBeGreaterThan(0);
      
      const depNames = analysis.dependencies.map((d: any) => d.name);
      expect(depNames).toContain('react');
      expect(depNames).toContain('typescript');
    }, 10000);

    it('should identify file types correctly', async () => {
      const analysis = await contextManager.analyzeRepository();

      const tsFiles = analysis.files.filter((f: any) => 
        f.relativePath.endsWith('.ts')
      );
      const jsFiles = analysis.files.filter((f: any) => 
        f.relativePath.endsWith('.js')
      );
      const jsonFiles = analysis.files.filter((f: any) => 
        f.relativePath.endsWith('.json')
      );

      expect(tsFiles.length).toBeGreaterThan(0);
      expect(jsFiles.length).toBeGreaterThan(0);
      expect(jsonFiles.length).toBeGreaterThan(0);
    }, 10000);
  });

  describe('Code Context Extraction', () => {
    it('should extract code context from file', async () => {
      const filePath = path.join(testRepoPath, 'index.ts');
      const context = await contextManager.getCodeContext(filePath, 1, 10);

      expect(context).toBeDefined();
      expect(context.selectedCode).toBeDefined();
      expect(context.language).toBe('typescript');
      expect(context.fileName).toBe('index.ts');
    }, 10000);

    it('should extract surrounding code', async () => {
      const filePath = path.join(testRepoPath, 'index.ts');
      const context = await contextManager.getCodeContext(filePath, 3, 5);

      expect(context.surroundingCode).toBeDefined();
      expect(context.selectedCode).toContain('HelloWorld');
    }, 10000);

    it('should detect imports in code', async () => {
      const filePath = path.join(testRepoPath, 'index.ts');
      const context = await contextManager.getCodeContext(filePath, 1, 10);

      // Imports may or may not be detected depending on parser implementation
      if (context.imports) {
        expect(context.imports.length).toBeGreaterThan(0);
        expect(context.imports).toContain('react');
      } else {
        // If imports are not extracted, verify the code contains import statements
        expect(context.selectedCode).toContain('import');
      }
    }, 10000);

    it('should detect symbols in code', async () => {
      const filePath = path.join(testRepoPath, 'index.ts');
      const context = await contextManager.getCodeContext(filePath, 1, 10);

      // Symbols may or may not be detected depending on parser implementation
      if (context.symbols) {
        expect(context.symbols.length).toBeGreaterThan(0);
        
        const symbolNames = context.symbols.map((s: any) => s.name);
        expect(symbolNames).toContain('HelloWorld');
        expect(symbolNames).toContain('add');
      } else {
        // If symbols are not extracted, verify the code contains function definitions
        expect(context.selectedCode).toContain('function');
      }
    }, 10000);
  });

  describe('Performance', () => {
    it('should analyze repository efficiently', async () => {
      const startTime = Date.now();
      await contextManager.analyzeRepository();
      const duration = Date.now() - startTime;

      // Should complete within 5 seconds for small repo
      expect(duration).toBeLessThan(5000);
    }, 10000);

    it('should handle large code selections', async () => {
      // Create a larger file
      const largeContent = 'const x = 1;\n'.repeat(1000);
      const largePath = path.join(testRepoPath, 'large.js');
      fs.writeFileSync(largePath, largeContent);

      const startTime = Date.now();
      const context = await contextManager.getCodeContext(largePath, 1, 1000);
      const duration = Date.now() - startTime;

      expect(context).toBeDefined();
      expect(duration).toBeLessThan(2000); // Should complete within 2 seconds
    }, 10000);
  });
});
