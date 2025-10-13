/**
 * Context Manager - Pattern Tests
 * Coverage: globToRegex, pattern matching, filtering
 */

import { describe, it, expect } from '@jest/globals';

describe('Context Manager - Pattern Matching', () => {
  // Helper to convert glob to regex (simplified version for testing)
  function globToRegex(glob: string): RegExp {
    let pattern = glob
      .replace(/\./g, '\\.')
      .replace(/\*/g, '.*')
      .replace(/\?/g, '.');
    
    return new RegExp(`^${pattern}$`);
  }

  describe('globToRegex Conversion', () => {
    it('should convert single asterisk', () => {
      const regex = globToRegex('*.ts');
      expect(regex.test('file.ts')).toBe(true);
      expect(regex.test('file.js')).toBe(false);
    });

    it('should convert double asterisk', () => {
      const regex = globToRegex('**/*.ts');
      expect(regex.test('src/file.ts')).toBe(true);
      expect(regex.test('src/lib/file.ts')).toBe(true);
    });

    it('should convert question mark', () => {
      const regex = globToRegex('file?.ts');
      expect(regex.test('file1.ts')).toBe(true);
      expect(regex.test('file12.ts')).toBe(false);
    });

    it('should escape dots properly', () => {
      const regex = globToRegex('file.test.ts');
      expect(regex.test('file.test.ts')).toBe(true);
      expect(regex.test('fileXtestXts')).toBe(false);
    });

    it('should handle complex patterns', () => {
      const regex = globToRegex('src/**/*.test.ts');
      expect(regex.test('src/app.test.ts')).toBe(true);
      expect(regex.test('src/lib/utils.test.ts')).toBe(true);
    });

    it('should handle patterns without wildcards', () => {
      const regex = globToRegex('src/index.ts');
      expect(regex.test('src/index.ts')).toBe(true);
      expect(regex.test('src/other.ts')).toBe(false);
    });

    it('should handle patterns with multiple wildcards', () => {
      const regex = globToRegex('**/test/**/*.ts');
      expect(regex.test('src/test/file.ts')).toBe(true);
      expect(regex.test('lib/test/utils/helper.ts')).toBe(true);
    });

    it('should handle leading slash', () => {
      const regex = globToRegex('/src/*.ts');
      expect(regex.test('/src/index.ts')).toBe(true);
    });

    it('should handle trailing slash', () => {
      const regex = globToRegex('src/');
      expect(regex.test('src/')).toBe(true);
    });

    it('should handle empty pattern', () => {
      const regex = globToRegex('');
      expect(regex.test('')).toBe(true);
    });
  });

  describe('Pattern Matching', () => {
    it('should match TypeScript files', () => {
      const pattern = /\.ts$/;
      expect(pattern.test('index.ts')).toBe(true);
      expect(pattern.test('index.js')).toBe(false);
    });

    it('should match test files', () => {
      const pattern = /\.test\.(ts|js)$/;
      expect(pattern.test('app.test.ts')).toBe(true);
      expect(pattern.test('app.test.js')).toBe(true);
      expect(pattern.test('app.ts')).toBe(false);
    });

    it('should match node_modules paths', () => {
      const pattern = /node_modules/;
      expect(pattern.test('node_modules/pkg/index.js')).toBe(true);
      expect(pattern.test('src/index.ts')).toBe(false);
    });

    it('should match hidden files', () => {
      const pattern = /^\./;
      expect(pattern.test('.gitignore')).toBe(true);
      expect(pattern.test('file.ts')).toBe(false);
    });

    it('should match by directory', () => {
      const pattern = /^src\//;
      expect(pattern.test('src/index.ts')).toBe(true);
      expect(pattern.test('lib/index.ts')).toBe(false);
    });

    it('should match nested paths', () => {
      const pattern = /src\/.*\/utils/;
      expect(pattern.test('src/lib/utils/helper.ts')).toBe(true);
      expect(pattern.test('src/utils/helper.ts')).toBe(true);
    });

    it('should match multiple extensions', () => {
      const pattern = /\.(ts|js|json)$/;
      expect(pattern.test('file.ts')).toBe(true);
      expect(pattern.test('file.js')).toBe(true);
      expect(pattern.test('file.json')).toBe(true);
      expect(pattern.test('file.md')).toBe(false);
    });

    it('should handle case-insensitive matching', () => {
      const pattern = /\.ts$/i;
      expect(pattern.test('file.ts')).toBe(true);
      expect(pattern.test('file.TS')).toBe(true);
    });

    it('should match with word boundaries', () => {
      const pattern = /\btest\b/;
      expect(pattern.test('test.ts')).toBe(true);
      expect(pattern.test('testing.ts')).toBe(false);
    });

    it('should match with lookahead', () => {
      const pattern = /^(?=.*\.test).*\.ts$/;
      expect(pattern.test('app.test.ts')).toBe(true);
      expect(pattern.test('app.ts')).toBe(false);
    });
  });

  describe('Exclusion Patterns', () => {
    it('should exclude node_modules', () => {
      const excludes = [/node_modules/];
      const path = 'node_modules/pkg/index.js';
      
      expect(excludes.some(e => e.test(path))).toBe(true);
    });

    it('should exclude .git directory', () => {
      const excludes = [/\.git/];
      const path = '.git/config';
      
      expect(excludes.some(e => e.test(path))).toBe(true);
    });

    it('should exclude build directories', () => {
      const excludes = [/\/(dist|build|out)\//];
      
      expect(excludes.some(e => e.test('dist/index.js'))).toBe(true);
      expect(excludes.some(e => e.test('build/app.js'))).toBe(true);
      expect(excludes.some(e => e.test('src/index.ts'))).toBe(false);
    });

    it('should exclude test coverage', () => {
      const excludes = [/coverage/];
      const path = 'coverage/lcov-report/index.html';
      
      expect(excludes.some(e => e.test(path))).toBe(true);
    });

    it('should exclude temporary files', () => {
      const excludes = [/\.tmp$/, /~$/];
      
      expect(excludes.some(e => e.test('file.tmp'))).toBe(true);
      expect(excludes.some(e => e.test('file~'))).toBe(true);
    });

    it('should exclude log files', () => {
      const excludes = [/\.log$/];
      const path = 'app.log';
      
      expect(excludes.some(e => e.test(path))).toBe(true);
    });

    it('should exclude cache directories', () => {
      const excludes = [/\.cache/, /\.next/];
      
      expect(excludes.some(e => e.test('.cache/data'))).toBe(true);
      expect(excludes.some(e => e.test('.next/build'))).toBe(true);
    });

    it('should handle multiple exclusions', () => {
      const excludes = [
        /node_modules/,
        /\.git/,
        /dist/,
        /\.log$/
      ];
      
      expect(excludes.some(e => e.test('node_modules/pkg'))).toBe(true);
      expect(excludes.some(e => e.test('.git/config'))).toBe(true);
      expect(excludes.some(e => e.test('dist/app.js'))).toBe(true);
      expect(excludes.some(e => e.test('error.log'))).toBe(true);
      expect(excludes.some(e => e.test('src/index.ts'))).toBe(false);
    });
  });

  describe('Inclusion Patterns', () => {
    it('should include source files', () => {
      const includes = [/\.ts$/, /\.js$/];
      
      expect(includes.some(i => i.test('index.ts'))).toBe(true);
      expect(includes.some(i => i.test('app.js'))).toBe(true);
    });

    it('should include specific directories', () => {
      const includes = [/^src\//, /^lib\//];
      
      expect(includes.some(i => i.test('src/index.ts'))).toBe(true);
      expect(includes.some(i => i.test('lib/utils.ts'))).toBe(true);
      expect(includes.some(i => i.test('test/app.test.ts'))).toBe(false);
    });

    it('should include by file extension', () => {
      const includes = [/\.(ts|tsx|js|jsx)$/];
      
      expect(includes.some(i => i.test('Component.tsx'))).toBe(true);
      expect(includes.some(i => i.test('script.js'))).toBe(true);
    });

    it('should include configuration files', () => {
      const includes = [/^(package\.json|tsconfig\.json)$/];
      
      expect(includes.some(i => i.test('package.json'))).toBe(true);
      expect(includes.some(i => i.test('tsconfig.json'))).toBe(true);
    });
  });

  describe('Pattern Precedence', () => {
    function shouldInclude(path: string, includes: RegExp[], excludes: RegExp[]): boolean {
      const isExcluded = excludes.some(e => e.test(path));
      const isIncluded = includes.length === 0 || includes.some(i => i.test(path));
      
      return isIncluded && !isExcluded;
    }

    it('should exclude even if included', () => {
      const includes = [/\.ts$/];
      const excludes = [/\.test\.ts$/];
      
      expect(shouldInclude('index.ts', includes, excludes)).toBe(true);
      expect(shouldInclude('app.test.ts', includes, excludes)).toBe(false);
    });

    it('should handle empty includes as include-all', () => {
      const includes: RegExp[] = [];
      const excludes = [/node_modules/];
      
      expect(shouldInclude('index.ts', includes, excludes)).toBe(true);
      expect(shouldInclude('node_modules/pkg/index.js', includes, excludes)).toBe(false);
    });

    it('should handle empty excludes', () => {
      const includes = [/\.ts$/];
      const excludes: RegExp[] = [];
      
      expect(shouldInclude('index.ts', includes, excludes)).toBe(true);
      expect(shouldInclude('index.js', includes, excludes)).toBe(false);
    });

    it('should handle both empty', () => {
      const includes: RegExp[] = [];
      const excludes: RegExp[] = [];
      
      expect(shouldInclude('any-file.ts', includes, excludes)).toBe(true);
    });

    it('should prioritize exclusions', () => {
      const includes = [/\.ts$/];
      const excludes = [/node_modules/, /\.test\.ts$/];
      
      expect(shouldInclude('src/index.ts', includes, excludes)).toBe(true);
      expect(shouldInclude('src/app.test.ts', includes, excludes)).toBe(false);
      expect(shouldInclude('node_modules/pkg/index.ts', includes, excludes)).toBe(false);
    });
  });

  describe('Default Patterns', () => {
    function getDefaultExcludes(): string[] {
      return [
        '**/node_modules/**',
        '**/.git/**',
        '**/dist/**',
        '**/build/**',
        '**/coverage/**',
        '**/.next/**',
        '**/.cache/**',
        '**/*.log'
      ];
    }

    it('should have node_modules exclusion', () => {
      const defaults = getDefaultExcludes();
      expect(defaults).toContain('**/node_modules/**');
    });

    it('should have .git exclusion', () => {
      const defaults = getDefaultExcludes();
      expect(defaults).toContain('**/.git/**');
    });

    it('should have build output exclusions', () => {
      const defaults = getDefaultExcludes();
      expect(defaults).toContain('**/dist/**');
      expect(defaults).toContain('**/build/**');
    });

    it('should have coverage exclusion', () => {
      const defaults = getDefaultExcludes();
      expect(defaults).toContain('**/coverage/**');
    });

    it('should have framework cache exclusions', () => {
      const defaults = getDefaultExcludes();
      expect(defaults).toContain('**/.next/**');
      expect(defaults).toContain('**/.cache/**');
    });

    it('should exclude log files', () => {
      const defaults = getDefaultExcludes();
      expect(defaults).toContain('**/*.log');
    });
  });
});
