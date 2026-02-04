import { getPool, sql } from '../config/database';
import { Recipe, RecipeQueryParams, RecipeInstruction, RecipeIngredient } from '../types';
import { cacheService, CacheKeys } from './cache.service';

export class RecipeService {
  // Get all recipes with pagination and filters
  async getRecipes(params: RecipeQueryParams): Promise<{ recipes: Recipe[]; total: number }> {
    const pool = getPool();
    const { page = 1, limit = 20, language_id = 1, category, area, search } = params;
    const offset = (page - 1) * limit;

    let whereClause = 'WHERE 1=1';
    const request = pool.request()
      .input('language_id', sql.Int, language_id)
      .input('offset', sql.Int, offset)
      .input('limit', sql.Int, limit);

    if (category) {
      whereClause += ' AND r.category = @category';
      request.input('category', sql.NVarChar, category);
    }
    if (area) {
      whereClause += ' AND r.area = @area';
      request.input('area', sql.NVarChar, area);
    }
    if (search) {
      whereClause += ' AND (rt.name LIKE @search OR rt.overview LIKE @search)';
      request.input('search', sql.NVarChar, `%${search}%`);
    }

    // Get total count
    const countResult = await request.query(`
      SELECT COUNT(DISTINCT r.recipe_id) as total
      FROM Recipes r
      LEFT JOIN Recipe_Translations rt ON r.recipe_id = rt.recipe_id AND rt.language_id = @language_id
      ${whereClause}
    `);
    const total = countResult.recordset[0].total;

    // Get recipes with fallback to English
    const result = await pool.request()
      .input('language_id', sql.Int, language_id)
      .input('offset', sql.Int, offset)
      .input('limit', sql.Int, limit)
      .input('category', sql.NVarChar, category || null)
      .input('area', sql.NVarChar, area || null)
      .input('search', sql.NVarChar, search ? `%${search}%` : null)
      .query(`
        SELECT
          r.recipe_id,
          r.recipe_code,
          r.themealdb_id,
          r.category,
          r.area,
          r.image_url,
          r.thumbnail_url,
          r.youtube_url,
          r.source_url,
          r.tags,
          r.created_at,
          COALESCE(rt.name, rt_en.name) as name,
          COALESCE(rt.overview, rt_en.overview) as overview
        FROM Recipes r
        LEFT JOIN Recipe_Translations rt ON r.recipe_id = rt.recipe_id AND rt.language_id = @language_id
        LEFT JOIN Recipe_Translations rt_en ON r.recipe_id = rt_en.recipe_id AND rt_en.language_id = 1
        ${whereClause}
        ORDER BY r.recipe_id
        OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
      `);

    return { recipes: result.recordset, total };
  }

  // Get single recipe with ingredients and step-by-step instructions
  async getRecipeById(recipeId: number, languageId: number = 1): Promise<Recipe | null> {
    const pool = getPool();

    // Get base recipe info with fallback to English
    const recipeResult = await pool.request()
      .input('recipe_id', sql.Int, recipeId)
      .input('language_id', sql.Int, languageId)
      .query(`
        SELECT
          r.recipe_id,
          r.recipe_code,
          r.themealdb_id,
          r.category,
          r.area,
          r.image_url,
          r.thumbnail_url,
          r.youtube_url,
          r.source_url,
          r.tags,
          r.created_at,
          COALESCE(rt.name, rt_en.name) as name,
          COALESCE(rt.overview, rt_en.overview) as overview
        FROM Recipes r
        LEFT JOIN Recipe_Translations rt ON r.recipe_id = rt.recipe_id AND rt.language_id = @language_id
        LEFT JOIN Recipe_Translations rt_en ON r.recipe_id = rt_en.recipe_id AND rt_en.language_id = 1
        WHERE r.recipe_id = @recipe_id
      `);

    if (recipeResult.recordset.length === 0) {
      return null;
    }

    const recipe = recipeResult.recordset[0];

    // Get step-by-step instructions with fallback to English
    let instructionsResult = await pool.request()
      .input('recipe_id', sql.Int, recipeId)
      .input('language_id', sql.Int, languageId)
      .query(`
        SELECT step_order, instruction
        FROM Recipe_Instructions
        WHERE recipe_id = @recipe_id AND language_id = @language_id
        ORDER BY step_order
      `);

    // Fallback to English if no instructions found
    if (instructionsResult.recordset.length === 0 && languageId !== 1) {
      instructionsResult = await pool.request()
        .input('recipe_id', sql.Int, recipeId)
        .query(`
          SELECT step_order, instruction
          FROM Recipe_Instructions
          WHERE recipe_id = @recipe_id AND language_id = 1
          ORDER BY step_order
        `);
    }

    // Get ingredients with fallback to English
    let ingredientsResult = await pool.request()
      .input('recipe_id', sql.Int, recipeId)
      .input('language_id', sql.Int, languageId)
      .query(`
        SELECT ingredient_name, measure, display_order
        FROM Recipe_Ingredients
        WHERE recipe_id = @recipe_id AND language_id = @language_id
        ORDER BY display_order
      `);

    // Fallback to English if no ingredients found
    if (ingredientsResult.recordset.length === 0 && languageId !== 1) {
      ingredientsResult = await pool.request()
        .input('recipe_id', sql.Int, recipeId)
        .query(`
          SELECT ingredient_name, measure, display_order
          FROM Recipe_Ingredients
          WHERE recipe_id = @recipe_id AND language_id = 1
          ORDER BY display_order
        `);
    }

    return {
      ...recipe,
      instructions: instructionsResult.recordset,
      ingredients: ingredientsResult.recordset,
    };
  }

  // Get all categories (cached for 60 minutes)
  async getCategories(): Promise<string[]> {
    return cacheService.getOrSet(
      CacheKeys.RECIPE_CATEGORIES,
      async () => {
        const pool = getPool();
        const result = await pool.request().query(`
          SELECT DISTINCT category FROM Recipes WHERE category IS NOT NULL ORDER BY category
        `);
        return result.recordset.map((r: { category: string }) => r.category);
      },
      60 // 60 minutes TTL
    );
  }

  // Get all areas (cached for 60 minutes)
  async getAreas(): Promise<string[]> {
    return cacheService.getOrSet(
      CacheKeys.RECIPE_AREAS,
      async () => {
        const pool = getPool();
        const result = await pool.request().query(`
          SELECT DISTINCT area FROM Recipes WHERE area IS NOT NULL ORDER BY area
        `);
        return result.recordset.map((r: { area: string }) => r.area);
      },
      60 // 60 minutes TTL
    );
  }

  // Search recipes
  async searchRecipes(query: string, languageId: number = 1, limit: number = 10): Promise<Recipe[]> {
    const pool = getPool();

    const result = await pool.request()
      .input('search', sql.NVarChar, `%${query}%`)
      .input('language_id', sql.Int, languageId)
      .input('limit', sql.Int, limit)
      .query(`
        SELECT TOP (@limit)
          r.recipe_id,
          r.recipe_code,
          r.category,
          r.area,
          r.image_url,
          r.thumbnail_url,
          COALESCE(rt.name, rt_en.name) as name,
          COALESCE(rt.overview, rt_en.overview) as overview
        FROM Recipes r
        LEFT JOIN Recipe_Translations rt ON r.recipe_id = rt.recipe_id AND rt.language_id = @language_id
        LEFT JOIN Recipe_Translations rt_en ON r.recipe_id = rt_en.recipe_id AND rt_en.language_id = 1
        WHERE rt.name LIKE @search OR r.tags LIKE @search
        ORDER BY rt.name
      `);

    return result.recordset;
  }
}

export const recipeService = new RecipeService();
