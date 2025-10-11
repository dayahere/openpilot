# OpenPilot Testing System - Complete Guide

## 🎯 Overview

Comprehensive test infrastructure for OpenPilot with Docker support, 100% coverage goals, and automatic issue resolution.

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Testing Modes](#testing-modes)
- [Test Structure](#test-structure)
- [Auto-Fix Loop](#auto-fix-loop)
- [Docker Commands](#docker-commands)
- [Coverage Requirements](#coverage-requirements)
- [Troubleshooting](#troubleshooting)

## 🚀 Quick Start

### Local Testing (requires Node.js/npm)

```bash
cd tests
npm install
npm test
```

### Docker Testing (no local dependencies required)

```bash
# Build the test environment
docker-compose -f docker-compose.test.yml build test-runner

# Run all tests
docker-compose -f docker-compose.test.yml run --rm test-runner

# Run with coverage
docker-compose -f docker-compose.test.yml run --rm test-coverage

# Run auto-fix loop
docker-compose -f docker-compose.test.yml run --rm test-autofix
```

## 🧪 Testing Modes

### 1. Unit Tests Only
```bash
npm test -- --testPathPattern=unit
```

### 2. Integration Tests Only
```bash
npm test -- --testPathPattern=integration
```

### 3. E2E Tests Only
```bash
npm test -- --testPathPattern=e2e
```

### 4. All Tests with Coverage
```bash
npm test -- --coverage
```

### 5. Watch Mode (Development)
```bash
npm test -- --watch
```

## 📁 Test Structure

```
tests/
├── integration/              # Integration tests
│   ├── ai-engine.integration.test.ts
│   ├── context-manager.integration.test.ts
│   └── full-app-generation.test.ts
├── e2e/                      # End-to-end tests
│   └── full-workflow.e2e.test.ts
├── helpers/                  # Test utilities
│   └── test-helpers.ts       # Factory functions for proper types
├── jest.config.js            # Jest configuration
├── tsconfig.json             # TypeScript config
└── autofix.py                # Automatic issue resolution

Test Files: 7 files
Test Cases: 150+ tests
Coverage Target: >= 90%
```

## 🔧 Test Helpers

The `helpers/test-helpers.ts` file provides factory functions for creating properly typed test data:

### Available Helpers

```typescript
import {
  createMessage,           // Creates Message with id, role, content, timestamp
  createChatContext,       // Creates ChatContext with proper Message types
  createCompletionRequest, // Creates CompletionRequest with CodeContext
  createCodeContext,       // Creates CodeContext for code analysis
  createTestAIConfig,      // Creates AI configuration
  createMockOllamaResponse,// Creates axios mock response
  createMockCompletionResponse, // Creates CompletionResponse
  createMockAIResponse,    // Creates AIResponse
  waitFor,                 // Async condition waiter
  createMockRepository,    // Creates mock repository structure
} from '../helpers/test-helpers';
```

### Example Usage

```typescript
import { createMessage, createChatContext } from '../helpers/test-helpers';

// Create a single message
const message = createMessage('user', 'Hello AI!');
// { id: uuid(), role: 'user', content: 'Hello AI!', timestamp: Date.now() }

// Create a chat context
const context = createChatContext([
  { role: 'user', content: 'First message' },
  { role: 'assistant', content: 'Response' },
]);
```

## 🤖 Auto-Fix Loop

The auto-fix script automatically resolves test issues through iterative improvements:

### Features
- ✅ Runs TypeScript type checking
- ✅ Executes all tests
- ✅ Validates code coverage >= 90%
- ✅ Identifies and logs fixable issues
- ✅ Max 10 iterations
- ✅ Comprehensive reporting

### Running Auto-Fix

**Local:**
```bash
cd tests
python3 autofix.py
```

**Docker:**
```bash
docker-compose -f docker-compose.test.yml run --rm test-autofix
```

### Auto-Fix Process

```
Iteration 1
├── TypeScript Check → Fix type errors
├── Run Tests → Fix failing tests
└── Coverage Check → Add missing test cases

Iteration 2
├── TypeScript Check → Verify fixes
├── Run Tests → All pass
└── Coverage Check → >= 90%

✅ SUCCESS: All requirements met!
```

## 🐳 Docker Commands

### Build Images

```bash
# Build all test services
docker-compose -f docker-compose.test.yml build

# Build specific service
docker-compose -f docker-compose.test.yml build test-runner
docker-compose -f docker-compose.test.yml build test-coverage
docker-compose -f docker-compose.test.yml build test-autofix
```

### Run Tests

```bash
# Standard test run
docker-compose -f docker-compose.test.yml run --rm test-runner

# With coverage report
docker-compose -f docker-compose.test.yml run --rm test-coverage

# Integration tests only
docker-compose -f docker-compose.test.yml run --rm test-integration

# E2E tests only
docker-compose -f docker-compose.test.yml run --rm test-e2e

# Auto-fix until all pass
docker-compose -f docker-compose.test.yml run --rm test-autofix
```

### Interactive Shell

```bash
# Enter container shell for debugging
docker-compose -f docker-compose.test.yml run --rm test-runner sh

# Inside container:
npm test
npm test -- --watch
npm test -- --coverage
```

## 📊 Coverage Requirements

### Thresholds (jest.config.js)

```javascript
coverageThreshold: {
  global: {
    branches: 90,
    functions: 90,
    lines: 90,
    statements: 90
  }
}
```

### Viewing Coverage Reports

**After running tests with coverage:**

```bash
# Local
open tests/coverage/lcov-report/index.html

# Docker - copy report to host
docker-compose -f docker-compose.test.yml run --rm test-coverage
docker cp <container-id>:/app/tests/coverage ./test-coverage
```

## 🔍 Troubleshooting

### TypeScript Errors

**Problem:** `Cannot find module '@openpilot/core'`

**Solution:**
```bash
# Rebuild core library
cd core
npm install
npm run build

# Ensure path mapping in tests/tsconfig.json:
"paths": {
  "@openpilot/core": ["../core/src"]
}
```

### Test Failures

**Problem:** `Property 'content' does not exist on type 'CompletionResponse'`

**Solution:** Use correct response types
- `chat()` returns `AIResponse` with `content` property
- `complete()` returns `CompletionResponse` with `completions` array

```typescript
// Correct usage
const response = await engine.chat(context);
expect(response.content).toContain('expected');

const completion = await engine.complete(request);
expect(completion.completions[0].text).toContain('expected');
```

### Mock Errors

**Problem:** `axios.post is not a function`

**Solution:** Properly mock axios

```typescript
import axios from 'axios';
jest.mock('axios');
const mockedAxios = axios as jest.Mocked<typeof axios>;

// In test:
mockedAxios.post.mockResolvedValueOnce({
  data: { response: 'mock response' }
});
```

### Docker Build Issues

**Problem:** Docker build fails

**Solutions:**
```bash
# Clean rebuild
docker-compose -f docker-compose.test.yml build --no-cache test-runner

# Check Docker daemon
docker info

# View detailed logs
docker-compose -f docker-compose.test.yml build test-runner --progress=plain
```

### Coverage Not Met

**Problem:** Coverage below 90%

**Solutions:**
1. Add missing test cases for uncovered code
2. Test edge cases and error paths
3. Check coverage report for specific gaps:
   ```bash
   npm test -- --coverage
   open coverage/lcov-report/index.html
   ```

## 📝 Test Writing Guidelines

### 1. Always Use Test Helpers

```typescript
// ❌ Bad - Missing id and timestamp
const context = {
  messages: [{ role: 'user', content: 'test' }]
};

// ✅ Good - Properly typed
const context = createChatContext([
  { role: 'user', content: 'test' }
]);
```

### 2. Use Proper Types

```typescript
// ❌ Bad - String instead of enum
const config = { provider: 'ollama' };

// ✅ Good - Enum value
const config = createTestAIConfig(AIProvider.OLLAMA, 'codellama');
```

### 3. Mock External Calls

```typescript
// Always mock axios, fs, etc.
jest.mock('axios');
const mockedAxios = axios as jest.Mocked<typeof axios>;

beforeEach(() => {
  mockedAxios.post.mockResolvedValueOnce({ data: mockResponse });
});

afterEach(() => {
  jest.clearAllMocks();
});
```

### 4. Test Async Code Properly

```typescript
// Use async/await
it('should complete async operation', async () => {
  const result = await asyncFunction();
  expect(result).toBeDefined();
}, 30000); // Set appropriate timeout
```

## 🎯 Success Criteria

A successful test run requires:

- ✅ All TypeScript files compile with zero errors
- ✅ All Jest tests pass (0 failures)
- ✅ Code coverage >= 90% (lines, statements, functions, branches)
- ✅ No lint errors
- ✅ All mocks properly configured
- ✅ Proper type usage throughout

## 📚 Related Documentation

- [Docker Testing Guide](./DOCKER_TESTING_GUIDE.md)
- [Test Writing Best Practices](./TEST_WRITING_GUIDE.md)
- [Coverage Analysis Guide](./COVERAGE_GUIDE.md)
- [Type System Guide](./TYPE_SYSTEM_GUIDE.md)

## 🆘 Getting Help

If tests are failing after following this guide:

1. Check Docker build logs: `docker-compose -f docker-compose.test.yml build --progress=plain`
2. Run TypeScript check: `cd tests && npx tsc --noEmit`
3. Run auto-fix loop: `docker-compose -f docker-compose.test.yml run --rm test-autofix`
4. Review test-helpers.ts for available utilities
5. Check type definitions in core/src/types/index.ts

## 📈 Continuous Improvement

The auto-fix loop continuously improves test quality:

```
Run 1: Fix type errors
Run 2: Fix failing tests
Run 3: Improve mocks
Run 4: Add coverage
...
Run N: 100% success ✅
```

---

**Last Updated:** 2025-01-11  
**Version:** 1.0.0  
**Status:** Production Ready
