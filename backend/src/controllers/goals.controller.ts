import { Request, Response } from 'express';
import { goalsService } from '../services/goals.service';
import { ApiResponse } from '../utils/response';
import { parseIdParam } from '../utils/validation';

export class GoalsController {
    // GET /api/users/:userId/goals
    async getUserGoals(req: Request, res: Response): Promise<void> {
        try {
            const userId = parseIdParam(req.params.userId);
            if (!userId) {
                ApiResponse.badRequest(res, 'Invalid user ID');
                return;
            }

            const goals = await goalsService.getOrCreateGoals(userId);
            ApiResponse.success(res, goals);
        } catch (error) {
            console.error('❌ Get user goals error:', error);
            ApiResponse.serverError(res, 'Failed to get user goals');
        }
    }

    // PUT /api/users/:userId/goals
    async updateUserGoals(req: Request, res: Response): Promise<void> {
        try {
            const userId = parseIdParam(req.params.userId);
            if (!userId) {
                ApiResponse.badRequest(res, 'Invalid user ID');
                return;
            }

            const { calories_goal, protein_goal, carbs_goal, fat_goal, workouts_per_week } = req.body;

            // Validation
            if (calories_goal !== undefined && (calories_goal < 1000 || calories_goal > 10000)) {
                ApiResponse.badRequest(res, 'Calories goal must be between 1000 and 10000');
                return;
            }

            const updatedGoals = await goalsService.updateUserGoals(userId, {
                calories_goal,
                protein_goal,
                carbs_goal,
                fat_goal,
                workouts_per_week
            });

            if (!updatedGoals) {
                ApiResponse.notFound(res, 'User goals');
                return;
            }

            ApiResponse.success(res, updatedGoals, 'Goals updated successfully');
        } catch (error) {
            console.error('❌ Update user goals error:', error);
            ApiResponse.serverError(res, 'Failed to update user goals');
        }
    }
}

export const goalsController = new GoalsController();
