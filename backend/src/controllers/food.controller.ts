import { Request, Response } from 'express';
import { foodService } from '../services/food.service';
import { FoodQueryParams } from '../types';
import { ApiResponse } from '../utils/response';
import { parseIntSafe, parseIdParam } from '../utils/validation';

export class FoodController {
  // Get all foods
  async getFoods(req: Request, res: Response): Promise<void> {
    try {
      const params: FoodQueryParams = {
        page: parseIntSafe(req.query.page as string, 1) ?? 1,
        limit: parseIntSafe(req.query.limit as string, 20) ?? 20,
        language_id: parseIntSafe(req.query.language_id as string, 1) ?? 1,
        category: req.query.category as string,
        search: req.query.search as string,
      };

      const { foods, total } = await foodService.getFoods(params);

      res.json({
        success: true,
        data: foods,
        pagination: {
          page: params.page,
          limit: params.limit,
          total,
          totalPages: Math.ceil(total / (params.limit || 20)),
        },
      });
    } catch (error) {
      console.error('❌ Get foods error:', error);
      ApiResponse.serverError(res, 'Failed to get foods');
    }
  }

  // Get food by ID
  async getFoodById(req: Request, res: Response): Promise<void> {
    try {
      const foodId = parseIdParam(req.params.id);
      if (!foodId) {
        ApiResponse.badRequest(res, 'Invalid food ID');
        return;
      }
      const languageId = parseIntSafe(req.query.language_id as string, 1) ?? 1;

      const food = await foodService.getFoodById(foodId, languageId);

      if (!food) {
        ApiResponse.notFound(res, 'Food');
        return;
      }

      ApiResponse.success(res, food);
    } catch (error) {
      console.error('❌ Get food by ID error:', error);
      ApiResponse.serverError(res, 'Failed to get food');
    }
  }

  // Get categories
  async getCategories(req: Request, res: Response): Promise<void> {
    try {
      const languageId = parseIntSafe(req.query.language_id as string, 1) ?? 1;
      const categories = await foodService.getCategories(languageId);
      ApiResponse.success(res, categories);
    } catch (error) {
      console.error('❌ Get categories error:', error);
      ApiResponse.serverError(res, 'Failed to get categories');
    }
  }

  // Search foods
  async searchFoods(req: Request, res: Response): Promise<void> {
    try {
      const query = req.query.q as string;
      const languageId = parseIntSafe(req.query.language_id as string, 1) ?? 1;
      const limit = parseIntSafe(req.query.limit as string, 10) ?? 10;

      if (!query) {
        ApiResponse.badRequest(res, 'Search query is required');
        return;
      }

      const foods = await foodService.searchFoods(query, languageId, limit);
      ApiResponse.success(res, foods);
    } catch (error) {
      console.error('❌ Search foods error:', error);
      ApiResponse.serverError(res, 'Search failed');
    }
  }
}

export const foodController = new FoodController();
