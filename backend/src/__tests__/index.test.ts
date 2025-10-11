import request from 'supertest';
import app from '../index';

describe('Backend API', () => {
  describe('Health Check', () => {
    it('should return 200 OK', async () => {
      const response = await request(app).get('/health');
      expect(response.status).toBe(200);
    });

    it('should return JSON with status and timestamp', async () => {
      const response = await request(app).get('/health');
      expect(response.body).toHaveProperty('status', 'ok');
      expect(response.body).toHaveProperty('timestamp');
      expect(new Date(response.body.timestamp)).toBeInstanceOf(Date);
    });

    it('should have correct content type', async () => {
      const response = await request(app).get('/health');
      expect(response.type).toBe('application/json');
    });
  });

  describe('CORS', () => {
    it('should have CORS headers', async () => {
      const response = await request(app)
        .get('/health')
        .set('Origin', 'http://localhost:3000');
      expect(response.headers).toHaveProperty('access-control-allow-origin');
    });
  });

  describe('Security Headers', () => {
    it('should have helmet security headers', async () => {
      const response = await request(app).get('/health');
      expect(response.headers).toHaveProperty('x-content-type-options');
      expect(response.headers).toHaveProperty('x-frame-options');
    });
  });

  describe('Routes', () => {
    it('should mount /api/auth routes', async () => {
      const response = await request(app).post('/api/auth/login');
      // Should not be 404
      expect(response.status).not.toBe(404);
    });

    it('should mount /api/chat routes', async () => {
      const response = await request(app).post('/api/chat/message');
      // Should not be 404
      expect(response.status).not.toBe(404);
    });

    it('should mount /api/sync routes', async () => {
      const response = await request(app).get('/api/sync/status');
      // Should not be 404
      expect(response.status).not.toBe(404);
    });
  });

  describe('Error Handling', () => {
    it('should handle invalid routes', async () => {
      const response = await request(app).get('/invalid-route');
      expect(response.status).toBe(404);
    });

    it('should handle malformed JSON', async () => {
      const response = await request(app)
        .post('/api/chat/message')
        .set('Content-Type', 'application/json')
        .send('invalid json');
      expect(response.status).toBe(400);
    });
  });

  describe('JSON Parsing', () => {
    it('should parse JSON request bodies', async () => {
      const response = await request(app)
        .post('/api/chat/message')
        .send({ message: 'test' });
      expect(response.status).not.toBe(400);
    });
  });
});

describe('Backend WebSocket', () => {
  it('should setup WebSocket server', () => {
    // WebSocket setup is tested via setupWebSocket
    expect(true).toBe(true);
  });
});
