# AI Provider Support - Complete List

## 🎯 Total Providers Supported: 17

### 🏠 Local / Self-Hosted Providers (5)

#### 1. **Ollama** (`ollama`)
- **Best for**: Easy local model deployment
- **Models**: CodeLlama, Llama 2, Mistral, Mixtral, etc.
- **Default URL**: `http://localhost:11434`
- **Setup**: Install from https://ollama.ai

#### 2. **LocalAI** (`localai`)
- **Best for**: Drop-in OpenAI replacement
- **Models**: GGML models, Whisper, Stable Diffusion
- **Default URL**: `http://localhost:8080`
- **Setup**: Docker or binary from https://localai.io

#### 3. **llama.cpp** (`llamacpp`)
- **Best for**: Lightweight C++ inference
- **Models**: Any GGUF format models
- **Default URL**: `http://localhost:8080`
- **Setup**: Build from https://github.com/ggerganov/llama.cpp

#### 4. **Text Generation WebUI** (`textgen-webui`)
- **Best for**: oobabooga's interface
- **Models**: Wide variety with UI
- **Default URL**: `http://localhost:5000`
- **Setup**: https://github.com/oobabooga/text-generation-webui

#### 5. **vLLM** (`vllm`)
- **Best for**: High-throughput serving
- **Models**: Llama, Mistral, Yi, etc.
- **Default URL**: `http://localhost:8000`
- **Setup**: https://github.com/vllm-project/vllm

---

### ☁️ Cloud Providers (11)

#### 6. **OpenAI** (`openai`)
- **Models**: GPT-4, GPT-4 Turbo, GPT-4o, GPT-3.5
- **API Key Required**: Yes
- **Website**: https://platform.openai.com

#### 7. **Anthropic** (`anthropic`)
- **Models**: Claude 3.5 Sonnet, Claude 3 Opus, Claude 3 Sonnet
- **API Key Required**: Yes
- **Website**: https://console.anthropic.com

#### 8. **Grok (xAI)** (`grok`)
- **Models**: Grok Beta
- **API Key Required**: Yes
- **Website**: https://x.ai

#### 9. **Groq** (`groq`)
- **Best for**: Ultra-fast inference
- **Models**: Mixtral, Llama 2, Gemma
- **API Key Required**: Yes
- **Website**: https://console.groq.com

#### 10. **Together AI** (`together`)
- **Models**: 50+ open-source models
- **API Key Required**: Yes
- **Website**: https://api.together.xyz

#### 11. **Mistral AI** (`mistral`)
- **Models**: Mistral Large, Mistral Medium, Mistral Small
- **API Key Required**: Yes
- **Website**: https://console.mistral.ai

#### 12. **Cohere** (`cohere`)
- **Models**: Command, Command Light, Command R+
- **API Key Required**: Yes
- **Website**: https://dashboard.cohere.com

#### 13. **Perplexity AI** (`perplexity`)
- **Models**: pplx-70b-online, pplx-7b-online
- **API Key Required**: Yes
- **Website**: https://docs.perplexity.ai

#### 14. **DeepSeek** (`deepseek`)
- **Models**: DeepSeek Coder, DeepSeek Chat
- **API Key Required**: Yes
- **Website**: https://platform.deepseek.com

#### 15. **Google Gemini** (`gemini`)
- **Models**: Gemini 1.5 Pro, Gemini 1.5 Flash
- **API Key Required**: Yes
- **Website**: https://ai.google.dev

#### 16. **HuggingFace** (`huggingface`)
- **Models**: 100k+ models via Inference API
- **API Key Required**: Yes
- **Website**: https://huggingface.co

---

### 🔧 Other (1)

#### 17. **Custom** (`custom`)
- **Best for**: Any OpenAI-compatible endpoint
- **Requires**: Custom API URL
- **Use case**: Self-hosted APIs, enterprise endpoints

---

## 🚀 Quick Start Examples

### Local Setup (No API Key Required)

```json
{
  "provider": "ollama",
  "model": "codellama",
  "temperature": 0.7,
  "maxTokens": 2048
}
```

### Cloud Setup (API Key Required)

```json
{
  "provider": "anthropic",
  "model": "claude-3-5-sonnet",
  "apiKey": "your-api-key-here",
  "temperature": 0.7,
  "maxTokens": 4096
}
```

### Custom Endpoint

```json
{
  "provider": "custom",
  "model": "your-model",
  "apiUrl": "https://your-endpoint.com/v1",
  "apiKey": "optional-key",
  "temperature": 0.7
}
```

---

## 📊 Provider Comparison

| Provider | Cost | Speed | Code Quality | Privacy | Setup Difficulty |
|----------|------|-------|--------------|---------|------------------|
| Ollama | Free | Medium | Good | 100% | Easy |
| LocalAI | Free | Medium | Good | 100% | Medium |
| llama.cpp | Free | Fast | Good | 100% | Hard |
| Text Gen WebUI | Free | Medium | Good | 100% | Medium |
| vLLM | Free | Very Fast | Good | 100% | Medium |
| OpenAI | $$ | Very Fast | Excellent | Cloud | Very Easy |
| Anthropic | $$$ | Fast | Excellent | Cloud | Very Easy |
| Groq | $ | Ultra Fast | Very Good | Cloud | Very Easy |
| Together AI | $ | Fast | Very Good | Cloud | Very Easy |
| Mistral | $$ | Fast | Excellent | Cloud | Very Easy |
| Cohere | $$ | Fast | Very Good | Cloud | Very Easy |
| Perplexity | $ | Fast | Good | Cloud | Very Easy |
| DeepSeek | $ | Fast | Very Good | Cloud | Very Easy |
| Gemini | $$ | Fast | Excellent | Cloud | Very Easy |
| HuggingFace | Free* | Varies | Varies | Cloud | Easy |

*Free tier available

---

## 🎓 Recommended Providers

### For Privacy-Conscious Users
1. **Ollama** - Easiest local setup
2. **LocalAI** - Most versatile
3. **vLLM** - Best performance

### For Best Quality
1. **Claude 3.5 Sonnet** (Anthropic) - Best for coding
2. **GPT-4o** (OpenAI) - Most capable
3. **Gemini 1.5 Pro** (Google) - Long context

### For Speed
1. **Groq** - Ultra-fast inference
2. **vLLM** - Fast local inference
3. **Together AI** - Fast cloud inference

### For Cost-Effectiveness
1. **Ollama** - Completely free
2. **Groq** - Very cheap cloud
3. **DeepSeek** - Affordable + quality

---

## 🔒 Privacy & Security

### 100% Private (Data Never Leaves Your Machine)
- Ollama
- LocalAI
- llama.cpp
- Text Generation WebUI
- vLLM

### Cloud-Based (Data Sent to Provider)
- All cloud providers listed above
- Check each provider's privacy policy
- Consider data residency requirements

---

## 📝 Configuration in VSCode Extension

All providers are available in the chat window dropdown:

1. Open OpenPilot chat view
2. Select provider from dropdown
3. Choose model
4. Adjust temperature (0-2)
5. Start chatting!

The extension will automatically handle:
- API authentication
- Request formatting
- Streaming responses
- Error handling
- Rate limiting

---

## 🛠️ Testing All Providers

Run comprehensive tests:

```powershell
# Test locally with Docker
.\test-local-docker.ps1

# Test specific provider
cd core
npm test -- --testNamePattern="handles all cloud AI providers"
```

---

## 📚 Additional Resources

- [Core Types Documentation](../core/src/types/index.ts)
- [AIEngine Implementation](../core/src/ai-engine/index.ts)
- [VSCode Extension UI](../vscode-extension/src/views/chatView.ts)
- [Test Suite](../core/src/__tests__/)

---

## 🤝 Contributing

To add a new provider:

1. Add enum value to `AIProvider` in `core/src/types/index.ts`
2. Add case in `AIEngine.createProvider()` in `core/src/ai-engine/index.ts`
3. Add option in VSCode extension UI in `vscode-extension/src/views/chatView.ts`
4. Add tests in `core/src/__tests__/types.test.ts` and `ai-engine.test.ts`
5. Update this documentation

---

**Last Updated**: October 14, 2025
**Total Providers**: 17 (5 local + 11 cloud + 1 custom)
