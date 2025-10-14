# Testing Guide - OpenPilot

## Quick Start

### Run All Tests
```powershell
# VSCode Extension Tests
cd vscode-extension
npm test

# Core Tests  
cd core
npm test

# Both with coverage
npm run test:coverage  # If script exists
```

### Run Specific Test Suites

#### VSCode Extension
```powershell
cd vscode-extension

# Run specific test file
npm test -- chatView.unit.test.ts

# Run with coverage
npm test -- --coverage

# Run in watch mode
npm test -- --watch

# Run with verbose output
npm test -- --verbose
```

#### Core
```powershell
cd core

# Run specific test file
npm test -- types.test.ts

# Run all with coverage
npm test -- --coverage

# Run and update snapshots
npm test -- -u
```

## Test Structure

### VSCode Extension (`vscode-extension/src/__tests__/`)
```
__tests__/
├── chatView.unit.test.ts       # ChatViewProvider unit tests
├── extension.test.ts           # Extension activation tests
├── integration/                # Integration tests (pending)
└── e2e/                       # E2E tests (require VS Code)
```

### Core (`core/src/__tests__/`)
```
__tests__/
├── types.test.ts              # Type definitions and schema
├── ai-engine.test.ts          # AIEngine class tests
├── utils.test.ts              # Utility functions
└── providers.test.ts          # Provider implementations
```

## Coverage Requirements

All tests must meet **95% coverage** threshold:
- Branches: 95%
- Functions: 95%
- Lines: 95%
- Statements: 95%

### Check Coverage
```powershell
# VSCode Extension
cd vscode-extension
npm test -- --coverage --coverageReporters=text --coverageReporters=html

# Open HTML report
start coverage/index.html

# Core
cd core
npm test -- --coverage
```

## Writing Tests

### VSCode Extension Tests

#### Mock AIEngine
```typescript
class MockAIEngine {
  public updateConfig = jest.fn();
  public async streamChat(_ctx: any, onChunk: (c: string) => void) {
    onChunk('Hello');
    onChunk(' World');
    return {
      id: 'resp-1',
      content: 'Hello World',
      role: 'assistant' as const,
      timestamp: Date.now(),
      model: 'test',
    };
  }
}
```

#### Test Configuration Updates
```typescript
it('updateConfig triggers engine.updateConfig', async () => {
  await messageCallback({
    type: 'updateConfig',
    payload: {
      provider: 'openai',
      model: 'gpt-4',
      temperature: 0.8,
    },
  });

  expect(mockEngine.updateConfig).toHaveBeenCalledWith(
    expect.objectContaining({
      provider: 'openai',
      model: 'gpt-4',
    })
  );
});
```

### Core Tests

#### Type Validation
```typescript
import { AIProvider, AIConfigSchema } from '../types';

it('accepts GEMINI provider', () => {
  const config = {
    provider: AIProvider.GEMINI,
    model: 'gemini-1.5-pro',
    temperature: 0.7,
    maxTokens: 2048,
  };
  const result = AIConfigSchema.safeParse(config);
  expect(result.success).toBe(true);
});
```

#### Mocking axios for Providers
```typescript
import axios from 'axios';
jest.mock('axios');
const mockedAxios = axios as jest.Mocked<typeof axios>;

beforeEach(() => {
  mockedAxios.create.mockReturnValue(mockedAxios as any);
  mockedAxios.post.mockResolvedValue({
    data: { message: { content: 'response' } },
  });
});
```

## Debugging Tests

### VS Code Debugger
Create `.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Jest Current File",
      "program": "${workspaceFolder}/node_modules/.bin/jest",
      "args": [
        "${fileBasename}",
        "--config",
        "jest.config.js",
        "--runInBand"
      ],
      "console": "integratedTerminal",
      "internalConsoleOptions": "neverOpen"
    }
  ]
}
```

### Command Line Debugging
```powershell
# Run single test with debugger
node --inspect-brk node_modules/.bin/jest --runInBand chatView.unit.test.ts

# Then open chrome://inspect in Chrome
```

## CI/CD Integration

### GitHub Actions
Tests run automatically on:
- Push to main
- Pull requests
- Manual workflow dispatch

View results: https://github.com/dayahere/openpilot/actions

### Local Pre-Push Validation
```powershell
# Run all checks before pushing
.\test-all.bat  # Or test-all.sh on Unix

# Or manually:
cd vscode-extension
npm test -- --coverage
npm run lint

cd ../core  
npm test -- --coverage
npm run build
```

## Common Issues

### Issue: vscode module not found
**Solution**: Tests use the mock in `src/__mocks__/vscode.ts`
- Ensure jest.config.js has correct moduleNameMapper
- Verify mock file exists and exports required APIs

### Issue: jest not defined in mock
**Solution**: Mock uses custom function factory instead of jest.fn()
- `@ts-nocheck` directive prevents TS checking during prepublish
- Mock is only loaded by Jest, not by vsce compile

### Issue: Coverage below 95%
**Solution**: Add more test cases or exclude certain files
```javascript
// jest.config.js
collectCoverageFrom: [
  'src/**/*.ts',
  '!src/**/*.test.ts',
  '!src/**/__tests__/**',
  '!src/utils/experimental.ts',  // Exclude specific files
],
```

### Issue: Tests timeout
**Solution**: Increase Jest timeout
```typescript
jest.setTimeout(10000);  // 10 seconds

// Or per test:
it('slow test', async () => {
  // ...
}, 10000);
```

## Test Maintenance

### Update Snapshots
```powershell
npm test -- -u
```

### Clear Jest Cache
```powershell
npm test -- --clearCache
```

### Run Tests in Parallel
```powershell
npm test -- --maxWorkers=4
```

### Run Only Changed Tests
```powershell
npm test -- --onlyChanged
```

## Resources

- [Jest Documentation](https://jestjs.io/)
- [ts-jest Configuration](https://kulshekhar.github.io/ts-jest/)
- [VS Code Extension Testing](https://code.visualstudio.com/api/working-with-extensions/testing-extension)
- [Testing Best Practices](https://testingjavascript.com/)

## Support

For issues or questions:
1. Check [TEST_IMPLEMENTATION_STATUS.md](./TEST_IMPLEMENTATION_STATUS.md)
2. Review [COMPREHENSIVE_TEST_PLAN.md](./COMPREHENSIVE_TEST_PLAN.md)
3. Open an issue on GitHub
