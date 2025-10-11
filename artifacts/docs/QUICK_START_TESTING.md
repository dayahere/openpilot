# 🚀 Quick Start Guide - OpenPilot Testing

## ⚡ Super Fast Setup (3 Steps)

### Step 1: Run Setup Script

```cmd
cd i:\openpilot
setup-tests.bat
```

This will:
- ✅ Install all dependencies
- ✅ Build core library
- ✅ Setup test environment
- ✅ Verify everything works

**Time:** ~3-5 minutes

---

### Step 2: Run Tests

```cmd
run-tests.bat
```

This will run all tests and show results.

**Time:** ~30 seconds

---

### Step 3: View Results

Look for:
- ✅ **Green checkmarks** = Tests passed
- ❌ **Red X's** = Tests failed
- 📊 **Coverage %** = Code coverage

---

## 📋 Manual Setup (If Scripts Don't Work)

### 1. Install Dependencies

```cmd
cd i:\openpilot

REM Install root dependencies
npm install

REM Install core dependencies
cd core
npm install
npm run build
cd ..

REM Install test dependencies
cd tests
npm install
cd ..
```

### 2. Run Tests

```cmd
cd i:\openpilot\tests
npm test
```

---

## 🎯 Common Test Commands

### Run All Tests
```cmd
cd tests
npm test
```

### Run with Coverage
```cmd
cd tests
npm run test:coverage
```

### Run Integration Tests Only
```cmd
cd tests
npm run test:integration
```

### Run E2E Tests (Requires Web App Running)
```cmd
REM Terminal 1: Start web app
cd web
npm start

REM Terminal 2: Run E2E tests
cd tests
npm run test:e2e
```

### Watch Mode (Auto-rerun on changes)
```cmd
cd tests
npm run test:watch
```

---

## 🔧 Troubleshooting

### Issue 1: "npm not found"

**Solution:** Install Node.js from https://nodejs.org/

### Issue 2: "Cannot find module '@openpilot/core'"

**Solution:**
```cmd
cd core
npm run build
```

### Issue 3: "Ollama connection failed"

**Solution:**
```cmd
REM Install Ollama from https://ollama.ai/
ollama serve
ollama pull codellama
```

### Issue 4: Tests fail

**Solution:**
```cmd
REM Clear cache and retry
cd tests
npm test -- --clearCache
npm test
```

---

## ✅ What Gets Tested

### 1. AI Engine (50+ tests)
- ✅ Code completion
- ✅ Chat responses
- ✅ Streaming
- ✅ Multiple providers
- ✅ Error handling

### 2. Context Manager (30+ tests)
- ✅ Repository analysis
- ✅ File scanning
- ✅ Dependency detection
- ✅ Symbol extraction

### 3. App Generation (40+ tests)
- ✅ React components
- ✅ Mobile apps
- ✅ Game scripts
- ✅ APIs
- ✅ Full-stack apps

### 4. Web UI (10+ tests)
- ✅ Page loading
- ✅ Chat interface
- ✅ Settings
- ✅ Offline mode

---

## 📊 Success Criteria

Tests pass when:
- ✅ 0 test failures
- ✅ 90%+ coverage
- ✅ No critical errors

---

## 🎯 Expected Results

After running tests:

```
Test Suites: 8 passed, 8 total
Tests:       150 passed, 150 total
Coverage:    90.5%
Time:        25s
```

---

## 🚀 Auto-Fix (Advanced)

For automatic issue fixing:

```cmd
python scripts\run-tests.py
```

This will:
1. Run all tests
2. Find issues
3. Attempt fixes
4. Re-run tests
5. Repeat until all pass (max 3 iterations)

---

## 📚 Full Documentation

For complete details, see:
- **[tests/README.md](tests/README.md)** - Full test guide
- **[TESTING_SUMMARY.md](TESTING_SUMMARY.md)** - Complete overview

---

## 🎉 That's It!

Just run `setup-tests.bat` then `run-tests.bat` and you're done!

---

**Questions?** Check the [FAQ](docs/FAQ.md) or [TESTING_SUMMARY.md](TESTING_SUMMARY.md)

**Last Updated:** October 11, 2025  
**Status:** ✅ Ready to Use
