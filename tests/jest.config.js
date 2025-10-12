module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/integration', '<rootDir>/e2e', '<rootDir>/../core/src'],
  testMatch: ['**/*.test.ts'],
  collectCoverageFrom: [
    '../core/src/**/*.ts',
    '../vscode-extension/src/**/*.ts',
    '../desktop/src/**/*.{ts,tsx}',
    '!**/*.d.ts',
    '!**/node_modules/**',
    '!**/__tests__/**'
  ],
  coverageThreshold: {
    global: {
      branches: 90,
      functions: 90,
      lines: 90,
      statements: 90
    }
  },
  moduleNameMapper: {
    '^@openpilot/core$': '<rootDir>/../core/src/index.ts',
    '^@openpilot/core/(.*)$': '<rootDir>/../core/src/$1'
  },
  testTimeout: 30000,
  verbose: true,
  transform: {
    '^.+\\.tsx?$': ['ts-jest', {
      tsconfig: '<rootDir>/tsconfig.json'
    }]
  }
};
