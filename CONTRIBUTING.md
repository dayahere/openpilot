# Contributing to OpenPilot

Thank you for your interest in contributing to OpenPilot! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the community
- Show empathy towards other community members

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in Issues
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots if applicable
   - Your environment (OS, Node version, etc.)

### Suggesting Features

1. Check existing feature requests
2. Create an issue with:
   - Clear use case
   - Expected behavior
   - Why this feature would be useful
   - Possible implementation approach

### Pull Requests

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the coding standards
   - Write tests for new features
   - Update documentation

4. **Run quality checks**
   ```bash
   python scripts/auto-fix.py
   npm run test:all
   ```

5. **Commit your changes**
   ```bash
   git commit -m "feat: add amazing feature"
   ```
   
   Follow conventional commits:
   - `feat:` new feature
   - `fix:` bug fix
   - `docs:` documentation changes
   - `style:` formatting changes
   - `refactor:` code refactoring
   - `test:` adding tests
   - `chore:` maintenance tasks

6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request**
   - Link any related issues
   - Describe your changes
   - Add screenshots for UI changes

## Development Setup

See [INSTALL.md](INSTALL.md) for detailed setup instructions.

Quick start:
```bash
npm install
pip install -r requirements.txt
npm run build:all
```

## Coding Standards

### TypeScript/JavaScript

- Use TypeScript for new code
- Follow the existing code style
- Use meaningful variable names
- Add JSDoc comments for public APIs
- Run `npm run lint` before committing

### Python

- Follow PEP 8
- Use type hints
- Add docstrings for functions/classes
- Run `black`, `isort`, and `flake8` before committing

### Testing

- Write unit tests for new features
- Maintain 80%+ code coverage
- Test edge cases
- Use descriptive test names

Example:
```typescript
describe('AIEngine', () => {
  it('should return valid response for chat query', async () => {
    // Test implementation
  });
});
```

## Project Structure

```
openpilot/
├── core/                 # Shared AI logic
├── vscode-extension/     # VS Code extension
├── desktop/              # Electron app
├── mobile/               # React Native app
├── web/                  # React PWA
├── tests/                # Test suites
├── scripts/              # Build/utility scripts
└── docs/                 # Documentation
```

## Testing Guidelines

### Unit Tests
- Test individual functions/methods
- Mock external dependencies
- Focus on edge cases

### Integration Tests
- Test component interactions
- Use realistic data
- Test error handling

### E2E Tests
- Test user workflows
- Use test fixtures
- Clean up test data

## Documentation

- Update README.md for major changes
- Add inline comments for complex logic
- Update API documentation
- Include code examples

## Review Process

1. **Automated Checks**
   - Linting
   - Tests
   - Build verification

2. **Code Review**
   - At least one approving review required
   - Address all feedback
   - Keep discussions professional

3. **Merge**
   - Squash commits for clean history
   - Update changelog
   - Close related issues

## Release Process

1. Update version in package.json
2. Update CHANGELOG.md
3. Create release tag
4. Build and publish packages
5. Update documentation

## Getting Help

- **Discord**: Join our community
- **Issues**: Ask questions via GitHub Issues
- **Email**: Contact maintainers directly

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Credited in the project

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for making OpenPilot better! 🚀
