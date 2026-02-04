import { getPool, sql } from '../config/database';
import { Food, FoodQueryParams } from '../types';

export class FoodService {
  // Get all foods with pagination and filters
  async getFoods(params: FoodQueryParams): Promise<{ foods: Food[]; total: number }> {
    const pool = getPool();
    const { page = 1, limit = 20, language_id = 1, category, search } = params;
    const offset = (page - 1) * limit;

    // Build WHERE clause - only get foods that have translations
    let whereClause = 'WHERE COALESCE(ft.name, ft_en.name) IS NOT NULL';
    if (category) {
      // Filter by category_name from Food_Translations (supports both languages)
      whereClause += ' AND COALESCE(ft.category_name, ft_en.category_name) = @category';
    }
    if (search) {
      whereClause += ' AND COALESCE(ft.name, ft_en.name) LIKE @search';
    }

    // Get total count - use separate request
    const countRequest = pool.request()
      .input('language_id', sql.Int, language_id);
    if (category) {
      countRequest.input('category', sql.NVarChar, category);
    }
    if (search) {
      countRequest.input('search', sql.NVarChar, `%${search}%`);
    }

    const countResult = await countRequest.query(`
      SELECT COUNT(DISTINCT f.food_id) as total
      FROM Foods f
      LEFT JOIN Food_Translations ft ON f.food_id = ft.food_id AND ft.language_id = @language_id
      LEFT JOIN Food_Translations ft_en ON f.food_id = ft_en.food_id AND ft_en.language_id = 1
      ${whereClause}
    `);
    const total = countResult.recordset[0].total;

    // Get foods with fallback to English - use new request
    const dataRequest = pool.request()
      .input('language_id', sql.Int, language_id)
      .input('offset', sql.Int, offset)
      .input('limit', sql.Int, limit);
    if (category) {
      dataRequest.input('category', sql.NVarChar, category);
    }
    if (search) {
      dataRequest.input('search', sql.NVarChar, `%${search}%`);
    }

    const result = await dataRequest.query(`
      SELECT
        f.food_id,
        f.code,
        f.calories,
        f.protein,
        f.fat,
        f.carbs,
        f.fiber,
        f.cholesterol,
        f.calcium,
        f.phosphorus,
        f.iron,
        f.sodium,
        f.potassium,
        f.beta_carotene,
        f.vitamin_a,
        f.vitamin_b1,
        f.vitamin_c,
        f.category_code,
        f.created_at,
        COALESCE(ft.name, ft_en.name) as name,
        COALESCE(ft.category_name, ft_en.category_name) as category_name
      FROM Foods f
      LEFT JOIN Food_Translations ft ON f.food_id = ft.food_id AND ft.language_id = @language_id
      LEFT JOIN Food_Translations ft_en ON f.food_id = ft_en.food_id AND ft_en.language_id = 1
      ${whereClause}
      ORDER BY f.food_id
      OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
    `);

    return { foods: result.recordset, total };
  }

  // Get single food with fallback to English
  async getFoodById(foodId: number, languageId: number = 1): Promise<Food | null> {
    const pool = getPool();

    const result = await pool.request()
      .input('food_id', sql.Int, foodId)
      .input('language_id', sql.Int, languageId)
      .query(`
        SELECT
          f.food_id,
          f.code,
          f.calories,
          f.protein,
          f.fat,
          f.carbs,
          f.fiber,
          f.cholesterol,
          f.calcium,
          f.phosphorus,
          f.iron,
          f.sodium,
          f.potassium,
          f.beta_carotene,
          f.vitamin_a,
          f.vitamin_b1,
          f.vitamin_c,
          f.category_code,
          f.created_at,
          COALESCE(ft.name, ft_en.name) as name,
          COALESCE(ft.category_name, ft_en.category_name) as category_name
        FROM Foods f
        LEFT JOIN Food_Translations ft ON f.food_id = ft.food_id AND ft.language_id = @language_id
        LEFT JOIN Food_Translations ft_en ON f.food_id = ft_en.food_id AND ft_en.language_id = 1
        WHERE f.food_id = @food_id
      `);

    return result.recordset[0] || null;
  }

  // Get all categories with fallback to English
  async getCategories(languageId: number = 1): Promise<string[]> {
    const pool = getPool();
    const result = await pool.request()
      .input('language_id', sql.Int, languageId)
      .query(`
        SELECT DISTINCT COALESCE(ft.category_name, ft_en.category_name) as category_name
        FROM Foods f
        LEFT JOIN Food_Translations ft ON f.food_id = ft.food_id AND ft.language_id = @language_id
        LEFT JOIN Food_Translations ft_en ON f.food_id = ft_en.food_id AND ft_en.language_id = 1
        WHERE COALESCE(ft.category_name, ft_en.category_name) IS NOT NULL
        ORDER BY category_name
      `);
    return result.recordset.map((r: { category_name: string }) => r.category_name);
  }

  // Search foods
  async searchFoods(query: string, languageId: number = 1, limit: number = 10): Promise<Food[]> {
    const pool = getPool();

    const result = await pool.request()
      .input('search', sql.NVarChar, `%${query}%`)
      .input('language_id', sql.Int, languageId)
      .input('limit', sql.Int, limit)
      .query(`
        SELECT TOP (@limit)
          f.food_id,
          f.code,
          f.calories,
          f.protein,
          f.fat,
          f.carbs,
          f.fiber,
          f.cholesterol,
          f.calcium,
          f.phosphorus,
          f.iron,
          f.sodium,
          f.potassium,
          f.beta_carotene,
          f.vitamin_a,
          f.vitamin_b1,
          f.vitamin_c,
          f.category_code,
          f.created_at,
          COALESCE(ft.name, ft_en.name) as name,
          COALESCE(ft.category_name, ft_en.category_name) as category_name
        FROM Foods f
        LEFT JOIN Food_Translations ft ON f.food_id = ft.food_id AND ft.language_id = @language_id
        LEFT JOIN Food_Translations ft_en ON f.food_id = ft_en.food_id AND ft_en.language_id = 1
        WHERE COALESCE(ft.name, ft_en.name) LIKE @search
        ORDER BY COALESCE(ft.name, ft_en.name)
      `);

    return result.recordset;
  }
}

export const foodService = new FoodService();

