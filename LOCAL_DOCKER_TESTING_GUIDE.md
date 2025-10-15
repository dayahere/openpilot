# Local Docker Testing Guide

## Overview
This document explains how to test the complete OpenPilot project locally using Docker before pushing to GitHub. This ensures all GitHub Actions will pass.

## Prerequisites
- Docker Desktop installed and running
- PowerShell (Windows)
- Git

## Quick Start

```powershell
# Navigate to project root
cd i:\openpilot

# Run complete test suite
.\test-complete-local.ps1
```

## What Gets Tested

The local Docker test suite mirrors ALL GitHub Actions jobs:

### 1. Core Library Tests ✓
- **Build**: Compiles TypeScript to JavaScript
- **Unit Tests**: Runs Jest tests for all 17 AI providers
- **Coverage**: Validates test coverage meets minimum requirements

### 2. VSCode Extension Tests ✓ (CRITICAL)
- **Step 1**: Build core and create tarball (avoids symlink issues)
- **Step 2**: Install dev dependencies and compile TypeScript
- **Step 3**: Install production dependencies (including tarball)
- **Step 4**: Package VSIX artifact
- **Validation**: Ensures VSIX file is created successfully

### 3. VSCode Extension Unit Tests
- Webview messaging tests
- Configuration handling
- Mode switching (AI, Checkpoints, Chat)
- Integration with AIEngine

### 4. Integration Tests
- End-to-end workflow tests
- Mocked AI provider responses
- Streaming simulation

### 5. Coverage Analysis
- Line coverage
- Branch coverage  
- Function coverage
- Statement coverage

### 6. Desktop App Build (Optional)
- Electron app compilation
- Platform-specific builds

### 7. Web App Build (Optional)
- Next.js/React build
- Static asset generation

## Test Results Interpretation

###Success Output:
```
========================================
  >>> ALL CRITICAL TESTS PASSED <<<
  SAFE TO PUSH TO GITHUB
========================================

Ready to commit and push:
  git commit -m "your message"
  git push
```

### Failure Output:
```
========================================
  !!! CRITICAL TESTS FAILED !!!
  DO NOT PUSH - FIX ISSUES FIRST
========================================

Critical failures detected:
  - CoreBuild
  - VSCodePackage
```

## Critical Tests (MUST PASS)

These tests MUST pass before pushing:

1. **CoreBuild**: Core library compiles without errors
2. **CoreTests**: All unit tests pass
3. **VSCodeBuild**: Extension compiles successfully
4. **VSCodePackage**: VSIX artifact is created

If any critical test fails, **DO NOT PUSH** to GitHub.

## Test Execution Time

Expected duration for complete test suite:
- Docker image build (first time only): ~5-10 minutes
- Core build & tests: ~30 seconds
- VSCode extension build & package: ~2-3 minutes
- VSCode extension tests: ~1-2 minutes
- Integration tests: ~1 minute
- Total: ~5-7 minutes (after initial Docker build)

## Rebuilding Docker Image

If you need to rebuild the Docker test image:

```powershell
# Remove existing image
docker rmi openpilot-test:latest

# Run test script (will rebuild automatically)
.\test-complete-local.ps1
```

## Troubleshooting

### Docker Daemon Not Running
```
[FAIL] Docker not available: error during connect...
```
**Solution**: Start Docker Desktop and wait for it to fully initialize

### Build Context Too Large
```
ERROR: failed to build: failed to solve: invalid file request...
```
**Solution**: The `.dockerignore` file excludes node_modules. If you still see this, run:
```powershell
# Clean node_modules
Get-ChildItem -Path . -Recurse -Directory -Filter "node_modules" | Remove-Item -Recurse -Force

# Rebuild
.\test-complete-local.ps1
```

### VSIX Packaging Fails
```
[FAIL] VSIX packaging failed
```
**Solution**: Check that:
1. Core tarball was created (`core/openpilot-core-*.tgz`)
2. Extension compiled successfully (`vscode-extension/out/` exists)
3. `package.json` has valid version and metadata

### Tests Timeout
If tests hang, you can manually stop Docker containers:
```powershell
docker ps
docker stop <container_id>
```

## Manual Testing (Individual Components)

### Test Core Only
```powershell
docker run --rm -v "${PWD}:/workspace" -w /workspace/core openpilot-test:latest sh -c "npm install --legacy-peer-deps && npm run build && npm test"
```

### Test VSCode Extension Only
```powershell
cd vscode-extension
docker run --rm -v "${PWD}/..:/workspace" -w /workspace/vscode-extension openpilot-test:latest sh -c "npm install --legacy-peer-deps && npm run compile"
```

### Package VSIX Manually
```powershell
cd vscode-extension
docker run --rm -v "${PWD}/..:/workspace" -w /workspace/vscode-extension openpilot-test:latest sh -c "npm install -g @vscode/vsce && vsce package --allow-missing-repository"
```

## CI/CD Workflow

Recommended workflow:

1. **Make Code Changes**
   ```powershell
   # Edit files
   code .
   ```

2. **Test Locally with Docker**
   ```powershell
   .\test-complete-local.ps1
   ```

3. **Fix Any Issues**
   - Review error output
   - Make necessary fixes
   - Re-run tests until all pass

4. **Commit and Push** (only after ALL critical tests pass)
   ```powershell
   git add -A
   git commit -m "feat: add support for 17 AI providers with comprehensive tests"
   git push
   ```

5. **Monitor GitHub Actions**
   - Check: https://github.com/dayahere/openpilot/actions
   - All jobs should pass (mirroring local tests)

## Benefits of Local Docker Testing

✅ **No Local Dependencies**: Test without installing Node.js, npm, or build tools
✅ **Consistent Environment**: Same Node.js 20 environment as GitHub Actions
✅ **Fast Feedback**: Catch errors locally before pushing
✅ **Zero Failed CI Runs**: Avoid cluttering GitHub Actions history with failures
✅ **Save Time**: Fix issues locally instead of waiting for CI
✅ **Confidence**: Know your changes will pass before pushing

## Files Created

- `test-complete-local.ps1`: PowerShell orchestration script
- `Dockerfile.test`: Node.js 20 Alpine test environment
- `.dockerignore`: Excludes unnecessary files from Docker context

## AI Provider Testing Coverage

All 17 AI providers are tested:

**Local Providers (5)**:
- Ollama
- LocalAI
- llama.cpp
- TextGen WebUI
- vLLM

**Cloud Providers (11)**:
- OpenAI
- Anthropic
- Grok (X.AI)
- Groq
- Together AI
- Mistral AI
- Cohere
- Perplexity
- DeepSeek
- Google Gemini
- HuggingFace

**Custom (1)**:
- Custom endpoint

## Next Steps

After all tests pass locally:

1. Review `COMPLETE_FIX_SUMMARY.md` for full changelog
2. Review `AI_PROVIDERS.md` for AI provider documentation
3. Commit changes with descriptive message
4. Push to GitHub
5. Monitor GitHub Actions to confirm success
6. Create release if needed

## Support

If you encounter issues not covered in this guide:

1. Check Docker logs: `docker logs <container_id>`
2. Review PowerShell script output carefully
3. Run individual test commands manually to isolate issues
4. Ensure Docker Desktop has sufficient resources (CPU, Memory)

---

**Remember**: The goal is **ZERO ERRORS** locally before pushing to GitHub. This prevents failed CI runs and ensures a clean commit history.
