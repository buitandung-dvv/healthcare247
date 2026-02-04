import { Request, Response } from 'express';
import { recipeService } from '../services/recipe.service';
import { RecipeQueryParams } from '../types';
import { ApiResponse } from '../utils/response';
import { parseIntSafe, parseIdParam } from '../utils/validation';

export class RecipeController {
  // Get all recipes
  async getRecipes(req: Request, res: Response): Promise<void> {
    try {
      const params: RecipeQueryParams = {
        page: parseIntSafe(req.query.page as string, 1) ?? 1,
        limit: parseIntSafe(req.query.limit as string, 20) ?? 20,
        language_id: parseIntSafe(req.query.language_id as string, 1) ?? 1,
        category: req.query.category as string,
        area: req.query.area as string,
        search: req.query.search as string,
      };

      const { recipes, total } = await recipeService.getRecipes(params);

      res.json({
        success: true,
        data: recipes,
        pagination: {
          page: params.page,
          limit: params.limit,
          total,
          totalPages: Math.ceil(total / (params.limit || 20)),
        },
      });
    } catch (error) {
      console.error('❌ Get recipes error:', error);
      ApiResponse.serverError(res, 'Failed to get recipes');
    }
  }

  // Get recipe by ID
  async getRecipeById(req: Request, res: Response): Promise<void> {
    try {
      const recipeId = parseIdParam(req.params.id);
      if (!recipeId) {
        ApiResponse.badRequest(res, 'Invalid recipe ID');
        return;
      }
      const languageId = parseIntSafe(req.query.language_id as string, 1) ?? 1;

      const recipe = await recipeService.getRecipeById(recipeId, languageId);

      if (!recipe) {
        ApiResponse.notFound(res, 'Recipe');
        return;
      }

      ApiResponse.success(res, recipe);
    } catch (error) {
      console.error('❌ Get recipe by ID error:', error);
      ApiResponse.serverError(res, 'Failed to get recipe');
    }
  }

  // Get categories
  async getCategories(req: Request, res: Response): Promise<void> {
    try {
      const categories = await recipeService.getCategories();
      ApiResponse.success(res, categories);
    } catch (error) {
      console.error('❌ Get categories error:', error);
      ApiResponse.serverError(res, 'Failed to get categories');
    }
  }

  // Get areas
  async getAreas(req: Request, res: Response): Promise<void> {
    try {
      const areas = await recipeService.getAreas();
      ApiResponse.success(res, areas);
    } catch (error) {
      console.error('❌ Get areas error:', error);
      ApiResponse.serverError(res, 'Failed to get areas');
    }
  }

  // Search recipes
  async searchRecipes(req: Request, res: Response): Promise<void> {
    try {
      const query = req.query.q as string;
      const languageId = parseIntSafe(req.query.language_id as string, 1) ?? 1;
      const limit = parseIntSafe(req.query.limit as string, 10) ?? 10;

      if (!query) {
        ApiResponse.badRequest(res, 'Search query is required');
        return;
      }

      const recipes = await recipeService.searchRecipes(query, languageId, limit);
      ApiResponse.success(res, recipes);
    } catch (error) {
      console.error('❌ Search recipes error:', error);
      ApiResponse.serverError(res, 'Search failed');
    }
  }
}

export const recipeController = new RecipeController();
