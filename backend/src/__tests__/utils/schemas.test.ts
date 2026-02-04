import { z } from 'zod';
import {
    registerSchema,
    loginSchema,
    goalsSchema,
    exerciseTrackingSchema,
    mealTrackingSchema,
    weightTrackingSchema,
    waterTrackingSchema,
} from '../../utils/schemas';

describe('Zod Validation Schemas', () => {
    describe('registerSchema', () => {
        it('should validate correct registration data', () => {
            const validData = {
                username: 'testuser',
                email: 'test@example.com',
                password: 'password123',
            };
            expect(() => registerSchema.parse(validData)).not.toThrow();
        });

        it('should reject short username', () => {
            const invalidData = {
                username: 'ab',
                email: 'test@example.com',
                password: 'password123',
            };
            const result = registerSchema.safeParse(invalidData);
            expect(result.success).toBe(false);
        });

        it('should reject invalid email', () => {
            const invalidData = {
                username: 'testuser',
                email: 'invalid-email',
                password: 'password123',
            };
            const result = registerSchema.safeParse(invalidData);
            expect(result.success).toBe(false);
        });

        it('should reject short password', () => {
            const invalidData = {
                username: 'testuser',
                email: 'test@example.com',
                password: '12345',
            };
            const result = registerSchema.safeParse(invalidData);
            expect(result.success).toBe(false);
        });
    });

    describe('loginSchema', () => {
        it('should validate correct login data', () => {
            const validData = {
                email: 'test@example.com',
                password: 'password123',
            };
            expect(() => loginSchema.parse(validData)).not.toThrow();
        });

        it('should reject empty password', () => {
            const invalidData = {
                email: 'test@example.com',
                password: '',
            };
            const result = loginSchema.safeParse(invalidData);
            expect(result.success).toBe(false);
        });
    });

    describe('goalsSchema', () => {
        it('should validate correct goals data', () => {
            const validData = {
                calories_goal: 2000,
                protein_goal: 150,
                carbs_goal: 250,
                fat_goal: 70,
                workouts_per_week: 4,
            };
            expect(() => goalsSchema.parse(validData)).not.toThrow();
        });

        it('should reject calories below minimum', () => {
            const invalidData = {
                calories_goal: 500,
            };
            const result = goalsSchema.safeParse(invalidData);
            expect(result.success).toBe(false);
        });

        it('should allow partial updates', () => {
            const partialData = {
                calories_goal: 2500,
            };
            expect(() => goalsSchema.parse(partialData)).not.toThrow();
        });
    });

    describe('exerciseTrackingSchema', () => {
        it('should validate correct exercise tracking data', () => {
            const validData = {
                exercise_id: 1,
                duration: 30,
                calories_burned: 200,
                sets: 3,
                reps: 12,
            };
            expect(() => exerciseTrackingSchema.parse(validData)).not.toThrow();
        });

        it('should require exercise_id', () => {
            const invalidData = {
                duration: 30,
            };
            const result = exerciseTrackingSchema.safeParse(invalidData);
            expect(result.success).toBe(false);
        });
    });

    describe('weightTrackingSchema', () => {
        it('should validate correct weight data', () => {
            const validData = {
                weight: 70.5,
                notes: 'Morning weight',
            };
            expect(() => weightTrackingSchema.parse(validData)).not.toThrow();
        });

        it('should reject weight below minimum', () => {
            const invalidData = {
                weight: 10,
            };
            const result = weightTrackingSchema.safeParse(invalidData);
            expect(result.success).toBe(false);
        });
    });

    describe('waterTrackingSchema', () => {
        it('should validate correct water intake data', () => {
            const validData = {
                amount_ml: 250,
                notes: 'After workout',
            };
            expect(() => waterTrackingSchema.parse(validData)).not.toThrow();
        });

        it('should reject zero amount', () => {
            const invalidData = {
                amount_ml: 0,
            };
            const result = waterTrackingSchema.safeParse(invalidData);
            expect(result.success).toBe(false);
        });
    });
});
