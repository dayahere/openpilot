# VSCode Extension Build with Docker

## Build Extension (2-3 minutes)

`powershell
cd i:\openpilot\vscode-extension

# Step 1: Install dependencies
docker run --rm -v ${PWD}:/app -w /app node:20 npm install

# Step 2: Compile TypeScript
docker run --rm -v ${PWD}:/app -w /app node:20 npm run compile

# Step 3: Package VSIX
docker run --rm -v ${PWD}:/app -w /app node:20 npx @vscode/vsce package --allow-star-activation --no-git-tag-version

# Output: *.vsix file in current directory
`

## Install Extension

`powershell
# Find VSIX file
 = Get-ChildItem *.vsix | Select-Object -First 1

# Install
code --install-extension .FullName

# Verify
code --list-extensions | Select-String "openpilot"
`

## Test Extension

1. Press Ctrl+Shift+P
2. Type "OpenPilot"
3. Verify commands appear
4. Test each feature

## Publish to Marketplace (Optional)

`powershell
docker run --rm -v ${PWD}:/app -w /app node:20 npx @vscode/vsce publish
`
