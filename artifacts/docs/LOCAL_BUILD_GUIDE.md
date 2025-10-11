# 🚀 OpenPilot - Local Build & Test Guide

Complete guide for building, testing, and creating artifacts locally - matching the GitHub Actions CI/CD workflow.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Local Build Options](#local-build-options)
- [Testing Locally](#testing-locally)
- [Docker Testing](#docker-testing)
- [GitHub Actions Integration](#github-actions-integration)
- [Artifacts](#artifacts)
- [Troubleshooting](#troubleshooting)

## ✅ Prerequisites

### Option 1: Local Development (with npm)

```bash
# Required
- Node.js 20+
- npm 9+
- Python 3.11+

# Optional
- Docker Desktop (for Docker testing)
```

### Option 2: Docker Only (no local npm required)

```bash
# Required
- Docker Desktop
- docker-compose
```

## 🏃 Quick Start

### Windows (PowerShell)

```powershell
# Build everything with coverage
.\build-local.ps1 -BuildType all -Coverage

# Just run tests
.\build-local.ps1 -BuildType tests -Coverage

# Docker build and test
.\build-local.ps1 -BuildType docker -Coverage

# Clean build
.\build-local.ps1 -BuildType all -Coverage -Clean
```

### Linux/Mac (Bash)

```bash
# Make script executable
chmod +x build-local.sh

# Build everything with coverage
./build-local.sh all

# With coverage
COVERAGE=true ./build-local.sh all

# Docker only
./build-local.sh docker

# Clean build
CLEAN=true COVERAGE=true ./build-local.sh all
```

## 🔨 Local Build Options

### Build Types

| Type | Description | Commands Run |
|------|-------------|--------------|
| `all` | Complete build pipeline | Core + Tests + Docker + Docs + Archive |
| `core` | Build core library only | TypeScript compilation |
| `tests` | Build core + run tests | Core + Jest tests |
| `docker` | Docker build + tests | Docker image + tests in container |
| `docs` | Generate documentation | TypeDoc + coverage reports |

### Environment Variables

#### PowerShell
```powershell
.\build-local.ps1 -BuildType all -Coverage -SkipTests -Clean
```

#### Bash
```bash
export BUILD_TYPE=all
export COVERAGE=true
export SKIP_TESTS=false
export CLEAN=true
./build-local.sh
```

## 🧪 Testing Locally

### 1. Run All Tests with Coverage

```bash
# Windows
.\build-local.ps1 -BuildType tests -Coverage

# Linux/Mac
COVERAGE=true ./build-local.sh tests
```

### 2. Run Specific Test Suites

```bash
cd tests

# Install dependencies
npm install

# Run all tests
npm test

# Run integration tests only
npm test -- --testPathPattern=integration

# Run with coverage
npm test -- --coverage

# Watch mode
npm test -- --watch
```

### 3. Run Auto-Fix Loop

```bash
cd tests

# Run auto-fix script
python autofix.py

# Or in Docker
docker-compose -f ../docker-compose.test.yml run --rm test-autofix
```

## 🐳 Docker Testing

### Build Docker Image

```bash
docker-compose -f docker-compose.test.yml build test-runner
```

### Run Tests in Docker

```bash
# Standard test run
docker-compose -f docker-compose.test.yml run --rm test-runner

# With coverage
docker-compose -f docker-compose.test.yml run --rm test-coverage

# Integration tests only
docker-compose -f docker-compose.test.yml run --rm test-integration

# E2E tests
docker-compose -f docker-compose.test.yml run --rm test-e2e

# Auto-fix loop
docker-compose -f docker-compose.test.yml run --rm test-autofix
```

### Extract Coverage from Docker

```powershell
# Windows
docker create --name coverage-temp openpilot-test-runner:latest
docker cp coverage-temp:/app/tests/coverage ./coverage-docker
docker rm coverage-temp

# Linux/Mac
docker create --name coverage-temp openpilot-test-runner:latest
docker cp coverage-temp:/app/tests/coverage ./coverage-docker
docker rm coverage-temp
```

## 🔄 GitHub Actions Integration

The local build process mirrors the GitHub Actions CI/CD pipeline exactly.

### Workflow Triggers

```yaml
# Automatically runs on:
- Push to main/develop branches
- Pull requests to main/develop
- Manual workflow dispatch
- Git tags (for releases)
```

### Jobs Overview

1. **build-and-test**: Builds core, runs tests, generates coverage
2. **docker-test**: Builds Docker image, runs containerized tests
3. **code-quality**: ESLint, Prettier, security audits
4. **build-docs**: Generates TypeDoc and documentation site
5. **deploy-pages**: Deploys to GitHub Pages (main branch only)
6. **create-release**: Creates GitHub releases (tags only)
7. **auto-fix**: Runs auto-fix on test failures
8. **notify**: Sends build status notifications

### Local Equivalents

| GitHub Action | Local Command |
|---------------|---------------|
| build-and-test | `.\build-local.ps1 -BuildType tests -Coverage` |
| docker-test | `docker-compose -f docker-compose.test.yml run --rm test-runner` |
| code-quality | `npm run lint` (in core/) |
| build-docs | `.\build-local.ps1 -BuildType docs` |
| create-release | `.\build-local.ps1 -BuildType all` (creates archive) |
| auto-fix | `python tests/autofix.py` |

## 📦 Artifacts

### Local Build Output

After running `build-local.ps1 -BuildType all -Coverage`, you'll find:

```
artifacts/
├── coverage/               # Test coverage reports
│   ├── lcov-report/       # HTML coverage report
│   └── coverage-summary.json
├── docker-coverage/       # Coverage from Docker tests
├── docs/                  # Documentation site
│   ├── index.html
│   ├── README.html
│   ├── TESTING.html
│   ├── api/              # TypeDoc API docs
│   └── coverage/         # Coverage report copy
└── openpilot-v1.0.0-YYYYMMDD.zip  # Release archive

build-output/
├── core/
│   ├── dist/             # Compiled TypeScript
│   └── package.json
└── ...
```

### Opening Artifacts

**Windows:**
```powershell
# Build script automatically opens artifacts folder
# Or manually:
explorer artifacts
```

**macOS:**
```bash
open artifacts
```

**Linux:**
```bash
xdg-open artifacts
```

### Viewing Coverage Reports

```bash
# Local coverage
open artifacts/coverage/lcov-report/index.html

# Docker coverage
open artifacts/docker-coverage/lcov-report/index.html

# Documentation site
open artifacts/docs/index.html
```

## 🎯 Testing for 100% Coverage

### Step-by-Step Process

1. **Run Initial Tests with Coverage**
```bash
cd tests
npm test -- --coverage
```

2. **Check Coverage Report**
```bash
# View in browser
open coverage/lcov-report/index.html

# Or check summary
cat coverage/coverage-summary.json
```

3. **Identify Uncovered Code**
- Red lines in HTML report = not covered
- Focus on:
  - Branches (if/else statements)
  - Error handling paths
  - Edge cases

4. **Add Missing Tests**
- Create tests for uncovered functions
- Test error scenarios
- Test boundary conditions

5. **Run Auto-Fix Loop**
```bash
python autofix.py
```

6. **Verify Coverage Thresholds**
```javascript
// jest.config.js
coverageThreshold: {
  global: {
    branches: 90,
    functions: 90,
    lines: 90,
    statements: 90
  }
}
```

### Current Coverage Status

Run `npm test -- --coverage` to see current coverage levels.

Target: **>= 90%** for all metrics (lines, statements, functions, branches)

## 🐛 Troubleshooting

### Issue: Docker build fails

**Solution:**
```bash
# Clean rebuild
docker-compose -f docker-compose.test.yml build --no-cache test-runner

# Check Docker resources
docker system df
docker system prune  # if needed
```

### Issue: Tests fail with type errors

**Solution:**
```bash
# Check TypeScript compilation
cd tests
npx tsc --noEmit

# Run auto-fix
python autofix.py
```

### Issue: Coverage below threshold

**Solution:**
```bash
# View detailed coverage
npm test -- --coverage --verbose

# Check specific uncovered files
open coverage/lcov-report/index.html
```

### Issue: npm not installed locally

**Solution:** Use Docker testing exclusively:
```bash
# All tests in Docker
docker-compose -f docker-compose.test.yml run --rm test-runner

# Coverage in Docker
docker-compose -f docker-compose.test.yml run --rm test-coverage

# Extract results
docker cp <container-id>:/app/tests/coverage ./coverage
```

### Issue: Permission denied on Linux

**Solution:**
```bash
# Make scripts executable
chmod +x build-local.sh
chmod +x tests/autofix.py
```

### Issue: Build script errors

**Solution:**
```bash
# Clean everything
CLEAN=true ./build-local.sh all

# Or manually
rm -rf build-output artifacts core/dist tests/coverage
```

## 📚 Additional Resources

- **[Testing System Guide](tests/TESTING_SYSTEM_GUIDE.md)** - Comprehensive testing documentation
- **[Docker Testing Guide](docs/DOCKER_TESTING_GUIDE.md)** - Docker-specific guide
- **[CI/CD Workflow](.github/workflows/ci-cd.yml)** - GitHub Actions configuration
- **[Contributing Guidelines](CONTRIBUTING.md)** - How to contribute

## 🎓 Examples

### Example 1: Full Local Build with Coverage

```powershell
# Windows - Complete build pipeline
.\build-local.ps1 -BuildType all -Coverage -Clean

# Result:
# ✅ Core library compiled
# ✅ Tests passed with >90% coverage
# ✅ Docker image built
# ✅ Documentation generated
# ✅ Release archive created
# 📁 Artifacts saved to: artifacts/
```

### Example 2: Quick Test Iteration

```bash
# Linux/Mac - Fast test iteration
cd tests
npm test -- --watch

# Change code -> tests auto-run
# Fix issues -> tests re-run
# Coverage updates automatically
```

### Example 3: Pre-Commit Check

```bash
# Before committing, verify everything works
./build-local.sh tests

# If successful:
# - All tests pass
# - TypeScript compiles
# - No lint errors
# - Coverage >= 90%
```

### Example 4: Docker-Only Workflow

```bash
# No local npm needed - everything in Docker

# 1. Build image
docker-compose -f docker-compose.test.yml build test-runner

# 2. Run tests
docker-compose -f docker-compose.test.yml run --rm test-runner

# 3. Get coverage
docker-compose -f docker-compose.test.yml run --rm test-coverage

# 4. Extract results
docker create --name temp openpilot-test-runner:latest
docker cp temp:/app/tests/coverage ./results
docker rm temp
```

---

## 🚀 Next Steps

1. Run local build: `.\build-local.ps1 -BuildType all -Coverage`
2. Review coverage report
3. Add missing tests if coverage < 90%
4. Push changes to trigger GitHub Actions
5. Deploy to GitHub Pages automatically

**Happy Building! 🎉**
