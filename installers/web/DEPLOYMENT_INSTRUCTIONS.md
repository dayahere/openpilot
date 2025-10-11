# OpenPilot Web App Deployment Instructions

## Prerequisites
- Node.js 18+
- npm 9+
- Web server (nginx, Apache, or hosting service)

## Build Steps

1. **Install Dependencies**
   ```bash
   cd web
   npm install
   ```

2. **Build for Production**
   ```bash
   npm run build
   ```
   Output: uild/ directory with optimized static files

3. **Test Build Locally**
   ```bash
   npm install -g serve
   serve -s build
   ```
   Open: http://localhost:3000

## Deployment Options

### Option 1: Static Hosting (Vercel, Netlify)

**Vercel:**
```bash
npm install -g vercel
vercel --prod
```

**Netlify:**
```bash
npm install -g netlify-cli
netlify deploy --prod
```

### Option 2: Traditional Web Server (nginx)

1. **Copy build files to server**
   ```bash
   scp -r build/* user@server:/var/www/openpilot/
   ```

2. **Configure nginx**
   ```nginx
   server {
       listen 80;
       server_name openpilot.example.com;
       root /var/www/openpilot;
       index index.html;

       location / {
           try_files \ /index.html;
       }

       location /static {
           expires 1y;
           add_header Cache-Control "public, immutable";
       }
   }
   ```

3. **Restart nginx**
   ```bash
   sudo systemctl restart nginx
   ```

### Option 3: Docker

1. **Build Docker image**
   ```bash
   docker build -t openpilot-web .
   ```

2. **Run container**
   ```bash
   docker run -p 80:80 openpilot-web
   ```

### Option 4: AWS S3 + CloudFront

1. **Upload to S3**
   ```bash
   aws s3 sync build/ s3://openpilot-web/
   ```

2. **Configure CloudFront distribution**
   - Origin: S3 bucket
   - Default root object: index.html
   - Error pages: 404 â†’ index.html

## Testing

1. **Run Development Server**
   ```bash
   npm start
   ```
   Open: http://localhost:3000

2. **Run Tests**
   ```bash
   npm test
   ```

3. **Check Production Build**
   ```bash
   npm run build
   serve -s build
   ```

## Environment Variables

Create .env.production:
```
REACT_APP_API_URL=https://api.openpilot.example.com
REACT_APP_WEBSOCKET_URL=wss://api.openpilot.example.com
REACT_APP_VERSION=1.0.0
```

## Features

- âœ… Progressive Web App (PWA)
- âœ… Service Worker for offline support
- âœ… Responsive design
- âœ… Code splitting for performance
- âœ… Optimized for production

---
**Package:** OpenPilot Web App  
**Version:** 1.0.0  
**Framework:** React + PWA  
**Browser Support:** Chrome 90+, Firefox 88+, Safari 14+, Edge 90+
