# Git Workflow and Branch Protection Guide

## Branch Structure

This repository uses a **three-branch workflow** to ensure code quality and stability:

```
feature/* → dev → main
```

### Branches

1. **`main`** - Production-ready code
   - Protected branch (direct pushes disabled)
   - Only accepts merges from `dev`
   - All tests must pass before merge
   - Requires code review and approval

2. **`dev`** - Development integration branch
   - Protected branch (direct pushes disabled)
   - Only accepts merges from `feature/*` branches
   - All tests must pass before merge
   - Staging environment for testing

3. **`feature/*`** - Feature development branches
   - Created from `dev` for new features/fixes
   - Developer can push directly
   - Must pass all tests before merging to `dev`
   - Deleted after merge

---

## Workflow Steps

### 1. Create a Feature Branch

Always create feature branches from `dev`:

```bash
# Ensure you're on dev and it's up to date
git checkout dev
git pull origin dev

# Create and checkout new feature branch
git checkout -b feature/your-feature-name

# Example:
git checkout -b feature/add-chat-history
git checkout -b feature/fix-completion-bug
```

### 2. Develop and Test

Work on your feature branch:

```bash
# Make changes
# ... edit files ...

# Run tests locally
docker-compose -f docker-compose.test.yml run --rm test-runner

# Add and commit changes
git add .
git commit -m "feat: add chat history feature"

# Push to GitHub
git push -u origin feature/your-feature-name
```

### 3. Create Pull Request: Feature → Dev

1. Go to GitHub repository: https://github.com/dayahere/openpilot
2. Click "Pull Requests" → "New Pull Request"
3. Set base: `dev` ← compare: `feature/your-feature-name`
4. Fill in PR template:
   - **Title**: Clear description of feature
   - **Description**: What changes were made and why
   - **Tests**: Confirm all tests pass
   - **Screenshots**: If UI changes
5. Click "Create Pull Request"
6. Wait for CI/CD checks to complete ✅
7. Request code review
8. Address review comments if needed
9. Once approved and all checks pass, merge to `dev`
10. Delete feature branch after merge

### 4. Create Pull Request: Dev → Main

When dev is stable and ready for production:

1. Go to GitHub repository
2. Click "Pull Requests" → "New Pull Request"
3. Set base: `main` ← compare: `dev`
4. Fill in PR template:
   - **Title**: Release version (e.g., "Release v1.2.0")
   - **Description**: Summary of all features/fixes included
   - **Tests**: Confirm all tests pass (43/43)
   - **Coverage**: Include coverage report
5. Click "Create Pull Request"
6. Wait for CI/CD checks (all tests must pass)
7. Require at least 1 approval from code reviewer
8. Once approved, merge to `main`
9. Create Git tag for release:
   ```bash
   git checkout main
   git pull origin main
   git tag -a v1.2.0 -m "Release version 1.2.0"
   git push origin v1.2.0
   ```

---

## Branch Protection Rules

### Main Branch Protection

**Settings → Branches → Branch protection rules → Add rule**

Branch name pattern: `main`

Enable:
- ✅ Require a pull request before merging
  - ✅ Require approvals (1)
  - ✅ Dismiss stale pull request approvals when new commits are pushed
  - ✅ Require review from Code Owners
- ✅ Require status checks to pass before merging
  - ✅ Require branches to be up to date before merging
  - Required status checks:
    - `test-core`
    - `test-integration`
    - `test-mobile`
    - `test-desktop`
    - `test-web`
    - `test-backend`
    - `test-vscode-extension`
    - `build-all`
- ✅ Require conversation resolution before merging
- ✅ Require linear history
- ✅ Include administrators (even admins can't bypass these rules)
- ✅ Restrict who can push to matching branches
  - Nobody (only via PR)
- ✅ Allow force pushes: NO
- ✅ Allow deletions: NO

### Dev Branch Protection

**Settings → Branches → Branch protection rules → Add rule**

Branch name pattern: `dev`

Enable:
- ✅ Require a pull request before merging
  - ✅ Require approvals (1)
- ✅ Require status checks to pass before merging
  - ✅ Require branches to be up to date before merging
  - Required status checks:
    - `test-core`
    - `test-integration`
    - `build-all`
- ✅ Require conversation resolution before merging
- ✅ Include administrators
- ✅ Restrict who can push to matching branches
  - Nobody (only via PR)
- ✅ Allow force pushes: NO
- ✅ Allow deletions: NO

---

## CI/CD Pipeline

All branches trigger automated testing via GitHub Actions (`.github/workflows/ci-cd.yml`):

### On Push to Any Branch:
1. **Code Quality Checks**
   - ESLint
   - Prettier
   - TypeScript compilation

2. **Unit Tests**
   - Core library tests (17 tests)
   - Component tests (26 tests)

3. **Integration Tests**
   - Context manager (10 tests)
   - AI engine (7 tests)
   - Full app generation (9 tests)

4. **Build Verification**
   - Docker build
   - All components compile

### On Pull Request to Dev/Main:
All above checks PLUS:
5. **Coverage Report**
   - Minimum 80% coverage required
   - Coverage report posted as PR comment

6. **E2E Tests** (for main only)
   - Playwright tests
   - Full application flow

---

## Manual Setup Instructions

### To Set Up Branch Protection (GitHub Web UI):

1. **Navigate to Repository Settings**
   - Go to https://github.com/dayahere/openpilot
   - Click "Settings" tab
   - Click "Branches" in left sidebar

2. **Add Branch Protection Rule for Main**
   - Click "Add rule" or "Add branch protection rule"
   - Branch name pattern: `main`
   - Configure settings as listed above under "Main Branch Protection"
   - Click "Create" or "Save changes"

3. **Add Branch Protection Rule for Dev**
   - Click "Add rule" again
   - Branch name pattern: `dev`
   - Configure settings as listed above under "Dev Branch Protection"
   - Click "Create" or "Save changes"

4. **Verify Configuration**
   - Try to push directly to main: `git push origin main` (should fail)
   - Try to push directly to dev: `git push origin dev` (should fail)
   - Create PR from feature to dev (should work)

---

## Testing Before Merge

### Run All Tests Locally

```bash
# Using Docker (recommended)
docker-compose -f docker-compose.test.yml run --rm test-runner

# With coverage
docker-compose -f docker-compose.test.yml run --rm test-coverage
```

### Build All Components

```bash
# Using Docker
docker-compose build

# Using local PowerShell (requires npm)
.\build-local.ps1 -BuildType all -Coverage
```

### Expected Results

```
✅ Test Suites: 4 passed, 4 total
✅ Tests: 43 passed, 43 total
✅ Coverage: 80%+ for all components
✅ Build: Success
```

---

## Commit Message Convention

Use conventional commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding/updating tests
- `chore`: Maintenance tasks
- `ci`: CI/CD changes

**Examples:**

```bash
git commit -m "feat(chat): add message history feature"
git commit -m "fix(completion): resolve inline completion bug"
git commit -m "test(core): add unit tests for ContextManager"
git commit -m "docs(readme): update installation instructions"
git commit -m "ci(workflow): add coverage reporting"
```

---

## Quick Reference

### Create Feature Branch
```bash
git checkout dev
git pull origin dev
git checkout -b feature/my-feature
```

### Develop and Push
```bash
# Make changes
git add .
git commit -m "feat: description"
git push -u origin feature/my-feature
```

### Merge Feature → Dev
1. Create PR on GitHub
2. Wait for CI/CD ✅
3. Get approval
4. Merge PR
5. Delete feature branch

### Merge Dev → Main (Release)
1. Create PR on GitHub
2. Wait for all tests ✅
3. Get approval
4. Merge PR
5. Tag release
   ```bash
   git tag -a v1.0.0 -m "Release 1.0.0"
   git push origin v1.0.0
   ```

---

## Troubleshooting

### "Protected branch update failed"
- You're trying to push directly to `main` or `dev`
- Solution: Create a feature branch and PR

### "Required status checks must pass"
- Tests are failing in CI/CD
- Solution: Run tests locally, fix issues, push again

### "Review required"
- PR needs approval before merge
- Solution: Request review from team member

### "Branch is out of date"
- Your branch is behind the base branch
- Solution:
  ```bash
  git checkout your-branch
  git pull origin dev
  git push origin your-branch
  ```

---

## Repository Status

- ✅ Git initialized
- ✅ Initial commit created (120 files, 43 tests passing)
- ✅ Branches created: `main`, `dev`, `feature/unit-tests`
- ✅ Remote added: https://github.com/dayahere/openpilot.git
- ✅ All branches pushed to GitHub
- ⏳ Branch protection rules (manual setup required on GitHub)
- ✅ CI/CD workflow configured (`.github/workflows/ci-cd.yml`)

---

## Next Steps

1. **Set up branch protection rules** on GitHub (see Manual Setup Instructions above)
2. **Test the workflow**: Create a test PR from feature branch
3. **Verify CI/CD**: Ensure all tests run automatically
4. **Add CODEOWNERS** file to specify code reviewers
5. **Configure notifications** for PR reviews and CI/CD failures

---

**Last Updated:** October 11, 2025  
**Repository:** https://github.com/dayahere/openpilot  
**All Tests:** ✅ 43/43 PASSING
