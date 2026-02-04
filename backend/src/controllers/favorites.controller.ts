import { Request, Response } from 'express';
import { favoritesService } from '../services/favorites.service';
import { ApiResponse } from '../utils/response';
import { parseIntSafe, parseIdParam } from '../utils/validation';

// Extended Request type with user info
interface AuthenticatedRequest extends Request {
    user?: { user_id: number };
    userId?: number;
}

export class FavoritesController {
    // Get all user favorites
    async getUserFavorites(req: AuthenticatedRequest, res: Response): Promise<void> {
        try {
            const userId = req.userId || req.user?.user_id;
            if (!userId) {
                ApiResponse.unauthorized(res);
                return;
            }

            const languageId = parseIntSafe(req.query.language_id as string, 1) ?? 1;
            const favorites = await favoritesService.getUserFavorites(userId, languageId);
            ApiResponse.success(res, favorites);
        } catch (error) {
            console.error('❌ Get favorites error:', error);
            ApiResponse.serverError(res, 'Failed to get favorites');
        }
    }

    // Get favorite foods
    async getFavoriteFoods(req: AuthenticatedRequest, res: Response): Promise<void> {
        try {
            const userId = req.userId || req.user?.user_id;
            if (!userId) {
                ApiResponse.unauthorized(res);
                return;
            }

            const languageId = parseIntSafe(req.query.language_id as string, 1) ?? 1;
            const foods = await favoritesService.getUserFavoriteFoods(userId, languageId);
            ApiResponse.success(res, foods);
        } catch (error) {
            console.error('❌ Get favorite foods error:', error);
            ApiResponse.serverError(res, 'Failed to get favorite foods');
        }
    }

    // Add food to favorites
    async addFavoriteFood(req: AuthenticatedRequest, res: Response): Promise<void> {
        try {
            const userId = req.userId || req.user?.user_id;
            if (!userId) {
                ApiResponse.unauthorized(res);
                return;
            }

            const { food_id, notes } = req.body;
            if (!food_id) {
                ApiResponse.badRequest(res, 'food_id is required');
                return;
            }

            const success = await favoritesService.addFavoriteFood(userId, food_id, notes);

            if (success) {
                ApiResponse.created(res, null, 'Food added to favorites');
            } else {
                ApiResponse.badRequest(res, 'Failed to add food to favorites');
            }
        } catch (error) {
            console.error('❌ Add favorite food error:', error);
            ApiResponse.serverError(res, 'Failed to add favorite food');
        }
    }

    // Remove food from favorites
    async removeFavoriteFood(req: AuthenticatedRequest, res: Response): Promise<void> {
        try {
            const userId = req.userId || req.user?.user_id;
            if (!userId) {
                ApiResponse.unauthorized(res);
                return;
            }

            const foodId = parseIdParam(req.params.foodId);
            if (!foodId) {
                ApiResponse.badRequest(res, 'Invalid food ID');
                return;
            }

            const success = await favoritesService.removeFavoriteFood(userId, foodId);

            if (success) {
                res.status(204).send();
            } else {
                ApiResponse.notFound(res, 'Food in favorites');
            }
        } catch (error) {
            console.error('❌ Remove favorite food error:', error);
            ApiResponse.serverError(res, 'Failed to remove favorite food');
        }
    }

    // Get favorite recipes
    async getFavoriteRecipes(req: AuthenticatedRequest, res: Response): Promise<void> {
        try {
            const userId = req.userId || req.user?.user_id;
            if (!userId) {
                ApiResponse.unauthorized(res);
                return;
            }

            const languageId = parseIntSafe(req.query.language_id as string, 1) ?? 1;
            const recipes = await favoritesService.getUserFavoriteRecipes(userId, languageId);
            ApiResponse.success(res, recipes);
        } catch (error) {
            console.error('❌ Get favorite recipes error:', error);
            ApiResponse.serverError(res, 'Failed to get favorite recipes');
        }
    }

    // Add recipe to favorites
    async addFavoriteRecipe(req: AuthenticatedRequest, res: Response): Promise<void> {
        try {
            const userId = req.userId || req.user?.user_id;
            if (!userId) {
                ApiResponse.unauthorized(res);
                return;
            }

            const { recipe_id, notes } = req.body;
            if (!recipe_id) {
                ApiResponse.badRequest(res, 'recipe_id is required');
                return;
            }

            const success = await favoritesService.addFavoriteRecipe(userId, recipe_id, notes);

            if (success) {
                ApiResponse.created(res, null, 'Recipe added to favorites');
            } else {
                ApiResponse.badRequest(res, 'Failed to add recipe to favorites');
            }
        } catch (error) {
            console.error('❌ Add favorite recipe error:', error);
            ApiResponse.serverError(res, 'Failed to add favorite recipe');
        }
    }

    // Remove recipe from favorites
    async removeFavoriteRecipe(req: AuthenticatedRequest, res: Response): Promise<void> {
        try {
            const userId = req.userId || req.user?.user_id;
            if (!userId) {
                ApiResponse.unauthorized(res);
                return;
            }

            const recipeId = parseIdParam(req.params.recipeId);
            if (!recipeId) {
                ApiResponse.badRequest(res, 'Invalid recipe ID');
                return;
            }

            const success = await favoritesService.removeFavoriteRecipe(userId, recipeId);

            if (success) {
                res.status(204).send();
            } else {
                ApiResponse.notFound(res, 'Recipe in favorites');
            }
        } catch (error) {
            console.error('❌ Remove favorite recipe error:', error);
            ApiResponse.serverError(res, 'Failed to remove favorite recipe');
        }
    }
}

export const favoritesController = new FavoritesController();
