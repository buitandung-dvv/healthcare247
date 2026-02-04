import { Response } from 'express';
import { workoutSessionService } from '../services/workout-session.service';
import { AuthRequest } from '../middleware/auth';
import { ApiResponse } from '../utils/response';
import { parseIntSafe, parseIdParam } from '../utils/validation';

export class WorkoutSessionController {
    // Start session
    async startSession(req: AuthRequest, res: Response): Promise<void> {
        try {
            if (!req.userId) {
                ApiResponse.unauthorized(res);
                return;
            }

            const { plan_id, exercise_id, name } = req.body;

            const session = await workoutSessionService.startSession(
                req.userId,
                plan_id,
                exercise_id,
                name
            );

            ApiResponse.created(res, session, 'Workout session started');
        } catch (error) {
            console.error('❌ Start session error:', error);
            ApiResponse.serverError(res, 'Failed to start workout session');
        }
    }

    // Get active session
    async getActiveSession(req: AuthRequest, res: Response): Promise<void> {
        try {
            if (!req.userId) {
                ApiResponse.unauthorized(res);
                return;
            }

            const session = await workoutSessionService.getActiveSession(req.userId);
            ApiResponse.success(res, session);
        } catch (error) {
            console.error('❌ Get active session error:', error);
            ApiResponse.serverError(res, 'Failed to get active session');
        }
    }

    // Get session by ID
    async getSessionById(req: AuthRequest, res: Response): Promise<void> {
        try {
            const sessionId = parseIdParam(req.params.id);
            if (!sessionId) {
                ApiResponse.badRequest(res, 'Invalid session ID');
                return;
            }
            const languageId = parseIntSafe(req.query.language_id as string, 1) ?? 1;

            const session = await workoutSessionService.getSessionById(sessionId, languageId);

            if (!session) {
                ApiResponse.notFound(res, 'Session');
                return;
            }

            // Check if session belongs to user
            if (req.userId && session.user_id !== req.userId) {
                ApiResponse.error(res, 403, 'Forbidden');
                return;
            }

            ApiResponse.success(res, session);
        } catch (error) {
            console.error('❌ Get session by ID error:', error);
            ApiResponse.serverError(res, 'Failed to get session');
        }
    }

    // Update exercise progress
    async updateExerciseProgress(req: AuthRequest, res: Response): Promise<void> {
        try {
            const sessionId = parseIdParam(req.params.id);
            const exerciseId = parseIdParam(req.params.exerciseId);

            if (!sessionId || !exerciseId) {
                ApiResponse.badRequest(res, 'Invalid session or exercise ID');
                return;
            }

            const { sets_completed, reps_completed, weight_used, notes } = req.body;

            const detail = await workoutSessionService.updateExerciseProgress(
                sessionId,
                exerciseId,
                sets_completed,
                reps_completed,
                weight_used,
                notes
            );

            if (!detail) {
                ApiResponse.notFound(res, 'Exercise detail in session');
                return;
            }

            ApiResponse.success(res, detail, 'Progress updated');
        } catch (error) {
            console.error('❌ Update exercise progress error:', error);
            ApiResponse.serverError(res, 'Failed to update progress');
        }
    }

    // Complete session
    async completeSession(req: AuthRequest, res: Response): Promise<void> {
        try {
            const sessionId = parseIdParam(req.params.id);
            if (!sessionId) {
                ApiResponse.badRequest(res, 'Invalid session ID');
                return;
            }

            const { notes } = req.body;

            const session = await workoutSessionService.completeSession(sessionId, notes);

            if (!session) {
                ApiResponse.notFound(res, 'Session (or already completed)');
                return;
            }

            ApiResponse.success(res, session, 'Session completed');
        } catch (error) {
            console.error('❌ Complete session error:', error);
            ApiResponse.serverError(res, 'Failed to complete session');
        }
    }

    // Cancel session
    async cancelSession(req: AuthRequest, res: Response): Promise<void> {
        try {
            const sessionId = parseIdParam(req.params.id);
            if (!sessionId) {
                ApiResponse.badRequest(res, 'Invalid session ID');
                return;
            }

            const cancelled = await workoutSessionService.cancelSession(sessionId);

            if (!cancelled) {
                ApiResponse.notFound(res, 'Session (or already completed)');
                return;
            }

            res.status(204).send();
        } catch (error) {
            console.error('❌ Cancel session error:', error);
            ApiResponse.serverError(res, 'Failed to cancel session');
        }
    }

    // Get session history
    async getSessionHistory(req: AuthRequest, res: Response): Promise<void> {
        try {
            if (!req.userId) {
                ApiResponse.unauthorized(res);
                return;
            }

            const page = parseIntSafe(req.query.page as string, 1) ?? 1;
            const limit = parseIntSafe(req.query.limit as string, 20) ?? 20;

            const result = await workoutSessionService.getSessionHistory(req.userId, page, limit);

            res.json({
                success: true,
                data: result.sessions,
                pagination: {
                    page,
                    limit,
                    total: result.total,
                    totalPages: Math.ceil(result.total / limit),
                },
            });
        } catch (error) {
            console.error('❌ Get session history error:', error);
            ApiResponse.serverError(res, 'Failed to get history');
        }
    }
}

export const workoutSessionController = new WorkoutSessionController();
