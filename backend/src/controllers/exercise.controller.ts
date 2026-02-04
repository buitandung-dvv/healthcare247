import { Request, Response } from 'express';
import { exerciseService } from '../services/exercise.service';
import { ExerciseQueryParams } from '../types';
import { parseIntSafe, parseIdParam } from '../utils/validation';
import { ApiResponse } from '../utils/response';

export class ExerciseController {
  // Get all exercises
  async getExercises(req: Request, res: Response): Promise<void> {
    try {
      const params: ExerciseQueryParams = {
        page: parseIntSafe(req.query.page as string, 1) ?? 1,
        limit: parseIntSafe(req.query.limit as string, 20) ?? 20,
        language_id: parseIntSafe(req.query.language_id as string, 1) ?? 1,
        level: req.query.level as string,
        category: req.query.category as string,
        equipment: req.query.equipment as string,
        muscle: req.query.muscle as string,
        search: req.query.search as string,
      };

      const { exercises, total } = await exerciseService.getExercises(params);

      res.json({
        success: true,
        data: exercises,
        pagination: {
          page: params.page,
          limit: params.limit,
          total,
          totalPages: Math.ceil(total / (params.limit || 20)),
        },
      });
    } catch (error) {
      console.error('❌ Get exercises error:', error);
      ApiResponse.serverError(res, 'Failed to get exercises');
    }
  }

  // Get exercise by ID
  async getExerciseById(req: Request, res: Response): Promise<void> {
    try {
      const exerciseId = parseIdParam(req.params.id);
      if (!exerciseId) {
        ApiResponse.badRequest(res, 'Invalid exercise ID');
        return;
      }
      const languageId = parseIntSafe(req.query.language_id as string, 1) ?? 1;

      const exercise = await exerciseService.getExerciseById(exerciseId, languageId);

      if (!exercise) {
        ApiResponse.notFound(res, 'Exercise');
        return;
      }

      ApiResponse.success(res, exercise);
    } catch (error) {
      console.error('❌ Get exercise by ID error:', error);
      ApiResponse.serverError(res, 'Failed to get exercise');
    }
  }

  // Get categories
  async getCategories(req: Request, res: Response): Promise<void> {
    try {
      const categories = await exerciseService.getCategories();
      ApiResponse.success(res, categories);
    } catch (error) {
      console.error('❌ Get categories error:', error);
      ApiResponse.serverError(res, 'Failed to get categories');
    }
  }

  // Get levels
  async getLevels(req: Request, res: Response): Promise<void> {
    try {
      const levels = await exerciseService.getLevels();
      ApiResponse.success(res, levels);
    } catch (error) {
      console.error('❌ Get levels error:', error);
      ApiResponse.serverError(res, 'Failed to get levels');
    }
  }

  // Get equipments
  async getEquipments(req: Request, res: Response): Promise<void> {
    try {
      const equipments = await exerciseService.getEquipments();
      ApiResponse.success(res, equipments);
    } catch (error) {
      console.error('❌ Get equipments error:', error);
      ApiResponse.serverError(res, 'Failed to get equipments');
    }
  }

  // Get muscles
  async getMuscles(req: Request, res: Response): Promise<void> {
    try {
      const languageId = parseIntSafe(req.query.language_id as string, 1) ?? 1;
      const muscles = await exerciseService.getMuscles(languageId);
      ApiResponse.success(res, muscles);
    } catch (error) {
      console.error('❌ Get muscles error:', error);
      ApiResponse.serverError(res, 'Failed to get muscles');
    }
  }
}

export const exerciseController = new ExerciseController();
