import { getPool, sql } from '../config/database';
import { FavoriteFood, FavoriteRecipe, Food, Recipe } from '../types';

export class FavoritesService {
    // ==========================================
    // FAVORITE FOODS
    // ==========================================

    // Get user's favorite foods
    async getUserFavoriteFoods(userId: number, languageId: number = 1): Promise<FavoriteFood[]> {
        const pool = getPool();

        const result = await pool.request()
            .input('user_id', sql.Int, userId)
            .input('language_id', sql.Int, languageId)
            .query(`
        SELECT
          ff.user_id,
          ff.food_id,
          ff.notes,
          ff.created_at,
          f.code,
          f.calories,
          f.protein,
          f.fat,
          f.carbs,
          f.fiber,
          f.source,
          f.meal_type,
          COALESCE(ft.name, ft_en.name) as name,
          COALESCE(ft.category_name, ft_en.category_name) as category_name
        FROM Favorite_Foods ff
        JOIN Foods f ON ff.food_id = f.food_id
        LEFT JOIN Food_Translations ft ON f.food_id = ft.food_id AND ft.language_id = @language_id
        LEFT JOIN Food_Translations ft_en ON f.food_id = ft_en.food_id AND ft_en.language_id = 1
        WHERE ff.user_id = @user_id
        ORDER BY ff.created_at DESC
      `);

        return result.recordset.map(row => ({
            user_id: row.user_id,
            food_id: row.food_id,
            notes: row.notes,
            created_at: row.created_at,
            food: {
                food_id: row.food_id,
                code: row.code,
                name: row.name,
                category_name: row.category_name,
                calories: row.calories,
                protein: row.protein,
                fat: row.fat,
                carbs: row.carbs,
                fiber: row.fiber,
                source: row.source,
                meal_type: row.meal_type,
                created_at: row.created_at,
            },
        }));
    }

    // Add food to favorites
    async addFavoriteFood(userId: number, foodId: number, notes?: string): Promise<boolean> {
        const pool = getPool();

        try {
            await pool.request()
                .input('user_id', sql.Int, userId)
                .input('food_id', sql.Int, foodId)
                .input('notes', sql.NVarChar, notes || null)
                .query(`
          IF NOT EXISTS (SELECT 1 FROM Favorite_Foods WHERE user_id = @user_id AND food_id = @food_id)
          INSERT INTO Favorite_Foods (user_id, food_id, notes)
          VALUES (@user_id, @food_id, @notes)
        `);
            return true;
        } catch (error) {
            console.error('Error adding favorite food:', error);
            return false;
        }
    }

    // Remove food from favorites
    async removeFavoriteFood(userId: number, foodId: number): Promise<boolean> {
        const pool = getPool();

        const result = await pool.request()
            .input('user_id', sql.Int, userId)
            .input('food_id', sql.Int, foodId)
            .query(`
        DELETE FROM Favorite_Foods
        WHERE user_id = @user_id AND food_id = @food_id
      `);

        return result.rowsAffected[0] > 0;
    }

    // Check if food is favorited
    async isFoodFavorited(userId: number, foodId: number): Promise<boolean> {
        const pool = getPool();

        const result = await pool.request()
            .input('user_id', sql.Int, userId)
            .input('food_id', sql.Int, foodId)
            .query(`
        SELECT 1 FROM Favorite_Foods
        WHERE user_id = @user_id AND food_id = @food_id
      `);

        return result.recordset.length > 0;
    }

    // ==========================================
    // FAVORITE RECIPES
    // ==========================================

    // Get user's favorite recipes
    async getUserFavoriteRecipes(userId: number, languageId: number = 1): Promise<FavoriteRecipe[]> {
        const pool = getPool();

        const result = await pool.request()
            .input('user_id', sql.Int, userId)
            .input('language_id', sql.Int, languageId)
            .query(`
        SELECT
          fr.user_id,
          fr.recipe_id,
          fr.notes,
          fr.created_at,
          r.recipe_code,
          r.category,
          r.area,
          r.image_url,
          r.thumbnail_url,
          r.youtube_url,
          r.tags,
          COALESCE(rt.name, rt_en.name) as name,
          COALESCE(rt.overview, rt_en.overview) as overview
        FROM Favorite_Recipes fr
        JOIN Recipes r ON fr.recipe_id = r.recipe_id
        LEFT JOIN Recipe_Translations rt ON r.recipe_id = rt.recipe_id AND rt.language_id = @language_id
        LEFT JOIN Recipe_Translations rt_en ON r.recipe_id = rt_en.recipe_id AND rt_en.language_id = 1
        WHERE fr.user_id = @user_id
        ORDER BY fr.created_at DESC
      `);

        return result.recordset.map(row => ({
            user_id: row.user_id,
            recipe_id: row.recipe_id,
            notes: row.notes,
            created_at: row.created_at,
            recipe: {
                recipe_id: row.recipe_id,
                recipe_code: row.recipe_code,
                category: row.category,
                area: row.area,
                image_url: row.image_url,
                thumbnail_url: row.thumbnail_url,
                youtube_url: row.youtube_url,
                tags: row.tags,
                name: row.name,
                overview: row.overview,
                created_at: row.created_at,
            },
        }));
    }

    // Add recipe to favorites
    async addFavoriteRecipe(userId: number, recipeId: number, notes?: string): Promise<boolean> {
        const pool = getPool();

        try {
            await pool.request()
                .input('user_id', sql.Int, userId)
                .input('recipe_id', sql.Int, recipeId)
                .input('notes', sql.NVarChar, notes || null)
                .query(`
          IF NOT EXISTS (SELECT 1 FROM Favorite_Recipes WHERE user_id = @user_id AND recipe_id = @recipe_id)
          INSERT INTO Favorite_Recipes (user_id, recipe_id, notes)
          VALUES (@user_id, @recipe_id, @notes)
        `);
            return true;
        } catch (error) {
            console.error('Error adding favorite recipe:', error);
            return false;
        }
    }

    // Remove recipe from favorites
    async removeFavoriteRecipe(userId: number, recipeId: number): Promise<boolean> {
        const pool = getPool();

        const result = await pool.request()
            .input('user_id', sql.Int, userId)
            .input('recipe_id', sql.Int, recipeId)
            .query(`
        DELETE FROM Favorite_Recipes
        WHERE user_id = @user_id AND recipe_id = @recipe_id
      `);

        return result.rowsAffected[0] > 0;
    }

    // Check if recipe is favorited
    async isRecipeFavorited(userId: number, recipeId: number): Promise<boolean> {
        const pool = getPool();

        const result = await pool.request()
            .input('user_id', sql.Int, userId)
            .input('recipe_id', sql.Int, recipeId)
            .query(`
        SELECT 1 FROM Favorite_Recipes
        WHERE user_id = @user_id AND recipe_id = @recipe_id
      `);

        return result.recordset.length > 0;
    }

    // ==========================================
    // COMBINED FAVORITES
    // ==========================================

    // Get all user favorites
    async getUserFavorites(userId: number, languageId: number = 1): Promise<{
        foods: FavoriteFood[];
        recipes: FavoriteRecipe[];
    }> {
        const foods = await this.getUserFavoriteFoods(userId, languageId);
        const recipes = await this.getUserFavoriteRecipes(userId, languageId);

        return { foods, recipes };
    }
}

export const favoritesService = new FavoritesService();
