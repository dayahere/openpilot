# Web App Build with Docker

## Build Web App (3-5 minutes)

`powershell
cd i:\openpilot\web

# Step 1: Clean install
Remove-Item node_modules -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item package-lock.json -Force -ErrorAction SilentlyContinue

# Step 2: Install dependencies
docker run --rm -v ${PWD}:/app -w /app node:20 npm install

# Step 3: Build production app
docker run --rm -v ${PWD}:/app -w /app node:20 npm run build

# Step 4: Package
Compress-Archive -Path build\* -DestinationPath openpilot-web.zip -Force
`

## Test Web App

`powershell
# Extract and serve
Expand-Archive openpilot-web.zip -DestinationPath web-dist
docker run --rm -p 3000:3000 -v ${PWD}/web-dist:/usr/share/nginx/html nginx:alpine

# Open: http://localhost:3000
`

## Deploy Options

- **Netlify**: Drop build folder
- **Vercel**: `vercel --prod`
- **GitHub Pages**: Push build\ to gh-pages branch
- **Docker**: `docker run -p 80:80 -v ./build:/usr/share/nginx/html nginx:alpine`
