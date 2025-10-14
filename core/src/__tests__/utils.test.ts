import { generateId, parseError } from '../utils';

describe('Utils', () => {
  describe('generateId', () => {
    it('returns UUID v4 with proper typing', () => {
      const id = generateId();
      
      expect(typeof id).toBe('string');
      expect(id).toMatch(
        /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
      );
    });

    it('generates unique IDs', () => {
      const id1 = generateId();
      const id2 = generateId();
      const id3 = generateId();

      expect(id1).not.toBe(id2);
      expect(id2).not.toBe(id3);
      expect(id1).not.toBe(id3);
    });

    it('returns string type for all IDs', () => {
      for (let i = 0; i < 10; i++) {
        const id = generateId();
        expect(typeof id).toBe('string');
        expect(id.length).toBeGreaterThan(0);
      }
    });
  });

  describe('parseError', () => {
    it('handles Error instances', () => {
      const error = new Error('Test error message');
      const result = parseError(error);

      expect(result).toContain('Test error message');
    });

    it('handles Error with stack trace', () => {
      const error = new Error('Error with stack');
      const result = parseError(error);

      expect(result).toContain('Error with stack');
      // Stack should be included if available
      if (error.stack) {
        expect(result).toContain('Error with stack');
      }
    });

    it('handles string errors', () => {
      const error = 'String error message';
      const result = parseError(error);

      expect(result).toBe('String error message');
    });

    it('handles non-Error objects', () => {
      const error = { code: 'ERR_CODE', message: 'Custom error' };
      const result = parseError(error);

      expect(typeof result).toBe('string');
      expect(result).toContain('ERR_CODE');
      expect(result).toContain('Custom error');
    });

    it('handles null and undefined', () => {
      expect(parseError(null)).toBe('Unknown error');
      expect(parseError(undefined)).toBe('Unknown error');
    });

    it('handles numbers', () => {
      const result = parseError(404);
      expect(result).toContain('404');
    });

    it('handles arrays', () => {
      const error = ['error1', 'error2'];
      const result = parseError(error);
      
      expect(typeof result).toBe('string');
      expect(result).toContain('error1');
      expect(result).toContain('error2');
    });
  });
});
