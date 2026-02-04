import { parseIntSafe, parseIdParam, parseIntStrict, validateParams } from '../../utils/validation';

describe('Validation Utils', () => {
    describe('parseIntSafe', () => {
        it('should parse valid integer strings', () => {
            expect(parseIntSafe('123', 0)).toBe(123);
            expect(parseIntSafe('0', 1)).toBe(0);
            expect(parseIntSafe('-5', 0)).toBe(-5);
        });

        it('should return default for invalid strings', () => {
            expect(parseIntSafe('abc', 10)).toBe(10);
            expect(parseIntSafe('', 5)).toBe(5);
            expect(parseIntSafe(undefined, 7)).toBe(7);
        });

        it('should return null when no default provided', () => {
            expect(parseIntSafe('abc')).toBe(null);
            expect(parseIntSafe(undefined)).toBe(null);
        });

        it('should handle float strings by truncating', () => {
            expect(parseIntSafe('12.5', 0)).toBe(12);
            expect(parseIntSafe('99.9', 0)).toBe(99);
        });
    });

    describe('parseIdParam', () => {
        it('should parse valid positive integers', () => {
            expect(parseIdParam('1')).toBe(1);
            expect(parseIdParam('999')).toBe(999);
        });

        it('should return null for invalid or non-positive', () => {
            expect(parseIdParam('0')).toBe(null);
            expect(parseIdParam('-1')).toBe(null);
            expect(parseIdParam('abc')).toBe(null);
            expect(parseIdParam('')).toBe(null);
            expect(parseIdParam(undefined)).toBe(null);
        });
    });

    describe('parseIntStrict', () => {
        it('should parse valid integers', () => {
            expect(parseIntStrict('123', 'testField')).toBe(123);
            expect(parseIntStrict('0', 'testField')).toBe(0);
        });

        it('should throw for undefined value', () => {
            expect(() => parseIntStrict(undefined, 'userId')).toThrow('userId is required');
        });

        it('should throw for invalid number', () => {
            expect(() => parseIntStrict('abc', 'userId')).toThrow('userId must be a valid number');
        });
    });

    describe('validateParams', () => {
        it('should return empty array for valid params', () => {
            const params = { id: '1', name: 'test' };
            const errors = validateParams(params, ['id', 'name']);
            expect(errors).toEqual([]);
        });

        it('should return errors for missing required params', () => {
            const params = { id: '1' };
            const errors = validateParams(params, ['id', 'name']);
            expect(errors).toHaveLength(1);
            expect(errors[0]).toEqual({ field: 'name', message: 'name is required' });
        });

        it('should validate ID fields as positive integers', () => {
            const params = { userId: '0' };
            const errors = validateParams(params, ['userId']);
            expect(errors).toHaveLength(1);
            expect(errors[0].message).toContain('positive number');
        });
    });
});
