import { Response } from 'express';
import { trackingService } from '../services/tracking.service';
import { goalsService } from '../services/goals.service';
import { AuthRequest } from '../middleware/auth';
import { parseIntSafe } from '../utils/validation';
import { logger } from '../utils/logger';
import { ApiResponse } from '../utils/response';

export class TrackingController {
  // ============ EXERCISE TRACKING ============

  // Log exercise
  async logExercise(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        ApiResponse.unauthorized(res);
        return;
      }

      const { exercise_id, duration, calories_burned, sets, reps, weight, notes, tracked_at } = req.body;

      if (!exercise_id) {
        ApiResponse.badRequest(res, 'exercise_id is required');
        return;
      }

      const tracking = await trackingService.logExercise(
        req.userId,
        exercise_id,
        duration,
        calories_burned,
        sets,
        reps,
        weight,
        notes,
        tracked_at ? new Date(tracked_at) : undefined
      );

      ApiResponse.created(res, tracking, 'Exercise logged successfully');
    } catch (error) {
      console.error('❌ Log exercise error:', error);
      ApiResponse.serverError(res, 'Failed to log exercise');
    }
  }

  // Get exercise tracking
  async getExerciseTracking(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        ApiResponse.unauthorized(res);
        return;
      }

      const startDate = req.query.start_date ? new Date(req.query.start_date as string) : undefined;
      const endDate = req.query.end_date ? new Date(req.query.end_date as string) : undefined;

      const tracking = await trackingService.getExerciseTracking(req.userId, startDate, endDate);
      ApiResponse.success(res, tracking);
    } catch (error) {
      console.error('❌ Get exercise tracking error:', error);
      ApiResponse.serverError(res, 'Failed to get exercise tracking');
    }
  }

  // Delete exercise tracking
  async deleteExerciseTracking(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        ApiResponse.unauthorized(res);
        return;
      }

      const { exercise_id, tracked_at } = req.body;

      if (!exercise_id || !tracked_at) {
        ApiResponse.badRequest(res, 'exercise_id and tracked_at are required');
        return;
      }

      const deleted = await trackingService.deleteExerciseTracking(
        req.userId,
        exercise_id,
        new Date(tracked_at)
      );

      if (!deleted) {
        ApiResponse.notFound(res, 'Exercise tracking');
        return;
      }

      res.status(204).send();
    } catch (error) {
      console.error('❌ Delete exercise tracking error:', error);
      ApiResponse.serverError(res, 'Failed to delete tracking');
    }
  }

  // ============ MEAL TRACKING ============

  // Log meal with nutrition info
  async logMeal(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        ApiResponse.unauthorized(res);
        return;
      }

      const {
        recipe_id,
        food_id,
        meal_type,
        meal_name,
        calories,
        protein,
        carbs,
        fat,
        notes,
        quantity,
        date
      } = req.body;

      logger.debug('Log meal request', { userId: req.userId, recipe_id, food_id, meal_type, meal_name, calories, quantity, date });

      const tracking = await trackingService.logMeal(
        req.userId,
        recipe_id,
        food_id,
        meal_type,
        meal_name,
        calories,
        protein,
        carbs,
        fat,
        notes,
        quantity,
        date ? new Date(date) : undefined
      );

      logger.debug('Log meal success', { user_id: tracking.user_id });
      ApiResponse.created(res, tracking, 'Meal logged successfully');
    } catch (error) {
      logger.error('Log meal failed', error);
      console.error('❌ Log meal error:', error);
      ApiResponse.serverError(res, 'Failed to log meal');
    }
  }

  // Get meal tracking
  async getMealTracking(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        ApiResponse.unauthorized(res);
        return;
      }

      const startDate = req.query.start_date ? new Date(req.query.start_date as string) : undefined;
      const endDate = req.query.end_date ? new Date(req.query.end_date as string) : undefined;

      logger.debug('Get meals request', { userId: req.userId, startDate, endDate });

      const tracking = await trackingService.getMealTracking(req.userId, startDate, endDate);
      logger.debug('Get meals success', { count: tracking.length });
      ApiResponse.success(res, tracking);
    } catch (error) {
      logger.error('Get meals failed', error);
      console.error('❌ Get meal tracking error:', error);
      ApiResponse.serverError(res, 'Failed to get meal tracking');
    }
  }

  // Delete meal tracking
  async deleteMealTracking(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        ApiResponse.unauthorized(res);
        return;
      }

      const { tracked_date, meal_type, created_at } = req.body;

      if (!tracked_date || !meal_type || !created_at) {
        ApiResponse.badRequest(res, 'tracked_date, meal_type, and created_at are required');
        return;
      }

      const deleted = await trackingService.deleteMealTracking(
        req.userId,
        new Date(tracked_date),
        meal_type,
        new Date(created_at)
      );

      if (!deleted) {
        ApiResponse.notFound(res, 'Meal tracking');
        return;
      }

      res.status(204).send();
    } catch (error) {
      console.error('❌ Delete meal tracking error:', error);
      ApiResponse.serverError(res, 'Failed to delete tracking');
    }
  }

  // ============ WEIGHT TRACKING ============

  // Log weight
  async logWeight(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        ApiResponse.unauthorized(res);
        return;
      }

      const { weight, notes, tracked_at } = req.body;

      if (!weight || weight <= 0) {
        ApiResponse.badRequest(res, 'Valid weight is required');
        return;
      }

      const tracking = await trackingService.logWeight(
        req.userId,
        weight,
        notes,
        tracked_at ? new Date(tracked_at) : undefined
      );

      ApiResponse.created(res, tracking, 'Weight logged successfully');
    } catch (error) {
      console.error('❌ Log weight error:', error);
      ApiResponse.serverError(res, 'Failed to log weight');
    }
  }

  // Get weight history
  async getWeightHistory(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        ApiResponse.unauthorized(res);
        return;
      }

      const startDate = req.query.start_date ? new Date(req.query.start_date as string) : undefined;
      const endDate = req.query.end_date ? new Date(req.query.end_date as string) : undefined;
      const limit = parseIntSafe(req.query.limit as string, 30) ?? 30;

      const history = await trackingService.getWeightHistory(req.userId, startDate, endDate, limit);
      ApiResponse.success(res, history);
    } catch (error) {
      console.error('❌ Get weight history error:', error);
      ApiResponse.serverError(res, 'Failed to get weight history');
    }
  }

  // Delete weight tracking
  async deleteWeightTracking(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        ApiResponse.unauthorized(res);
        return;
      }

      const { tracked_at } = req.body;

      if (!tracked_at) {
        ApiResponse.badRequest(res, 'tracked_at is required');
        return;
      }

      const deleted = await trackingService.deleteWeightTracking(
        req.userId,
        new Date(tracked_at)
      );

      if (!deleted) {
        ApiResponse.notFound(res, 'Weight tracking');
        return;
      }

      res.status(204).send();
    } catch (error) {
      console.error('❌ Delete weight tracking error:', error);
      ApiResponse.serverError(res, 'Failed to delete weight tracking');
    }
  }

  // ============ WATER TRACKING ============

  // Log water intake
  async logWater(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        ApiResponse.unauthorized(res);
        return;
      }

      const { amount_ml, notes, tracked_at } = req.body;

      if (!amount_ml || amount_ml <= 0) {
        ApiResponse.badRequest(res, 'Valid amount_ml is required');
        return;
      }

      const tracking = await trackingService.logWater(
        req.userId,
        amount_ml,
        notes,
        tracked_at ? new Date(tracked_at) : undefined
      );

      ApiResponse.created(res, tracking, 'Water intake logged successfully');
    } catch (error) {
      console.error('❌ Log water error:', error);
      ApiResponse.serverError(res, 'Failed to log water intake');
    }
  }

  // Get water history
  async getWaterHistory(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        ApiResponse.unauthorized(res);
        return;
      }

      const startDate = req.query.start_date ? new Date(req.query.start_date as string) : undefined;
      const endDate = req.query.end_date ? new Date(req.query.end_date as string) : undefined;
      const limit = parseIntSafe(req.query.limit as string, 50) ?? 50;

      const history = await trackingService.getWaterHistory(req.userId, startDate, endDate, limit);
      ApiResponse.success(res, history);
    } catch (error) {
      console.error('❌ Get water history error:', error);
      ApiResponse.serverError(res, 'Failed to get water history');
    }
  }

  // Get daily water intake
  async getDailyWaterIntake(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        ApiResponse.unauthorized(res);
        return;
      }

      const date = req.query.date ? new Date(req.query.date as string) : new Date();

      const data = await trackingService.getDailyWaterIntake(req.userId, date);

      res.json({
        success: true,
        data: {
          total_ml: data.totalMl,
          entries: data.entries,
          goal_ml: data.goal,
          progress: data.goal > 0 ? Math.min(data.totalMl / data.goal, 1) : 0,
        },
      });
    } catch (error) {
      console.error('❌ Get daily water intake error:', error);
      ApiResponse.serverError(res, 'Failed to get daily water intake');
    }
  }

  // Delete water tracking
  async deleteWaterTracking(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        ApiResponse.unauthorized(res);
        return;
      }

      const { tracked_at } = req.body;

      if (!tracked_at) {
        ApiResponse.badRequest(res, 'tracked_at is required');
        return;
      }

      const deleted = await trackingService.deleteWaterTracking(
        req.userId,
        new Date(tracked_at)
      );

      if (!deleted) {
        ApiResponse.notFound(res, 'Water tracking');
        return;
      }

      res.status(204).send();
    } catch (error) {
      console.error('❌ Delete water tracking error:', error);
      ApiResponse.serverError(res, 'Failed to delete water tracking');
    }
  }

  // ============ DASHBOARD ============

  // Get daily stats
  async getDailyStats(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        ApiResponse.unauthorized(res);
        return;
      }

      const date = req.query.date ? new Date(req.query.date as string) : new Date();

      // Get both stats and goals in parallel
      const [stats, goals] = await Promise.all([
        trackingService.getDailyStats(req.userId, date),
        goalsService.getOrCreateGoals(req.userId)
      ]);

      res.json({
        success: true,
        data: {
          ...stats,
          // Include user goals from database
          calories_goal: goals.calories_goal,
          protein_goal: goals.protein_goal,
          carbs_goal: goals.carbs_goal,
          fat_goal: goals.fat_goal,
          workouts_per_week: goals.workouts_per_week,
        },
      });
    } catch (error) {
      console.error('❌ Get daily stats error:', error);
      ApiResponse.serverError(res, 'Failed to get daily stats');
    }
  }

  // Get weekly stats
  async getWeeklyStats(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        ApiResponse.unauthorized(res);
        return;
      }

      const stats = await trackingService.getWeeklyStats(req.userId);
      ApiResponse.success(res, stats);
    } catch (error) {
      console.error('❌ Get weekly stats error:', error);
      ApiResponse.serverError(res, 'Failed to get weekly stats');
    }
  }
}

export const trackingController = new TrackingController();
