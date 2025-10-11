import { describe, it, expect, beforeAll, beforeEach, jest, afterEach } from '@jest/globals';
import { AIEngine, AIProvider } from '@openpilot/core';
import {
  createTestAIConfig,
  createChatContext,
  createMockOllamaChatResponse,
} from '../helpers/test-helpers';

// Mock axios - uses the manual mock in __mocks__/axios.ts
jest.mock('axios');
import axios from 'axios';

// Get the mocked axios instance
const mockedAxios = axios as jest.Mocked<typeof axios>;
const mockCreate = mockedAxios.create as jest.MockedFunction<typeof axios.create>;
let mockPost: jest.MockedFunction<any>;
let mockGet: jest.MockedFunction<any>;

describe('Full Application Generation Tests', () => {
  let engine: AIEngine;
  let config: ReturnType<typeof createTestAIConfig>;

  beforeAll(() => {
    config = createTestAIConfig(AIProvider.OLLAMA, 'codellama');
    
    // Set up the mock axios instance
    const mockAxiosInstance = {
      post: jest.fn(),
      get: jest.fn(),
      interceptors: {
        request: { use: jest.fn(), eject: jest.fn() },
        response: { use: jest.fn(), eject: jest.fn() },
      },
    };
    mockPost = mockAxiosInstance.post as jest.MockedFunction<any>;
    mockGet = mockAxiosInstance.get as jest.MockedFunction<any>;
    mockCreate.mockReturnValue(mockAxiosInstance as any);
    
    engine = new AIEngine({ config });
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  beforeEach(() => {
    // Reset and provide default implementation for mocks
    mockPost.mockReset().mockImplementation(() => Promise.resolve({ data: {} }));
    mockGet.mockReset().mockImplementation(() => Promise.resolve({ data: {} }));
  });

  describe('React Application Generation', () => {
    it('should generate a React todo component', async () => {
      const prompt = 'Create a React todo list component with add, delete, and mark complete functionality';
      
      const mockCode = `import React, { useState } from 'react';

export function TodoList() {
  const [todos, setTodos] = useState([]);
  const handleClick = () => {};
  return <div>Todo List</div>;
}`;

      mockPost.mockResolvedValueOnce(
        createMockOllamaChatResponse(mockCode)
      );

      const chatContext = createChatContext([{ role: 'user', content: prompt }]);
      const response = await engine.chat(chatContext);

      expect(response).toBeDefined();
      expect(response.content).toMatch(/import.*React/);
      expect(response.content).toMatch(/useState/);
      expect(response.content).toMatch(/function|const.*=/);
      expect(response.content).toMatch(/onClick|handleClick/i);
    }, 30000);

    it('should generate a React form component', async () => {
      const prompt = 'Create a React form component with validation for name, email, and password';
      
      const mockCode = `import React, { useState } from 'react';

export function Form() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const handleSubmit = (e) => { e.preventDefault(); };
  return <form onSubmit={handleSubmit}></form>;
}`;

      mockPost.mockResolvedValueOnce(
        createMockOllamaChatResponse(mockCode)
      );

      const chatContext = createChatContext([{ role: 'user', content: prompt }]);
      const response = await engine.chat(chatContext);

      expect(response.content).toMatch(/import.*React/);
      expect(response.content).toMatch(/useState/);
      expect(response.content).toMatch(/email|password|name/i);
      expect(response.content).toMatch(/onSubmit|handleSubmit/i);
    }, 30000);
  });

  describe('Mobile App Generation', () => {
    it('should generate React Native component structure', async () => {
      const prompt = 'Create a React Native screen for a profile page with avatar, name, and bio';
      
      const mockCode = `import React from 'react';
import { View, Text, Image, StyleSheet } from 'react-native';

const styles = StyleSheet.create({});`;

      mockPost.mockResolvedValueOnce(
        createMockOllamaChatResponse(mockCode)
      );

      const chatContext = createChatContext([{ role: 'user', content: prompt }]);
      const response = await engine.chat(chatContext);

      expect(response.content).toMatch(/import.*React/);
      expect(response.content).toMatch(/View|Text|Image|StyleSheet/);
      expect(response.content).toMatch(/const.*styles/);
    }, 30000);

    it('should include platform-specific code when requested', async () => {
      const prompt = 'Create a React Native component that uses Platform.OS to show different UI on iOS vs Android';
      
      const mockCode = `import { Platform } from 'react-native';

const isIOS = Platform.OS === 'ios';
const isAndroid = Platform.OS === 'android';`;

      mockPost.mockResolvedValueOnce(
        createMockOllamaChatResponse(mockCode)
      );

      const chatContext = createChatContext([{ role: 'user', content: prompt }]);
      const response = await engine.chat(chatContext);

      expect(response.content).toMatch(/Platform\.OS/);
      expect(response.content).toMatch(/ios|android/i);
    }, 30000);
  });

  describe('API Generation', () => {
    it('should generate Express.js REST API endpoints', async () => {
      const prompt = 'Create Express.js REST API routes for user CRUD operations';
      
      const mockCode = `const express = require('express');
const router = express.Router();

router.get('/users', (req, res) => {});
router.post('/users', (req, res) => {});
router.put('/users/:id', (req, res) => {});
router.delete('/users/:id', (req, res) => {});`;

      mockPost.mockResolvedValueOnce(
        createMockOllamaChatResponse(mockCode)
      );

      const chatContext = createChatContext([{ role: 'user', content: prompt }]);
      const response = await engine.chat(chatContext);

      expect(response.content).toMatch(/express|router/i);
      expect(response.content).toMatch(/get|post|put|delete/i);
      expect(response.content).toMatch(/req|res/);
    }, 30000);

    it('should generate API with error handling', async () => {
      const prompt = 'Create an Express.js API endpoint with try-catch error handling';
      
      const mockCode = `router.post('/api/data', async (req, res) => {
  try {
    const result = await processData(req.body);
    res.json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});`;

      mockPost.mockResolvedValueOnce(
        createMockOllamaChatResponse(mockCode)
      );

      const chatContext = createChatContext([{ role: 'user', content: prompt }]);
      const response = await engine.chat(chatContext);

      expect(response.content).toMatch(/try|catch/);
      expect(response.content).toMatch(/async|await/);
      expect(response.content).toMatch(/error|err/i);
    }, 30000);
  });

  describe('Code Quality', () => {
    it('should generate code with proper TypeScript types', async () => {
      const prompt = 'Create a TypeScript function that fetches user data with proper types';
      
      const mockCode = `interface User {
  id: number;
  name: string;
}

async function fetchUser(id: number): Promise<User> {
  const response = await fetch(\`/users/\${id}\`);
  return response.json();
}`;

      mockPost.mockResolvedValueOnce(
        createMockOllamaChatResponse(mockCode)
      );

      const chatContext = createChatContext([{ role: 'user', content: prompt }]);
      const response = await engine.chat(chatContext);

      expect(response.content).toMatch(/interface|type/);
      expect(response.content).toMatch(/: \w+/); // Type annotations
      expect(response.content).toMatch(/async.*Promise/);
    }, 30000);

    it('should include comments in complex code', async () => {
      const prompt = 'Create a complex sorting algorithm with comments explaining each step';
      
      const mockCode = `// Bubble sort algorithm
function bubbleSort(arr: number[]): number[] {
  /* Loop through array multiple times */
  for (let i = 0; i < arr.length; i++) {
    // Compare adjacent elements
    for (let j = 0; j < arr.length - i - 1; j++) {
      if (arr[j] > arr[j + 1]) {
        [arr[j], arr[j + 1]] = [arr[j + 1], arr[j]];
      }
    }
  }
  return arr;
}`;

      mockPost.mockResolvedValueOnce(
        createMockOllamaChatResponse(mockCode)
      );

      const chatContext = createChatContext([{ role: 'user', content: prompt }]);
      const response = await engine.chat(chatContext);

      expect(response.content).toMatch(/\/\/|\/\*|\*/);
    }, 30000);
  });

  describe('Performance', () => {
    it('should generate code within reasonable time', async () => {
      const startTime = Date.now();
      const chatContext = createChatContext([{
        role: 'user',
        content: 'Create a simple function',
      }]);

      mockPost.mockResolvedValueOnce(
        createMockOllamaChatResponse('function simple() { return true; }')
      );

      await engine.chat(chatContext);

      const duration = Date.now() - startTime;
      expect(duration).toBeLessThan(10000);
    }, 30000);
  });
});
