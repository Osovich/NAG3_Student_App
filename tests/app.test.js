const request = require('supertest');
const app = require('../app');

describe('NAG3 Student App', () => {
  describe('GET /', () => {
    it('should return app information', async () => {
      const response = await request(app).get('/');
      expect(response.status).toBe(200);
      expect(response.body.message).toBe('NAG3 Student App - DevOps Pipeline Demo');
      expect(response.body.version).toBe('1.0.0');
    });
  });

  describe('GET /health', () => {
    it('should return health status', async () => {
      const response = await request(app).get('/health');
      expect(response.status).toBe(200);
      expect(response.body.status).toBe('healthy');
      expect(response.body.uptime).toBeDefined();
    });
  });

  describe('GET /api/students', () => {
    it('should return all students', async () => {
      const response = await request(app).get('/api/students');
      expect(response.status).toBe(200);
      expect(response.body.students).toHaveLength(4);
      expect(response.body.count).toBe(4);
    });
  });

  describe('GET /api/students/:id', () => {
    it('should return specific student', async () => {
      const response = await request(app).get('/api/students/1');
      expect(response.status).toBe(200);
      expect(response.body.name).toBe('Alice Johnson');
      expect(response.body.grade).toBe('A');
    });

    it('should return 404 for non-existent student', async () => {
      const response = await request(app).get('/api/students/999');
      expect(response.status).toBe(404);
      expect(response.body.error).toBe('Student not found');
    });
  });
});
