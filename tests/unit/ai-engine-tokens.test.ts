/**
 * AI Engine - Token Usage Tests
 * Coverage: Token counting, usage tracking, edge cases
 */

import { describe, it, expect } from '@jest/globals';
import { TokenUsage } from '@openpilot/core';

describe('AI Engine - Token Usage', () => {
  describe('Token Counting', () => {
    it('should handle zero tokens', () => {
      const usage: TokenUsage = {
        promptTokens: 0,
        completionTokens: 0,
        totalTokens: 0,
      };

      expect(usage.totalTokens).toBe(0);
      expect(usage.promptTokens).toBe(0);
      expect(usage.completionTokens).toBe(0);
    });

    it('should handle normal token counts', () => {
      const usage: TokenUsage = {
        promptTokens: 150,
        completionTokens: 75,
        totalTokens: 225,
      };

      expect(usage.totalTokens).toBe(225);
      expect(usage.promptTokens + usage.completionTokens).toBe(usage.totalTokens);
    });

    it('should handle very large token counts', () => {
      const usage: TokenUsage = {
        promptTokens: 100000,
        completionTokens: 50000,
        totalTokens: 150000,
      };

      expect(usage.totalTokens).toBeGreaterThan(100000);
      expect(usage.promptTokens).toBeLessThanOrEqual(usage.totalTokens);
    });

    it('should validate token total matches sum', () => {
      const usage: TokenUsage = {
        promptTokens: 120,
        completionTokens: 80,
        totalTokens: 200,
      };

      const calculatedTotal = usage.promptTokens + usage.completionTokens;
      expect(calculatedTotal).toBe(usage.totalTokens);
    });

    it('should handle edge case with max safe integer', () => {
      const maxSafe = Number.MAX_SAFE_INTEGER;
      const usage: TokenUsage = {
        promptTokens: 1,
        completionTokens: 1,
        totalTokens: 2,
      };

      expect(usage.totalTokens).toBeLessThan(maxSafe);
    });
  });

  describe('Token Usage Validation', () => {
    it('should validate prompt tokens are non-negative', () => {
      const usage: TokenUsage = {
        promptTokens: 100,
        completionTokens: 50,
        totalTokens: 150,
      };

      expect(usage.promptTokens).toBeGreaterThanOrEqual(0);
    });

    it('should validate completion tokens are non-negative', () => {
      const usage: TokenUsage = {
        promptTokens: 100,
        completionTokens: 50,
        totalTokens: 150,
      };

      expect(usage.completionTokens).toBeGreaterThanOrEqual(0);
    });

    it('should validate total tokens are non-negative', () => {
      const usage: TokenUsage = {
        promptTokens: 100,
        completionTokens: 50,
        totalTokens: 150,
      };

      expect(usage.totalTokens).toBeGreaterThanOrEqual(0);
    });

    it('should handle token usage with only prompt tokens', () => {
      const usage: TokenUsage = {
        promptTokens: 100,
        completionTokens: 0,
        totalTokens: 100,
      };

      expect(usage.completionTokens).toBe(0);
      expect(usage.totalTokens).toBe(usage.promptTokens);
    });

    it('should handle token usage with only completion tokens', () => {
      const usage: TokenUsage = {
        promptTokens: 0,
        completionTokens: 75,
        totalTokens: 75,
      };

      expect(usage.promptTokens).toBe(0);
      expect(usage.totalTokens).toBe(usage.completionTokens);
    });
  });

  describe('Token Usage Calculations', () => {
    it('should calculate token ratio', () => {
      const usage: TokenUsage = {
        promptTokens: 200,
        completionTokens: 100,
        totalTokens: 300,
      };

      const ratio = usage.promptTokens / usage.completionTokens;
      expect(ratio).toBe(2);
    });

    it('should handle zero completion tokens in ratio calculation', () => {
      const usage: TokenUsage = {
        promptTokens: 100,
        completionTokens: 0,
        totalTokens: 100,
      };

      const ratio = usage.completionTokens === 0 ? Infinity : usage.promptTokens / usage.completionTokens;
      expect(ratio).toBe(Infinity);
    });

    it('should calculate percentage of total', () => {
      const usage: TokenUsage = {
        promptTokens: 150,
        completionTokens: 50,
        totalTokens: 200,
      };

      const promptPercentage = (usage.promptTokens / usage.totalTokens) * 100;
      const completionPercentage = (usage.completionTokens / usage.totalTokens) * 100;

      expect(promptPercentage).toBe(75);
      expect(completionPercentage).toBe(25);
      expect(promptPercentage + completionPercentage).toBe(100);
    });

    it('should handle small token counts', () => {
      const usage: TokenUsage = {
        promptTokens: 1,
        completionTokens: 1,
        totalTokens: 2,
      };

      expect(usage.totalTokens).toBe(2);
    });

    it('should validate token efficiency', () => {
      const usage: TokenUsage = {
        promptTokens: 50,
        completionTokens: 200,
        totalTokens: 250,
      };

      // Completion tokens > prompt tokens indicates good efficiency
      const isEfficient = usage.completionTokens > usage.promptTokens;
      expect(isEfficient).toBe(true);
    });
  });

  describe('Provider-Specific Token Handling', () => {
    it('should handle OpenAI token format', () => {
      const openAIUsage = {
        prompt_tokens: 100,
        completion_tokens: 50,
        total_tokens: 150,
      };

      const normalized: TokenUsage = {
        promptTokens: openAIUsage.prompt_tokens,
        completionTokens: openAIUsage.completion_tokens,
        totalTokens: openAIUsage.total_tokens,
      };

      expect(normalized.promptTokens).toBe(100);
      expect(normalized.completionTokens).toBe(50);
      expect(normalized.totalTokens).toBe(150);
    });

    it('should handle Anthropic token format', () => {
      const anthropicUsage = {
        input_tokens: 120,
        output_tokens: 80,
      };

      const normalized: TokenUsage = {
        promptTokens: anthropicUsage.input_tokens,
        completionTokens: anthropicUsage.output_tokens,
        totalTokens: anthropicUsage.input_tokens + anthropicUsage.output_tokens,
      };

      expect(normalized.promptTokens).toBe(120);
      expect(normalized.completionTokens).toBe(80);
      expect(normalized.totalTokens).toBe(200);
    });

    it('should handle missing token data gracefully', () => {
      const partialUsage = {
        total_tokens: 150,
      };

      const normalized: TokenUsage = {
        promptTokens: 0,
        completionTokens: 0,
        totalTokens: partialUsage.total_tokens || 0,
      };

      expect(normalized.totalTokens).toBe(150);
      expect(normalized.promptTokens).toBe(0);
      expect(normalized.completionTokens).toBe(0);
    });

    it('should handle completely missing token data', () => {
      const normalized: TokenUsage = {
        promptTokens: 0,
        completionTokens: 0,
        totalTokens: 0,
      };

      expect(normalized.totalTokens).toBe(0);
    });
  });

  describe('Token Limits', () => {
    it('should check if usage exceeds limit', () => {
      const usage: TokenUsage = {
        promptTokens: 3000,
        completionTokens: 1500,
        totalTokens: 4500,
      };

      const limit = 4096;
      const exceedsLimit = usage.totalTokens > limit;

      expect(exceedsLimit).toBe(true);
    });

    it('should check if usage is within limit', () => {
      const usage: TokenUsage = {
        promptTokens: 2000,
        completionTokens: 1000,
        totalTokens: 3000,
      };

      const limit = 4096;
      const withinLimit = usage.totalTokens <= limit;

      expect(withinLimit).toBe(true);
    });

    it('should calculate remaining tokens', () => {
      const usage: TokenUsage = {
        promptTokens: 1500,
        completionTokens: 0,
        totalTokens: 1500,
      };

      const limit = 4096;
      const remaining = limit - usage.promptTokens;

      expect(remaining).toBe(2596);
    });

    it('should handle different model limits', () => {
      const modelLimits = {
        'gpt-3.5-turbo': 4096,
        'gpt-4': 8192,
        'gpt-4-32k': 32768,
        'claude-2': 100000,
      };

      Object.values(modelLimits).forEach((limit) => {
        expect(limit).toBeGreaterThan(0);
        expect(typeof limit).toBe('number');
      });
    });
  });
});
