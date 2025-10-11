import * as fs from 'fs';
import * as path from 'path';
import { promisify } from 'util';
import {
  RepositoryContext,
  FileInfo,
  CodeContext,
  IndexedContent,
  ContentChunk,
  Dependency,
  GitInfo,
  ContextError,
} from '../types';

const readFile = promisify(fs.readFile);
const readdir = promisify(fs.readdir);
const stat = promisify(fs.stat);

export interface ContextManagerOptions {
  rootPath: string;
  maxFileSize?: number;
  excludePatterns?: string[];
  includePatterns?: string[];
}

export class ContextManager {
  private rootPath: string;
  private maxFileSize: number;
  private excludePatterns: RegExp[];
  private includePatterns: RegExp[];
  private repositoryContext?: RepositoryContext;
  private indexedFiles: Map<string, IndexedContent> = new Map();

  constructor(options: ContextManagerOptions) {
    this.rootPath = options.rootPath;
    this.maxFileSize = options.maxFileSize || 1024 * 1024; // 1MB default
    this.excludePatterns = (options.excludePatterns || this.getDefaultExcludes()).map(
      (pattern) => this.globToRegex(pattern)
    );
    this.includePatterns = (options.includePatterns || ['.*']).map(
      (pattern) => this.globToRegex(pattern)
    );
  }

  private globToRegex(pattern: string): RegExp {
    // If pattern is already a regex pattern, use it as is
    if (pattern.startsWith('^') || pattern.includes('\\')) {
      return new RegExp(pattern);
    }
    
    // Convert glob pattern to regex
    // Escape special regex characters except * and ?
    let regexPattern = pattern
      .replace(/[.+^${}()|[\]\\]/g, '\\$&')  // Escape special chars
      .replace(/\*/g, '.*')  // * becomes .*
      .replace(/\?/g, '.');  // ? becomes .
    
    // Make it match the whole path component
    return new RegExp(regexPattern);
  }

  private getDefaultExcludes(): string[] {
    return [
      'node_modules',
      '.git',
      'dist',
      'build',
      'out',
      'coverage',
      '__pycache__',
      '.pytest_cache',
      '.venv',
      'venv',
      '.env',
      '.DS_Store',
      '*.pyc',
      '*.pyo',
      '*.pyd',
      '*.so',
      '*.dll',
      '*.exe',
      '*.bin',
      '*.log',
      '*.lock',
    ];
  }

  async analyzeRepository(): Promise<RepositoryContext> {
    try {
      const files = await this.scanDirectory(this.rootPath);
      const dependencies = await this.extractDependencies();
      const gitInfo = await this.getGitInfo();

      this.repositoryContext = {
        rootPath: this.rootPath,
        files,
        dependencies,
        gitInfo,
        indexedContent: [],
      };

      return this.repositoryContext;
    } catch (error) {
      throw new ContextError(`Failed to analyze repository: ${error}`, {
        rootPath: this.rootPath,
      });
    }
  }

  private async scanDirectory(dirPath: string, basePath = ''): Promise<FileInfo[]> {
    const files: FileInfo[] = [];

    try {
      const entries = await readdir(dirPath);

      for (const entry of entries) {
        const fullPath = path.join(dirPath, entry);
        const relativePath = path.join(basePath, entry);

        // Check exclusions
        if (this.shouldExclude(relativePath)) {
          continue;
        }

        const stats = await stat(fullPath);

        if (stats.isDirectory()) {
          const subFiles = await this.scanDirectory(fullPath, relativePath);
          files.push(...subFiles);
        } else if (stats.isFile() && stats.size <= this.maxFileSize) {
          if (this.shouldInclude(relativePath)) {
            files.push({
              path: fullPath,
              relativePath,
              language: this.detectLanguage(entry),
              size: stats.size,
              lastModified: stats.mtimeMs,
            });
          }
        }
      }
    } catch (error) {
      console.warn(`Error scanning directory ${dirPath}:`, error);
    }

    return files;
  }

  private shouldExclude(relativePath: string): boolean {
    return this.excludePatterns.some((pattern) => pattern.test(relativePath));
  }

  private shouldInclude(relativePath: string): boolean {
    return this.includePatterns.some((pattern) => pattern.test(relativePath));
  }

  private detectLanguage(fileName: string): string {
    const ext = path.extname(fileName).toLowerCase();
    const languageMap: Record<string, string> = {
      '.js': 'javascript',
      '.jsx': 'javascriptreact',
      '.ts': 'typescript',
      '.tsx': 'typescriptreact',
      '.py': 'python',
      '.java': 'java',
      '.c': 'c',
      '.cpp': 'cpp',
      '.cs': 'csharp',
      '.go': 'go',
      '.rs': 'rust',
      '.rb': 'ruby',
      '.php': 'php',
      '.swift': 'swift',
      '.kt': 'kotlin',
      '.scala': 'scala',
      '.r': 'r',
      '.m': 'objective-c',
      '.sh': 'shellscript',
      '.ps1': 'powershell',
      '.sql': 'sql',
      '.html': 'html',
      '.css': 'css',
      '.scss': 'scss',
      '.json': 'json',
      '.xml': 'xml',
      '.yaml': 'yaml',
      '.yml': 'yaml',
      '.md': 'markdown',
      '.txt': 'plaintext',
    };

    return languageMap[ext] || 'plaintext';
  }

  private async extractDependencies(): Promise<Dependency[]> {
    const dependencies: Dependency[] = [];

    // Node.js dependencies
    const packageJsonPath = path.join(this.rootPath, 'package.json');
    if (fs.existsSync(packageJsonPath)) {
      try {
        const content = await readFile(packageJsonPath, 'utf-8');
        const packageJson = JSON.parse(content);
        const deps = {
          ...packageJson.dependencies,
          ...packageJson.devDependencies,
        };

        for (const [name, version] of Object.entries(deps)) {
          dependencies.push({
            name,
            version: version as string,
            type: 'npm',
          });
        }
      } catch (error) {
        console.warn('Error reading package.json:', error);
      }
    }

    // Python dependencies
    const requirementsPath = path.join(this.rootPath, 'requirements.txt');
    if (fs.existsSync(requirementsPath)) {
      try {
        const content = await readFile(requirementsPath, 'utf-8');
        const lines = content.split('\n');

        for (const line of lines) {
          const trimmed = line.trim();
          if (trimmed && !trimmed.startsWith('#')) {
            const match = trimmed.match(/^([a-zA-Z0-9-_]+)([><=!]+.*)?$/);
            if (match) {
              dependencies.push({
                name: match[1],
                version: match[2] || '*',
                type: 'pip',
              });
            }
          }
        }
      } catch (error) {
        console.warn('Error reading requirements.txt:', error);
      }
    }

    return dependencies;
  }

  private async getGitInfo(): Promise<GitInfo | undefined> {
    const gitPath = path.join(this.rootPath, '.git');
    if (!fs.existsSync(gitPath)) {
      return undefined;
    }

    try {
      // This is a simplified version - in production, use a git library
      const headPath = path.join(gitPath, 'HEAD');
      const head = await readFile(headPath, 'utf-8');
      const branch = head.trim().replace('ref: refs/heads/', '');

      return {
        branch,
        commit: '',
        status: [],
      };
    } catch (error) {
      return undefined;
    }
  }

  async indexFile(filePath: string): Promise<IndexedContent> {
    try {
      const content = await readFile(filePath, 'utf-8');
      const chunks = this.chunkContent(content);

      const indexed: IndexedContent = {
        filePath,
        content,
        chunks,
      };

      this.indexedFiles.set(filePath, indexed);
      return indexed;
    } catch (error) {
      throw new ContextError(`Failed to index file: ${filePath}`, { error });
    }
  }

  private chunkContent(content: string, chunkSize = 500): ContentChunk[] {
    const lines = content.split('\n');
    const chunks: ContentChunk[] = [];
    let currentChunk: string[] = [];
    let startLine = 0;

    for (let i = 0; i < lines.length; i++) {
      currentChunk.push(lines[i]);

      if (currentChunk.length >= chunkSize || i === lines.length - 1) {
        chunks.push({
          content: currentChunk.join('\n'),
          startLine,
          endLine: i,
        });

        currentChunk = [];
        startLine = i + 1;
      }
    }

    return chunks;
  }

  async getCodeContext(
    filePath: string,
    lineStart: number,
    lineEnd: number
  ): Promise<CodeContext> {
    try {
      const content = await readFile(filePath, 'utf-8');
      const lines = content.split('\n');
      const selectedCode = lines.slice(lineStart - 1, lineEnd).join('\n');

      // Get surrounding context (10 lines before and after)
      const contextStart = Math.max(0, lineStart - 11);
      const contextEnd = Math.min(lines.length, lineEnd + 10);
      const surroundingCode = lines.slice(contextStart, contextEnd).join('\n');

      return {
        language: this.detectLanguage(filePath),
        fileName: path.basename(filePath),
        filePath,
        lineStart,
        lineEnd,
        selectedCode,
        surroundingCode,
      };
    } catch (error) {
      throw new ContextError(`Failed to get code context: ${filePath}`, { error });
    }
  }

  getRepositoryContext(): RepositoryContext | undefined {
    return this.repositoryContext;
  }

  getIndexedContent(filePath: string): IndexedContent | undefined {
    return this.indexedFiles.get(filePath);
  }

  clearIndex(): void {
    this.indexedFiles.clear();
  }
}
