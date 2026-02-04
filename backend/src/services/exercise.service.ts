import { getPool, sql } from '../config/database';
import { Exercise, ExerciseQueryParams, Muscle } from '../types';
import { cacheService, CacheKeys } from './cache.service';

export class ExerciseService {
  // Get all exercises with pagination and filters
  async getExercises(params: ExerciseQueryParams): Promise<{ exercises: Exercise[]; total: number }> {
    const pool = getPool();
    const { page = 1, limit = 20, language_id = 1, level, category, equipment, muscle, search } = params;
    const offset = (page - 1) * limit;

    let whereClause = 'WHERE 1=1';
    const request = pool.request()
      .input('language_id', sql.Int, language_id)
      .input('offset', sql.Int, offset)
      .input('limit', sql.Int, limit);

    if (level) {
      whereClause += ' AND e.level = @level';
      request.input('level', sql.NVarChar, level);
    }
    if (category) {
      whereClause += ' AND e.category = @category';
      request.input('category', sql.NVarChar, category);
    }
    if (equipment) {
      whereClause += ' AND e.equipment = @equipment';
      request.input('equipment', sql.NVarChar, equipment);
    }
    if (muscle) {
      whereClause += ' AND (EXISTS (SELECT 1 FROM ExercisePrimaryMuscles epm WHERE epm.exercise_id = e.exercise_id AND epm.muscle = @muscle) OR EXISTS (SELECT 1 FROM ExerciseSecondaryMuscles esm WHERE esm.exercise_id = e.exercise_id AND esm.muscle = @muscle))';
      request.input('muscle', sql.NVarChar, muscle);
    }
    if (search) {
      whereClause += ' AND et.name LIKE @search';
      request.input('search', sql.NVarChar, `%${search}%`);
    }

    // Get total count
    const countResult = await request.query(`
      SELECT COUNT(DISTINCT e.exercise_id) as total
      FROM Exercises e
      LEFT JOIN Exercise_Translations et ON e.exercise_id = et.exercise_id AND et.language_id = @language_id
      ${whereClause}
    `);
    const total = countResult.recordset[0].total;

    // Get exercises with fallback to English
    const result = await pool.request()
      .input('language_id', sql.Int, language_id)
      .input('offset', sql.Int, offset)
      .input('limit', sql.Int, limit)
      .input('level', sql.NVarChar, level || null)
      .input('category', sql.NVarChar, category || null)
      .input('equipment', sql.NVarChar, equipment || null)
      .input('muscle', sql.NVarChar, muscle || null)
      .input('search', sql.NVarChar, search ? `%${search}%` : null)
      .query(`
        SELECT DISTINCT
          e.exercise_id,
          e.slug,
          e.force,
          e.level,
          e.mechanic,
          e.equipment,
          e.category,
          e.created_at,
          COALESCE(et.name, et_en.name) as name
        FROM Exercises e
        LEFT JOIN Exercise_Translations et ON e.exercise_id = et.exercise_id AND et.language_id = @language_id
        LEFT JOIN Exercise_Translations et_en ON e.exercise_id = et_en.exercise_id AND et_en.language_id = 1
        ${whereClause}
        ORDER BY e.exercise_id
        OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
      `);

    // OPTIMIZED: Batch load all related data instead of N+1 queries
    const exerciseIds = result.recordset.map((r: any) => r.exercise_id);

    if (exerciseIds.length === 0) {
      return { exercises: [], total };
    }

    // Batch load all muscles, instructions, and images in parallel
    const [primaryMuscles, secondaryMuscles, instructions, images] = await Promise.all([
      this.batchLoadPrimaryMuscles(exerciseIds, language_id),
      this.batchLoadSecondaryMuscles(exerciseIds, language_id),
      this.batchLoadInstructions(exerciseIds, language_id),
      this.batchLoadImages(exerciseIds),
    ]);

    // Combine all data
    const exercises: Exercise[] = result.recordset.map((row: any) => ({
      ...row,
      primary_muscles: primaryMuscles.get(row.exercise_id) || [],
      secondary_muscles: secondaryMuscles.get(row.exercise_id) || [],
      instructions: instructions.get(row.exercise_id) || [],
      images: images.get(row.exercise_id) || [],
    }));

    return { exercises, total };
  }

  // Batch load primary muscles for multiple exercises
  private async batchLoadPrimaryMuscles(exerciseIds: number[], languageId: number): Promise<Map<number, string[]>> {
    const pool = getPool();
    const result = await pool.request()
      .input('language_id', sql.Int, languageId)
      .query(`
        SELECT epm.exercise_id, COALESCE(mt.name, m.code) as muscle
        FROM ExercisePrimaryMuscles epm
        LEFT JOIN Muscles m ON epm.muscle = m.code
        LEFT JOIN Muscle_Translations mt ON m.muscle_id = mt.muscle_id AND mt.language_id = @language_id
        WHERE epm.exercise_id IN (${exerciseIds.join(',')})
      `);

    const muscleMap = new Map<number, string[]>();
    for (const row of result.recordset) {
      if (!muscleMap.has(row.exercise_id)) {
        muscleMap.set(row.exercise_id, []);
      }
      muscleMap.get(row.exercise_id)!.push(row.muscle);
    }
    return muscleMap;
  }

  // Batch load secondary muscles for multiple exercises
  private async batchLoadSecondaryMuscles(exerciseIds: number[], languageId: number): Promise<Map<number, string[]>> {
    const pool = getPool();
    const result = await pool.request()
      .input('language_id', sql.Int, languageId)
      .query(`
        SELECT esm.exercise_id, COALESCE(mt.name, m.code) as muscle
        FROM ExerciseSecondaryMuscles esm
        LEFT JOIN Muscles m ON esm.muscle = m.code
        LEFT JOIN Muscle_Translations mt ON m.muscle_id = mt.muscle_id AND mt.language_id = @language_id
        WHERE esm.exercise_id IN (${exerciseIds.join(',')})
      `);

    const muscleMap = new Map<number, string[]>();
    for (const row of result.recordset) {
      if (!muscleMap.has(row.exercise_id)) {
        muscleMap.set(row.exercise_id, []);
      }
      muscleMap.get(row.exercise_id)!.push(row.muscle);
    }
    return muscleMap;
  }

  // Batch load instructions for multiple exercises
  private async batchLoadInstructions(exerciseIds: number[], languageId: number): Promise<Map<number, string[]>> {
    const pool = getPool();

    // Try requested language first
    let result = await pool.request()
      .input('language_id', sql.Int, languageId)
      .query(`
        SELECT exercise_id, instruction
        FROM ExerciseInstructions
        WHERE exercise_id IN (${exerciseIds.join(',')}) AND language_id = @language_id
        ORDER BY exercise_id, step_order
      `);

    const instructionMap = new Map<number, string[]>();
    for (const row of result.recordset) {
      if (!instructionMap.has(row.exercise_id)) {
        instructionMap.set(row.exercise_id, []);
      }
      instructionMap.get(row.exercise_id)!.push(row.instruction);
    }

    // Fallback to English for exercises without translations
    if (languageId !== 1) {
      const missingIds = exerciseIds.filter(id => !instructionMap.has(id));
      if (missingIds.length > 0) {
        const fallbackResult = await pool.request().query(`
          SELECT exercise_id, instruction
          FROM ExerciseInstructions
          WHERE exercise_id IN (${missingIds.join(',')}) AND language_id = 1
          ORDER BY exercise_id, step_order
        `);

        for (const row of fallbackResult.recordset) {
          if (!instructionMap.has(row.exercise_id)) {
            instructionMap.set(row.exercise_id, []);
          }
          instructionMap.get(row.exercise_id)!.push(row.instruction);
        }
      }
    }

    return instructionMap;
  }

  // Batch load images for multiple exercises
  private async batchLoadImages(exerciseIds: number[]): Promise<Map<number, string[]>> {
    const pool = getPool();
    const result = await pool.request().query(`
      SELECT exercise_id, image_url
      FROM ExerciseImages
      WHERE exercise_id IN (${exerciseIds.join(',')})
    `);

    const imageMap = new Map<number, string[]>();
    for (const row of result.recordset) {
      if (!imageMap.has(row.exercise_id)) {
        imageMap.set(row.exercise_id, []);
      }
      // Return full path for frontend
      const fullPath = `/images/exercises/${row.image_url}`;
      imageMap.get(row.exercise_id)!.push(fullPath);
    }
    return imageMap;
  }

  // Get single exercise with full details
  async getExerciseById(exerciseId: number, languageId: number = 1): Promise<Exercise | null> {
    return this.getExerciseDetails(exerciseId, languageId);
  }

  private async getExerciseDetails(exerciseId: number, languageId: number): Promise<Exercise | null> {
    const pool = getPool();

    // Get base exercise info with fallback to English (language_id = 1) if translation not found
    const exerciseResult = await pool.request()
      .input('exercise_id', sql.Int, exerciseId)
      .input('language_id', sql.Int, languageId)
      .query(`
        SELECT
          e.exercise_id,
          e.slug,
          e.force,
          e.level,
          e.mechanic,
          e.equipment,
          e.category,
          e.created_at,
          COALESCE(et.name, et_en.name) as name
        FROM Exercises e
        LEFT JOIN Exercise_Translations et ON e.exercise_id = et.exercise_id AND et.language_id = @language_id
        LEFT JOIN Exercise_Translations et_en ON e.exercise_id = et_en.exercise_id AND et_en.language_id = 1
        WHERE e.exercise_id = @exercise_id
      `);

    if (exerciseResult.recordset.length === 0) {
      return null;
    }

    const exercise = exerciseResult.recordset[0];

    // Get primary muscles with translated names
    const primaryMusclesResult = await pool.request()
      .input('exercise_id', sql.Int, exerciseId)
      .input('language_id', sql.Int, languageId)
      .query(`
        SELECT COALESCE(mt.name, m.code) as muscle
        FROM ExercisePrimaryMuscles epm
        LEFT JOIN Muscles m ON epm.muscle = m.code
        LEFT JOIN Muscle_Translations mt ON m.muscle_id = mt.muscle_id AND mt.language_id = @language_id
        WHERE epm.exercise_id = @exercise_id
      `);

    // Get secondary muscles with translated names
    const secondaryMusclesResult = await pool.request()
      .input('exercise_id', sql.Int, exerciseId)
      .input('language_id', sql.Int, languageId)
      .query(`
        SELECT COALESCE(mt.name, m.code) as muscle
        FROM ExerciseSecondaryMuscles esm
        LEFT JOIN Muscles m ON esm.muscle = m.code
        LEFT JOIN Muscle_Translations mt ON m.muscle_id = mt.muscle_id AND mt.language_id = @language_id
        WHERE esm.exercise_id = @exercise_id
      `);

    // Get instructions with fallback to English
    let instructionsResult = await pool.request()
      .input('exercise_id', sql.Int, exerciseId)
      .input('language_id', sql.Int, languageId)
      .query(`
        SELECT instruction
        FROM ExerciseInstructions
        WHERE exercise_id = @exercise_id AND language_id = @language_id
        ORDER BY step_order
      `);

    // Fallback to English if no instructions found for requested language
    if (instructionsResult.recordset.length === 0 && languageId !== 1) {
      instructionsResult = await pool.request()
        .input('exercise_id', sql.Int, exerciseId)
        .query(`
          SELECT instruction
          FROM ExerciseInstructions
          WHERE exercise_id = @exercise_id AND language_id = 1
          ORDER BY step_order
        `);
    }

    // Get images
    const imagesResult = await pool.request()
      .input('exercise_id', sql.Int, exerciseId)
      .query(`SELECT image_url FROM ExerciseImages WHERE exercise_id = @exercise_id`);

    return {
      ...exercise,
      primary_muscles: primaryMusclesResult.recordset.map((r: { muscle: string }) => r.muscle),
      secondary_muscles: secondaryMusclesResult.recordset.map((r: { muscle: string }) => r.muscle),
      instructions: instructionsResult.recordset.map((r: { instruction: string }) => r.instruction),
      images: imagesResult.recordset.map((r: { image_url: string }) => `/images/exercises/${r.image_url}`),
    };
  }

  // Get all categories (cached for 60 minutes)
  async getCategories(): Promise<string[]> {
    return cacheService.getOrSet(
      CacheKeys.CATEGORIES,
      async () => {
        const pool = getPool();
        const result = await pool.request().query(`
          SELECT DISTINCT category FROM Exercises WHERE category IS NOT NULL ORDER BY category
        `);
        return result.recordset.map((r: { category: string }) => r.category);
      },
      60 // 60 minutes TTL
    );
  }

  // Get all levels
  async getLevels(): Promise<string[]> {
    return ['beginner', 'intermediate', 'expert'];
  }

  // Get all equipment (cached for 60 minutes)
  async getEquipments(): Promise<string[]> {
    return cacheService.getOrSet(
      CacheKeys.EQUIPMENTS,
      async () => {
        const pool = getPool();
        const result = await pool.request().query(`
          SELECT DISTINCT equipment FROM Exercises WHERE equipment IS NOT NULL ORDER BY equipment
        `);
        return result.recordset.map((r: { equipment: string }) => r.equipment);
      },
      60 // 60 minutes TTL
    );
  }

  // Get all muscles (cached per language for 60 minutes)
  async getMuscles(languageId: number = 1): Promise<Muscle[]> {
    return cacheService.getOrSet(
      CacheKeys.MUSCLES(languageId),
      async () => {
        const pool = getPool();
        const result = await pool.request()
          .input('language_id', sql.Int, languageId)
          .query(`
            SELECT m.muscle_id, m.code, mt.name, mt.description
            FROM Muscles m
            LEFT JOIN Muscle_Translations mt ON m.muscle_id = mt.muscle_id AND mt.language_id = @language_id
            ORDER BY m.code
          `);
        return result.recordset;
      },
      60 // 60 minutes TTL
    );
  }
}

export const exerciseService = new ExerciseService();

