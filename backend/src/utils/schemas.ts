import { z } from 'zod';
import { Request, Response, NextFunction } from 'express';

/**
 * Validation schemas for API requests using Zod
 * Provides type-safe validation with automatic TypeScript inference
 */

// Flexible datetime that accepts ISO8601 strings
const flexibleDateTime = z.string().refine(
    (val) => !isNaN(Date.parse(val)),
    { message: 'Invalid datetime format' }
).optional();

// ============ AUTH SCHEMAS ============

export const registerSchema = z.object({
    username: z.string()
        .min(3, 'Username must be at least 3 characters')
        .max(50, 'Username must be less than 50 characters'),
    email: z.string()
        .email('Invalid email format'),
    password: z.string()
        .min(6, 'Password must be at least 6 characters')
        .max(100, 'Password must be less than 100 characters'),
    gender: z.enum(['male', 'female']).optional().nullable(),
    date_of_birth: z.string().datetime().optional().nullable().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().nullable()),
    height: z.number().min(50).max(300).optional().nullable(),
    weight: z.number().min(20).max(500).optional().nullable(),
    goal: z.string().max(200).optional().nullable(),
    preferred_language_id: z.number().int().min(1).optional().nullable(),
});

export const loginSchema = z.object({
    email: z.string().email('Invalid email format'),
    password: z.string().min(1, 'Password is required'),
});

export const updateUserSchema = z.object({
    username: z.string().min(3).max(50).optional(),
    email: z.string().email().optional(),
    gender: z.enum(['male', 'female', 'other']).optional(),
    date_of_birth: z.string().optional(),
    height: z.number().min(50).max(300).optional(),
    weight: z.number().min(20).max(500).optional(),
    goal: z.enum(['maintain_weight', 'build_muscle', 'lose_weight']).optional(),
    body_goals: z.string().max(500).optional(),
    activity_level: z.enum(['sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extremely_active']).optional(),
    preferred_language_id: z.number().int().min(1).optional(),
    onboarding_completed: z.boolean().optional(),
});

// ============ TRACKING SCHEMAS ============

export const exerciseTrackingSchema = z.object({
    exercise_id: z.number().int().positive('Exercise ID must be positive'),
    duration: z.number().int().min(1).max(600).optional(),
    calories_burned: z.number().min(0).max(10000).optional(),
    sets: z.number().int().min(1).max(50).optional(),
    reps: z.number().int().min(1).max(100).optional(),
    weight: z.number().min(0).max(1000).optional(),
    notes: z.string().max(500).optional(),
    tracked_at: z.string().datetime().optional(),
});

export const mealTrackingSchema = z.object({
    recipe_id: z.number().int().positive().optional(),
    food_id: z.number().int().positive().optional(),
    meal_type: z.enum(['breakfast', 'lunch', 'dinner', 'snack']).optional(),
    meal_name: z.string().max(200).optional(),
    calories: z.number().min(0).max(10000).optional(),
    protein: z.number().min(0).max(1000).optional(),
    carbs: z.number().min(0).max(1000).optional(),
    fat: z.number().min(0).max(1000).optional(),
    notes: z.string().max(500).nullable().optional(),
    quantity: z.number().min(0.1).max(100).optional(),
    date: z.string().datetime().optional().or(z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional()),
});

export const weightTrackingSchema = z.object({
    weight: z.number().min(20, 'Weight must be at least 20 kg').max(500, 'Weight must be less than 500 kg'),
    notes: z.string().max(500).nullable().optional(),
    tracked_at: flexibleDateTime,
});

export const waterTrackingSchema = z.object({
    amount_ml: z.number().int().min(1, 'Amount must be at least 1 ml').max(10000, 'Amount must be less than 10000 ml'),
    notes: z.string().max(500).nullable().optional(),
    tracked_at: flexibleDateTime,
});

// ============ GOALS SCHEMA ============

export const goalsSchema = z.object({
    calories_goal: z.number().int().min(1000, 'Calories goal must be at least 1000').max(10000, 'Calories goal must be less than 10000').optional(),
    protein_goal: z.number().int().min(10).max(500).optional(),
    carbs_goal: z.number().int().min(10).max(1000).optional(),
    fat_goal: z.number().int().min(10).max(500).optional(),
    workouts_per_week: z.number().int().min(1).max(14).optional(),
});

// ============ PLAN SCHEMAS ============

export const createPlanSchema = z.object({
    name: z.string().max(255).optional(),
    plan_type: z.enum(['workout', 'meal', 'combined']).optional(),
    description: z.string().max(500).optional().nullable(),
    schedule_days: z.string().max(20).optional().nullable(), // "1,3,5" format
});

export const addPlanDetailSchema = z.object({
    exercise_id: z.number().int().positive().optional(),
    recipe_id: z.number().int().positive().optional(),
    sets: z.number().int().min(1).max(50).optional(),
    reps: z.number().int().min(1).max(100).optional(),
    rest_duration: z.number().int().min(0).max(600).optional(),
    order_index: z.number().int().min(0).optional(),
});

// ============ WORKOUT SESSION SCHEMAS ============

export const startSessionSchema = z.object({
    plan_id: z.number().int().positive().nullable().optional(),
    exercise_id: z.number().int().positive().nullable().optional(), // Can be null when starting from plan
    name: z.string().max(100).optional(),
});

export const updateExerciseProgressSchema = z.object({
    sets_completed: z.number().int().min(0).max(50).optional().nullable(),
    reps_completed: z.string().max(100).optional().nullable(),
    weight_used: z.string().max(100).optional().nullable(),
    notes: z.string().max(500).optional().nullable(),
});

// ============ FAVORITES SCHEMAS ============

export const addFavoriteFoodSchema = z.object({
    food_id: z.number().int().positive('food_id is required'),
    notes: z.string().max(500).optional(),
});

export const addFavoriteRecipeSchema = z.object({
    recipe_id: z.number().int().positive('recipe_id is required'),
    notes: z.string().max(500).optional(),
});

// ============ VALIDATION MIDDLEWARE ============

/**
 * Validate request body against a Zod schema
 */
export const validateBody = <T extends z.ZodSchema>(schema: T) => {
    return (req: Request, res: Response, next: NextFunction): void => {
        try {
            const result = schema.safeParse(req.body);

            if (!result.success) {
                const errors = result.error.issues.map((issue: z.ZodIssue) => ({
                    field: issue.path.join('.'),
                    message: issue.message,
                }));

                console.log('❌ Validation failed:', JSON.stringify({
                    body: req.body,
                    errors: errors,
                }));

                res.status(422).json({
                    success: false,
                    code: 'VALIDATION_ERROR',
                    message: 'Request validation failed',
                    errors,
                });
                return;
            }

            req.body = result.data;
            next();
        } catch (error) {
            console.error('❌ Validation middleware error:', error);
            res.status(500).json({
                success: false,
                message: 'Validation error',
            });
        }
    };
};

/**
 * Validate request query against a Zod schema
 */
export const validateQuery = <T extends z.ZodSchema>(schema: T) => {
    return (req: Request, res: Response, next: NextFunction): void => {
        try {
            const result = schema.safeParse(req.query);

            if (!result.success) {
                const errors = result.error.issues.map((issue: z.ZodIssue) => ({
                    field: issue.path.join('.'),
                    message: issue.message,
                }));

                res.status(422).json({
                    success: false,
                    code: 'VALIDATION_ERROR',
                    message: 'Query validation failed',
                    errors,
                });
                return;
            }

            // Merge validated data back into query (type-safe way)
            Object.assign(req.query, result.data);
            next();
        } catch (error) {
            console.error('❌ Query validation middleware error:', error);
            res.status(500).json({
                success: false,
                message: 'Validation error',
            });
        }
    };
};

// ============ TYPE EXPORTS ============

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type UpdateUserInput = z.infer<typeof updateUserSchema>;
export type ExerciseTrackingInput = z.infer<typeof exerciseTrackingSchema>;
export type MealTrackingInput = z.infer<typeof mealTrackingSchema>;
export type WeightTrackingInput = z.infer<typeof weightTrackingSchema>;
export type WaterTrackingInput = z.infer<typeof waterTrackingSchema>;
export type GoalsInput = z.infer<typeof goalsSchema>;
export type CreatePlanInput = z.infer<typeof createPlanSchema>;
export type AddPlanDetailInput = z.infer<typeof addPlanDetailSchema>;
export type StartSessionInput = z.infer<typeof startSessionSchema>;
export type UpdateExerciseProgressInput = z.infer<typeof updateExerciseProgressSchema>;
