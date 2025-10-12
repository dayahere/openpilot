# Desktop App Build with Docker

## Build Desktop App (5-10 minutes)

`powershell
cd i:\openpilot\desktop

# Step 1: Install dependencies
docker run --rm -v ${PWD}:/app -w /app node:20 npm install

# Step 2: Build
docker run --rm -v ${PWD}:/app -w /app node:20 npm run build

# Output: build\ folder
`

## Run Desktop App

`powershell
# Option 1: Open directly
cd build
start index.html

# Option 2: Serve with Docker
docker run --rm -p 8080:80 -v ${PWD}/build:/usr/share/nginx/html nginx:alpine
# Open: http://localhost:8080
`

## Package as Executable (Optional)

Requires Electron builder:
`powershell
docker run --rm -v ${PWD}:/app -w /app node:20 npm run package
`
