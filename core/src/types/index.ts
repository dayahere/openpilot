import { z } from 'zod';

// AI Provider types
export enum AIProvider {
  OLLAMA = 'ollama',
  OPENAI = 'openai',
  GROK = 'grok',
  TOGETHER = 'together',
  HUGGINGFACE = 'huggingface',
  CUSTOM = 'custom',
}

// Configuration schemas
export const AIConfigSchema = z.object({
  provider: z.nativeEnum(AIProvider),
  model: z.string(),
  apiKey: z.string().optional(),
  apiUrl: z.string().optional(),
  temperature: z.number().min(0).max(2).default(0.7),
  maxTokens: z.number().default(2048),
  topP: z.number().min(0).max(1).default(0.9),
  frequencyPenalty: z.number().min(-2).max(2).default(0),
  presencePenalty: z.number().min(-2).max(2).default(0),
  offline: z.boolean().default(false),
});

export type AIConfig = z.infer<typeof AIConfigSchema>;

// Message types
export interface Message {
  id: string;
  role: 'system' | 'user' | 'assistant';
  content: string;
  timestamp: number;
  metadata?: Record<string, unknown>;
}

export interface ChatContext {
  messages: Message[];
  codeContext?: CodeContext;
  repositoryContext?: RepositoryContext;
}

// Code context types
export interface CodeContext {
  language: string;
  fileName: string;
  filePath: string;
  lineStart: number;
  lineEnd: number;
  selectedCode: string;
  surroundingCode?: string;
  imports?: string[];
  symbols?: SymbolInfo[];
}

export interface SymbolInfo {
  name: string;
  kind: SymbolKind;
  location: Location;
  containerName?: string;
}

export enum SymbolKind {
  File = 0,
  Module = 1,
  Namespace = 2,
  Package = 3,
  Class = 4,
  Method = 5,
  Property = 6,
  Field = 7,
  Constructor = 8,
  Enum = 9,
  Interface = 10,
  Function = 11,
  Variable = 12,
  Constant = 13,
}

export interface Location {
  uri: string;
  range: Range;
}

export interface Range {
  start: Position;
  end: Position;
}

export interface Position {
  line: number;
  character: number;
}

// Repository context types
export interface RepositoryContext {
  rootPath: string;
  files: FileInfo[];
  dependencies: Dependency[];
  gitInfo?: GitInfo;
  indexedContent?: IndexedContent[];
}

export interface FileInfo {
  path: string;
  relativePath: string;
  language: string;
  size: number;
  lastModified: number;
}

export interface Dependency {
  name: string;
  version: string;
  type: 'npm' | 'pip' | 'maven' | 'cargo' | 'other';
}

export interface GitInfo {
  branch: string;
  commit: string;
  remote?: string;
  status: string[];
}

export interface IndexedContent {
  filePath: string;
  content: string;
  embedding?: number[];
  chunks?: ContentChunk[];
}

export interface ContentChunk {
  content: string;
  startLine: number;
  endLine: number;
  embedding?: number[];
}

// AI Response types
export interface AIResponse {
  id: string;
  content: string;
  role: 'assistant';
  timestamp: number;
  model: string;
  usage?: TokenUsage;
  metadata?: Record<string, unknown>;
}

export interface TokenUsage {
  promptTokens: number;
  completionTokens: number;
  totalTokens: number;
}

// Completion types
export interface CompletionRequest {
  prompt: string;
  context: CodeContext;
  config: AIConfig;
}

export interface CompletionResponse {
  completions: Completion[];
  metadata?: Record<string, unknown>;
}

export interface Completion {
  text: string;
  confidence: number;
  offset: number;
}

// Session types
export interface Session {
  id: string;
  messages: Message[];
  createdAt: number;
  updatedAt: number;
  metadata?: Record<string, unknown>;
}

// Checkpoint types
export interface Checkpoint {
  id: string;
  sessionId: string;
  timestamp: number;
  state: CheckpointState;
  description?: string;
}

export interface CheckpointState {
  messages: Message[];
  codeChanges: CodeChange[];
  repositoryState?: RepositoryState;
}

export interface CodeChange {
  filePath: string;
  before: string;
  after: string;
  timestamp: number;
}

export interface RepositoryState {
  commit?: string;
  branch?: string;
  modifiedFiles: string[];
}

// Error types
export class OpenPilotError extends Error {
  constructor(
    message: string,
    public code: string,
    public details?: Record<string, unknown>
  ) {
    super(message);
    this.name = 'OpenPilotError';
  }
}

export class AIProviderError extends OpenPilotError {
  constructor(message: string, details?: Record<string, unknown>) {
    super(message, 'AI_PROVIDER_ERROR', details);
    this.name = 'AIProviderError';
  }
}

export class ContextError extends OpenPilotError {
  constructor(message: string, details?: Record<string, unknown>) {
    super(message, 'CONTEXT_ERROR', details);
    this.name = 'ContextError';
  }
}

// Event types
export interface AIEvent {
  type: AIEventType;
  data: unknown;
  timestamp: number;
}

export enum AIEventType {
  COMPLETION_START = 'completion_start',
  COMPLETION_CHUNK = 'completion_chunk',
  COMPLETION_END = 'completion_end',
  COMPLETION_ERROR = 'completion_error',
  CONTEXT_UPDATE = 'context_update',
  SESSION_START = 'session_start',
  SESSION_END = 'session_end',
}
