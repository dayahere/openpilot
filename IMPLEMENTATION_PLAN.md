# OpenPilot - Implementation Plan

**Date:** October 13, 2025  
**Tasks:** Test Coverage + Online AI Chat + Desktop/Mobile Installers

---

## Task 1: Achieve 100% Test Coverage ✅

### Current Coverage:
- ✅ Error handling: 100% (done)
- ⚠️ Core AI engine: 95% → need 5% more
- ⚠️ Context management: 92% → need 8% more  
- ⚠️ Repository analysis: 88% → need 12% more

### Missing Coverage Areas:

#### A. Core AI Engine (5% missing)
**Uncovered code:**
- Stream chat error handling
- Token usage calculation edge cases
- Provider-specific error codes
- Request timeout scenarios
- Concurrent request handling

**New Tests Needed:**
1. Test streaming with connection interruption
2. Test token usage with empty responses
3. Test provider-specific error codes (401, 403, 429, 500)
4. Test request cancellation
5. Test rate limiting

#### B. Context Manager (8% missing)
**Uncovered code:**
- Binary file detection
- Symbolic link handling
- Permission errors
- Circular dependency detection
- Git submodule handling

**New Tests Needed:**
1. Test binary file detection (.exe, .png, .pdf)
2. Test symbolic link following
3. Test permission denied scenarios
4. Test circular dependencies
5. Test git submodules

#### C. Repository Analysis (12% missing)
**Uncovered code:**
- Multi-language project detection
- Monorepo handling
- Dependency version conflicts
- Package-lock.json parsing
- yarn.lock parsing

**New Tests Needed:**
1. Test multi-language detection (Python + Node.js)
2. Test monorepo structure
3. Test dependency conflicts
4. Test package-lock.json parsing
5. Test yarn.lock parsing
6. Test pnpm-lock.yaml parsing

---

## Task 2: Add Online AI Chat Integration ✅

### Requirements:
- Support online AI providers (OpenAI, Anthropic, Grok)
- Fallback to online when local AI unavailable
- Test both local and online in tests
- Configuration for switching providers

### Implementation:

#### A. Add Online Provider Tests
```typescript
// tests/integration/ai-engine-online.test.ts

describe('Online AI Providers', () => {
  describe('OpenAI Integration', () => {
    it('should complete code with OpenAI GPT-4', async () => {
      // Skip if no API key
      if (!process.env.OPENAI_API_KEY) {
        console.log('Skipping: OPENAI_API_KEY not set');
        return;
      }
      
      const config = {
        provider: AIProvider.OPENAI,
        model: 'gpt-4',
        apiKey: process.env.OPENAI_API_KEY,
        apiUrl: 'https://api.openai.com/v1'
      };
      
      const engine = new AIEngine({ config });
      const response = await engine.complete({
        prompt: 'Complete: function add(a, b) {',
        language: 'javascript'
      });
      
      expect(response.completions[0].text).toContain('return');
    });
  });
  
  describe('Anthropic Claude Integration', () => {
    it('should chat with Claude', async () => {
      if (!process.env.ANTHROPIC_API_KEY) return;
      // Test Claude integration
    });
  });
  
  describe('Grok Integration', () => {
    it('should chat with Grok', async () => {
      if (!process.env.GROK_API_KEY) return;
      // Test Grok integration
    });
  });
});
```

#### B. Update Existing Tests to Support Both
```typescript
// tests/integration/ai-engine.integration.test.ts

describe('AI Engine - Local and Online', () => {
  const providers = [
    { name: 'Ollama (Local)', config: ollamaConfig },
    { name: 'OpenAI (Online)', config: openaiConfig, skip: !process.env.OPENAI_API_KEY }
  ];
  
  providers.forEach(({ name, config, skip }) => {
    describe(name, () => {
      (skip ? it.skip : it)('should complete code', async () => {
        // Test with this provider
      });
    });
  });
});
```

---

## Task 3: Implement Desktop & Mobile Installers ✅

### A. Desktop Installers (v1.1)

#### Windows (.exe)
**Tool:** electron-builder

**Configuration:**
```json
// desktop/package.json
{
  "build": {
    "appId": "com.openpilot.desktop",
    "productName": "OpenPilot",
    "win": {
      "target": ["nsis"],
      "icon": "build/icon.ico"
    },
    "nsis": {
      "oneClick": false,
      "allowToChangeInstallationDirectory": true,
      "createDesktopShortcut": true,
      "createStartMenuShortcut": true
    }
  }
}
```

**Build Script:**
```powershell
# build-desktop-installer.ps1
cd desktop
npm install
npm run build
npx electron-builder build --win --x64
# Output: dist/OpenPilot-Setup-1.0.0.exe
```

#### macOS (.dmg)
```json
{
  "build": {
    "mac": {
      "target": ["dmg"],
      "icon": "build/icon.icns",
      "category": "public.app-category.developer-tools"
    }
  }
}
```

#### Linux (.deb, .AppImage)
```json
{
  "build": {
    "linux": {
      "target": ["deb", "AppImage"],
      "icon": "build/icon.png",
      "category": "Development"
    }
  }
}
```

### B. Android APK (v2.0)

**Approach:** Capacitor (easier than React Native)

**Steps:**
1. Convert web app to Capacitor
2. Add native plugins
3. Build with Android Studio

**Alternative:** Keep React Native but fix dependencies

```bash
# Fix react-native-voice issue
cd mobile
npm uninstall react-native-voice
npm install @react-native-voice/voice  # Updated package
npx react-native run-android
```

### C. iOS IPA (v2.0)

**Requirements:**
- macOS with Xcode
- Apple Developer Account ($99/year)
- Provisioning profiles

**Build:**
```bash
cd mobile
npx react-native run-ios --configuration Release
# Or use Capacitor
npx cap sync ios
open ios/App.xcworkspace
# Build in Xcode
```

---

## Implementation Timeline

### Week 1: Test Coverage (This Week)
- Day 1: Add AI Engine tests (5% → 100%)
- Day 2: Add Context Manager tests (92% → 100%)
- Day 3: Add Repository Analysis tests (88% → 100%)
- Day 4: Add Online AI provider tests
- Day 5: Test everything, fix issues

### Week 2: Desktop Installers (v1.1)
- Day 1: Setup electron-builder
- Day 2: Create Windows installer
- Day 3: Create macOS installer
- Day 4: Create Linux packages
- Day 5: Test installers, update CI/CD

### Week 3-4: Mobile Apps (v2.0)
- Week 3: Fix React Native OR migrate to Capacitor
- Week 4: Build APK and IPA, submit to stores

---

## Next Steps

1. **Immediate:** Start with test coverage improvements
2. **This week:** Add online AI provider tests
3. **Next week:** Desktop installers
4. **Next month:** Mobile apps

---

**Status:** Ready to implement ✅
