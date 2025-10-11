# OpenPilot Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        OpenPilot Ecosystem                       │
└─────────────────────────────────────────────────────────────────┘

┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  VS Code     │  │   Desktop    │  │     Web      │  │   Mobile     │
│  Extension   │  │     App      │  │     App      │  │     App      │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │                 │
       └─────────────────┴─────────────────┴─────────────────┘
                               │
                         ┌─────▼─────┐
                         │   Core    │
                         │  Library  │
                         └─────┬─────┘
                               │
       ┌───────────────────────┼───────────────────────┐
       │                       │                       │
   ┌───▼────┐           ┌─────▼──────┐         ┌─────▼─────┐
   │   AI   │           │  Context   │         │  Session  │
   │ Engine │           │  Manager   │         │  Manager  │
   └───┬────┘           └────────────┘         └───────────┘
       │
       ├─────────────┬─────────────┬─────────────┐
       │             │             │             │
   ┌───▼───┐    ┌───▼───┐    ┌───▼───┐    ┌───▼────┐
   │Ollama │    │OpenAI │    │ Grok  │    │Together│
   │(Local)│    │ (API) │    │ (API) │    │  (API) │
   └───────┘    └───────┘    └───────┘    └────────┘
```

## Component Architecture

### 1. Core Library (`@openpilot/core`)

```
core/
├── ai-engine/
│   ├── BaseAIProvider (abstract)
│   ├── OllamaProvider
│   ├── OpenAIProvider
│   ├── GrokProvider
│   ├── TogetherProvider
│   └── AIEngine (orchestrator)
│
├── context-manager/
│   ├── ContextManager
│   ├── FileScanner
│   ├── DependencyExtractor
│   └── CodeIndexer
│
├── types/
│   ├── AIConfig
│   ├── Message
│   ├── CodeContext
│   ├── RepositoryContext
│   └── Session
│
└── utils/
    ├── Logger
    ├── Retry helpers
    └── Common utilities
```

**Responsibilities:**
- AI provider abstraction and management
- Code context extraction
- Repository analysis and indexing
- Session and state management
- Type definitions

**Key Interfaces:**
```typescript
interface AIEngine {
  chat(context: ChatContext): Promise<AIResponse>
  complete(request: CompletionRequest): Promise<CompletionResponse>
  streamChat(context: ChatContext, onChunk: Function): Promise<AIResponse>
}

interface ContextManager {
  analyzeRepository(): Promise<RepositoryContext>
  getCodeContext(file: string, lines: Range): Promise<CodeContext>
  indexFile(path: string): Promise<IndexedContent>
}
```

### 2. VS Code Extension

```
vscode-extension/
├── extension.ts (entry point)
├── views/
│   ├── ChatViewProvider (webview)
│   ├── HistoryViewProvider
│   └── CheckpointsViewProvider
│
├── providers/
│   └── CompletionProvider
│
└── utils/
    ├── ConfigurationManager
    ├── SessionManager
    └── CheckpointManager
```

**Architecture:**

```
┌─────────────────────────────────────┐
│        VS Code Extension            │
│                                     │
│  ┌────────────┐   ┌──────────────┐ │
│  │ Chat View  │   │  Completion  │ │
│  │ (Webview)  │   │   Provider   │ │
│  └─────┬──────┘   └──────┬───────┘ │
│        │                 │         │
│  ┌─────▼─────────────────▼──────┐  │
│  │    Extension Host            │  │
│  │  - Command handlers          │  │
│  │  - Configuration manager     │  │
│  │  - Session manager           │  │
│  └──────────────┬───────────────┘  │
│                 │                  │
└─────────────────┼──────────────────┘
                  │
            ┌─────▼─────┐
            │   Core    │
            │  Library  │
            └───────────┘
```

**Communication Flow:**
```
User Action → Command → Extension Host → Core Library → AI Provider
                          ↓
                    Update UI ← Response ← Streaming
```

### 3. Desktop Application

```
desktop/
├── public/
│   └── electron.js (main process)
│
└── src/
    ├── App.tsx
    ├── components/
    │   ├── ChatInterface
    │   ├── Settings
    │   └── Sidebar
    └── index.tsx (renderer)
```

**Process Architecture:**

```
┌──────────────────────────────────────┐
│      Main Process (Electron)         │
│  - Window management                 │
│  - IPC handlers                      │
│  - Native API access                 │
└────────────┬─────────────────────────┘
             │ IPC
┌────────────▼─────────────────────────┐
│    Renderer Process (React)          │
│  ┌────────────┐   ┌────────────┐    │
│  │   Chat     │   │  Settings  │    │
│  └─────┬──────┘   └─────┬──────┘    │
│        │                │            │
│  ┌─────▼────────────────▼──────┐    │
│  │      React State            │    │
│  └────────────┬─────────────────┘    │
└───────────────┼──────────────────────┘
                │
          ┌─────▼─────┐
          │   Core    │
          │  Library  │
          └───────────┘
```

### 4. Web Application (Planned)

```
web/
├── src/
│   ├── App.tsx
│   ├── components/
│   ├── pages/
│   ├── hooks/
│   └── services/
│
├── public/
│   ├── manifest.json (PWA)
│   └── service-worker.js
│
└── package.json
```

**PWA Architecture:**
```
┌──────────────────────────────────┐
│         Browser                  │
│  ┌────────────────────────────┐  │
│  │    React Application       │  │
│  │  - Routing                 │  │
│  │  - State management        │  │
│  │  - UI components           │  │
│  └──────────┬─────────────────┘  │
│             │                    │
│  ┌──────────▼─────────────────┐  │
│  │    Service Worker          │  │
│  │  - Offline caching         │  │
│  │  - Background sync         │  │
│  └────────────────────────────┘  │
└──────────────────────────────────┘
```

### 5. Mobile Application (Planned)

```
mobile/
├── src/
│   ├── screens/
│   ├── components/
│   ├── navigation/
│   └── services/
│
├── ios/
└── android/
```

**React Native Architecture:**
```
┌──────────────────────────────────┐
│    React Native Application      │
│  ┌────────────────────────────┐  │
│  │   JavaScript Layer         │  │
│  │  - React components        │  │
│  │  - Business logic          │  │
│  └──────────┬─────────────────┘  │
│             │                    │
│  ┌──────────▼─────────────────┐  │
│  │    Native Bridge           │  │
│  └──────────┬─────────────────┘  │
│             │                    │
│  ┌──────────▼─────────────────┐  │
│  │   Native Modules           │  │
│  │  - iOS (Swift/Obj-C)       │  │
│  │  - Android (Java/Kotlin)   │  │
│  └────────────────────────────┘  │
└──────────────────────────────────┘
```

## Data Flow

### Chat Request Flow

```
1. User Input
   │
   ▼
2. UI Component
   │
   ▼
3. Session Manager (save message)
   │
   ▼
4. Context Manager (gather context)
   │
   ▼
5. AI Engine (prepare request)
   │
   ▼
6. AI Provider (call API)
   │
   ▼
7. Stream Response
   │
   ├──► Update UI (chunks)
   │
   ▼
8. Save Response (session)
   │
   ▼
9. Complete
```

### Code Completion Flow

```
1. User Types
   │
   ▼
2. Debounce (300ms)
   │
   ▼
3. Extract Context
   │  - Current file
   │  - Surrounding code
   │  - Imports
   │
   ▼
4. AI Engine (completion request)
   │
   ▼
5. AI Provider (generate)
   │
   ▼
6. Parse Response
   │
   ▼
7. Display Inline Suggestion
```

### Repository Analysis Flow

```
1. Open Workspace
   │
   ▼
2. Scan Directory
   │  - Filter files
   │  - Ignore patterns
   │
   ▼
3. Extract Metadata
   │  - File types
   │  - Dependencies
   │  - Git info
   │
   ▼
4. Index Files
   │  - Chunk content
   │  - Extract symbols
   │
   ▼
5. Store Index
   │
   ▼
6. Ready for Queries
```

## State Management

### Session State

```
Session {
  id: string
  messages: Message[]
  createdAt: timestamp
  updatedAt: timestamp
  metadata: {
    repository: string
    files: string[]
  }
}
```

**Storage:**
- VS Code: ExtensionContext.globalState
- Desktop: electron-store
- Web: localStorage / IndexedDB
- Mobile: AsyncStorage

### Configuration State

```
AIConfig {
  provider: AIProvider
  model: string
  apiKey?: string
  apiUrl?: string
  temperature: number
  maxTokens: number
  offline: boolean
}
```

**Storage:**
- VS Code: Workspace configuration
- Desktop: electron-store
- Web: localStorage
- Mobile: AsyncStorage

### Checkpoint State

```
Checkpoint {
  id: string
  sessionId: string
  timestamp: number
  state: {
    messages: Message[]
    codeChanges: CodeChange[]
    repositoryState: RepositoryState
  }
}
```

## Security Architecture

### API Key Storage

```
┌──────────────────────────────────┐
│   User Input (API Key)           │
└────────────┬─────────────────────┘
             │
             ▼
┌──────────────────────────────────┐
│   Secure Storage                 │
│  - VS Code: SecretStorage API    │
│  - Desktop: keytar/safeStorage   │
│  - Web: Not stored (session only)│
│  - Mobile: Keychain/KeyStore     │
└────────────┬─────────────────────┘
             │
             ▼
┌──────────────────────────────────┐
│   Encrypted at Rest              │
└──────────────────────────────────┘
```

### Privacy Modes

1. **Local Only** (Default)
   - All processing on device
   - No data sent to cloud
   - Uses Ollama or local models

2. **Cloud with Privacy**
   - Minimal data sent
   - No telemetry
   - User-controlled

3. **Team Mode** (Future)
   - End-to-end encryption
   - Self-hosted option
   - Audit logs

## Performance Optimization

### Caching Strategy

```
┌──────────────────────────────────┐
│        Request                   │
└────────────┬─────────────────────┘
             │
             ▼
      ┌─────────────┐
      │ Cache Check │
      └──┬──────┬───┘
         │      │
    Hit  │      │  Miss
         │      │
         ▼      ▼
    ┌────────┐ ┌─────────┐
    │ Return │ │ Fetch   │
    │ Cache  │ │ & Cache │
    └────────┘ └─────────┘
```

**Cache Layers:**
1. In-memory (session)
2. Persistent (disk)
3. Indexed (searchable)

### Code Indexing

```
File → Chunk (500 lines) → Embeddings → Vector DB
  │                           │
  └───────────────────────────┴─────► Fast Search
```

## Extensibility

### Plugin Architecture (Future)

```
┌──────────────────────────────────┐
│      Core API                    │
└────────────┬─────────────────────┘
             │
     ┌───────┼───────┐
     │       │       │
     ▼       ▼       ▼
┌─────────┐ ┌─────────┐ ┌─────────┐
│ Linter  │ │ Format  │ │ Custom  │
│ Plugin  │ │ Plugin  │ │ Plugin  │
└─────────┘ └─────────┘ └─────────┘
```

**Plugin Interface:**
```typescript
interface OpenPilotPlugin {
  name: string
  version: string
  activate(context: PluginContext): void
  deactivate(): void
}
```

## Deployment Architecture

### VS Code Extension

```
Source Code → Compile (tsc) → Package (vsce) → .vsix → Marketplace
```

### Desktop App

```
Source Code → Build (webpack) → Package (electron-builder) → 
  ├─► Windows (.exe, .msi)
  ├─► macOS (.dmg, .app)
  └─► Linux (.AppImage, .deb)
```

### Web App

```
Source Code → Build (webpack) → Optimize → Deploy →
  ├─► Static hosting (Netlify, Vercel)
  ├─► CDN (CloudFlare)
  └─► Self-hosted (nginx)
```

### Mobile App

```
Source Code → Build → Package →
  ├─► iOS (.ipa) → App Store
  └─► Android (.apk, .aab) → Play Store
```

## Technology Stack Summary

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Language | TypeScript | Type safety, better DX |
| UI Framework | React | Component-based UI |
| Desktop | Electron | Cross-platform desktop |
| Mobile | React Native | Cross-platform mobile |
| Testing | Jest | Unit and integration tests |
| Linting | ESLint | Code quality |
| Formatting | Prettier | Code style |
| Build | TypeScript, Webpack | Compilation and bundling |
| Package Manager | npm | Dependency management |
| Version Control | Git | Source control |
| AI | Ollama, OpenAI, etc. | AI inference |
| Storage | Various | Platform-specific |

---

This architecture is designed to be:
- **Modular**: Easy to extend and maintain
- **Scalable**: Handles growth in users and features
- **Flexible**: Multiple deployment options
- **Secure**: Privacy-first design
- **Performant**: Optimized data flow
- **Testable**: Clear component boundaries
