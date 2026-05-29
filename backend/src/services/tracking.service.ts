import { getPool, sql } from '../config/database';
import { ExerciseTracking, MealTracking, WeightTracking, WaterTracking } from '../types';

export class TrackingService {
  // ============ EXERCISE TRACKING ============

  // Log exercise
  async logExercise(
    userId: number,
    exerciseId: number,
    duration?: number,
    caloriesBurned?: number,
    sets?: number,
    reps?: number,
    weight?: number,
    notes?: string,
    trackedAt?: Date
  ): Promise<ExerciseTracking> {
    const pool = getPool();
    const trackingDate = trackedAt || new Date();

    await pool.request()
      .input('user_id', sql.Int, userId)
      .input('exercise_id', sql.Int, exerciseId)
      .input('duration', sql.Int, duration || null)
      .input('calories_burned', sql.Decimal(10, 2), caloriesBurned || null)
      .input('sets', sql.Int, sets || null)
      .input('reps', sql.Int, reps || null)
      .input('weight', sql.Decimal(10, 2), weight || null)
      .input('notes', sql.NVarChar(500), notes || null)
      .input('tracked_at', sql.DateTime, trackingDate)
      .query(`
        INSERT INTO Exercise_Tracking (user_id, exercise_id, duration, calories_burned, sets, reps, weight, notes, tracked_at)
        VALUES (@user_id, @exercise_id, @duration, @calories_burned, @sets, @reps, @weight, @notes, @tracked_at)
      `);

    // Get the newly created record
    const result = await pool.request()
      .input('user_id', sql.Int, userId)
      .input('exercise_id', sql.Int, exerciseId)
      .input('tracked_at', sql.DateTime, trackingDate)
      .query(`
        SELECT TOP 1 * FROM Exercise_Tracking 
        WHERE user_id = @user_id AND exercise_id = @exercise_id AND tracked_at = @tracked_at
        ORDER BY tracked_at DESC
      `);

    return result.recordset[0];
  }

  // Get user exercise tracking
  async getExerciseTracking(
    userId: number,
    startDate?: Date,
    endDate?: Date,
    limit: number = 100
  ): Promise<ExerciseTracking[]> {
    const pool = getPool();

    // Ensure limit is within bounds
    const maxLimit = Math.min(Math.max(limit, 1), 100);

    let whereClause = 'WHERE et.user_id = @user_id';
    const request = pool.request()
      .input('user_id', sql.Int, userId)
      .input('limit', sql.Int, maxLimit);

    if (startDate) {
      whereClause += ' AND CAST(et.tracked_at AS DATE) >= @start_date';
      request.input('start_date', sql.Date, startDate);
    }
    if (endDate) {
      whereClause += ' AND CAST(et.tracked_at AS DATE) <= @end_date';
      request.input('end_date', sql.Date, endDate);
    }

    const result = await request.query(`
      SELECT TOP (@limit)
        et.user_id,
        et.exercise_id,
        et.duration,
        et.sets,
        et.reps,
        et.weight,
        et.calories_burned,
        et.notes,
        et.tracked_at,
        ext.name as exercise_name
      FROM Exercise_Tracking et
      LEFT JOIN Exercise_Translations ext ON et.exercise_id = ext.exercise_id AND ext.language_id = 1
      ${whereClause}
      ORDER BY et.tracked_at DESC
    `);

    return result.recordset;
  }


  // Delete exercise tracking
  async deleteExerciseTracking(
    userId: number,
    exerciseId: number,
    trackedAt: Date
  ): Promise<boolean> {
    const pool = getPool();

    const result = await pool.request()
      .input('user_id', sql.Int, userId)
      .input('exercise_id', sql.Int, exerciseId)
      .input('tracked_at', sql.DateTime, trackedAt)
      .query(`
        DELETE FROM Exercise_Tracking
        WHERE user_id = @user_id AND exercise_id = @exercise_id AND tracked_at = @tracked_at
      `);

    return result.rowsAffected[0] > 0;
  }

  // ============ MEAL TRACKING ============

  // Log meal with nutrition info
  async logMeal(
    userId: number,
    recipeId?: number,  // Changed from mealId to recipeId
    foodId?: number,    // Added foodId
    mealType?: string,
    mealName?: string,
    calories?: number,
    protein?: number,
    carbs?: number,
    fat?: number,
    notes?: string,
    quantity?: number,
    date?: Date
  ): Promise<MealTracking> {
    const pool = getPool();
    const trackingDate = date || new Date();

    await pool.request()
      .input('user_id', sql.Int, userId)
      .input('recipe_id', sql.Int, recipeId || null)
      .input('food_id', sql.Int, foodId || null)
      .input('meal_type', sql.NVarChar(50), mealType || 'Snack')
      .input('meal_name', sql.NVarChar(255), mealName || null)
      .input('calories', sql.Decimal(10, 2), calories || null)
      .input('protein', sql.Decimal(10, 2), protein || null)
      .input('carbs', sql.Decimal(10, 2), carbs || null)
      .input('fat', sql.Decimal(10, 2), fat || null)
      .input('notes', sql.NVarChar(500), notes || null)
      .input('quantity', sql.Decimal(10, 2), quantity || 100)
      .input('tracked_date', sql.Date, trackingDate)
      .query(`
        INSERT INTO Meal_Tracking (user_id, tracked_date, meal_type, recipe_id, food_id, meal_name, calories, protein, carbs, fat, quantity, notes)
        VALUES (@user_id, @tracked_date, @meal_type, @recipe_id, @food_id, @meal_name, @calories, @protein, @carbs, @fat, @quantity, @notes)
      `);

    // Get the newly created record
    const result = await pool.request()
      .input('user_id', sql.Int, userId)
      .input('tracked_date', sql.Date, trackingDate)
      .query(`
        SELECT TOP 1 * FROM Meal_Tracking 
        WHERE user_id = @user_id AND tracked_date = @tracked_date
        ORDER BY created_at DESC
      `);

    return result.recordset[0];
  }

  // Get user meal tracking
  async getMealTracking(
    userId: number,
    startDate?: Date,
    endDate?: Date
  ): Promise<MealTracking[]> {
    const pool = getPool();

    let whereClause = 'WHERE mt.user_id = @user_id';
    const request = pool.request().input('user_id', sql.Int, userId);

    if (startDate) {
      whereClause += ' AND mt.tracked_date >= @start_date';
      request.input('start_date', sql.Date, startDate);
    }
    if (endDate) {
      whereClause += ' AND mt.tracked_date <= @end_date';
      request.input('end_date', sql.Date, endDate);
    }

    const result = await request.query(`
      SELECT
        mt.user_id,
        mt.tracked_date,
        mt.meal_type,
        mt.recipe_id,
        mt.food_id,
        mt.meal_name,
        mt.calories,
        mt.protein,
        mt.carbs,
        mt.fat,
        mt.quantity,
        mt.notes,
        mt.created_at
      FROM Meal_Tracking mt
      ${whereClause}
      ORDER BY mt.tracked_date DESC, mt.created_at DESC
    `);

    return result.recordset;
  }

  // Delete meal tracking
  async deleteMealTracking(
    userId: number,
    trackedDate: Date,
    mealType: string,
    createdAt: Date
  ): Promise<boolean> {
    const pool = getPool();

    const result = await pool.request()
      .input('user_id', sql.Int, userId)
      .input('tracked_date', sql.Date, trackedDate)
      .input('meal_type', sql.NVarChar, mealType)
      .input('created_at', sql.DateTime, createdAt)
      .query(`
        DELETE FROM Meal_Tracking
        WHERE user_id = @user_id AND tracked_date = @tracked_date 
          AND meal_type = @meal_type AND created_at = @created_at
      `);

    return result.rowsAffected[0] > 0;
  }

  // ============ WEIGHT TRACKING ============

  // Log weight
  async logWeight(
    userId: number,
    weight: number,
    notes?: string,
    trackedAt?: Date
  ): Promise<WeightTracking> {
    const pool = getPool();
    const trackingDate = trackedAt || new Date();

    await pool.request()
      .input('user_id', sql.Int, userId)
      .input('weight', sql.Decimal(5, 2), weight)
      .input('notes', sql.NVarChar(500), notes || null)
      .input('tracked_at', sql.DateTime, trackingDate)
      .query(`
        INSERT INTO Weight_Tracking (user_id, weight, notes, tracked_at)
        VALUES (@user_id, @weight, @notes, @tracked_at)
      `);

    // Sync: Update user profile with new weight
    await pool.request()
      .input('user_id', sql.Int, userId)
      .input('weight', sql.Decimal(5, 2), weight)
      .query(`
        UPDATE Users SET weight = @weight WHERE user_id = @user_id
      `);

    // Get the newly created record
    const result = await pool.request()
      .input('user_id', sql.Int, userId)
      .input('tracked_at', sql.DateTime, trackingDate)
      .query(`
        SELECT TOP 1 * FROM Weight_Tracking 
        WHERE user_id = @user_id AND tracked_at = @tracked_at
        ORDER BY tracked_at DESC
      `);

    return result.recordset[0];
  }

  // Get weight history
  async getWeightHistory(
    userId: number,
    startDate?: Date,
    endDate?: Date,
    limit: number = 30
  ): Promise<WeightTracking[]> {
    const pool = getPool();

    const maxLimit = Math.min(Math.max(limit, 1), 100);

    let whereClause = 'WHERE user_id = @user_id';
    const request = pool.request()
      .input('user_id', sql.Int, userId)
      .input('limit', sql.Int, maxLimit);

    if (startDate) {
      whereClause += ' AND tracked_at >= @start_date';
      request.input('start_date', sql.DateTime, startDate);
    }
    if (endDate) {
      whereClause += ' AND tracked_at <= @end_date';
      request.input('end_date', sql.DateTime, endDate);
    }

    const result = await request.query(`
      SELECT TOP (@limit)
        user_id,
        weight,
        notes,
        tracked_at
      FROM Weight_Tracking
      ${whereClause}
      ORDER BY tracked_at DESC
    `);

    return result.recordset;
  }

  // Delete weight tracking
  async deleteWeightTracking(
    userId: number,
    trackedAt: Date
  ): Promise<boolean> {
    const pool = getPool();

    const result = await pool.request()
      .input('user_id', sql.Int, userId)
      .input('tracked_at', sql.DateTime, trackedAt)
      .query(`
        DELETE FROM Weight_Tracking
        WHERE user_id = @user_id AND tracked_at = @tracked_at
      `);

    return result.rowsAffected[0] > 0;
  }

  // ============ WATER TRACKING ============

  // Log water intake
  async logWater(
    userId: number,
    amountMl: number,
    notes?: string | null,
    trackedAt?: Date
  ): Promise<WaterTracking> {
    const pool = getPool();
    const trackingDate = trackedAt || new Date();

    await pool.request()
      .input('user_id', sql.Int, userId)
      .input('amount_ml', sql.Int, amountMl)
      .input('notes', sql.NVarChar(255), notes || null)
      .input('tracked_at', sql.DateTime, trackingDate)
      .query(`
        INSERT INTO Water_Tracking (user_id, amount_ml, notes, tracked_at)
        VALUES (@user_id, @amount_ml, @notes, @tracked_at)
      `);

    // Get the newly created record
    const result = await pool.request()
      .input('user_id', sql.Int, userId)
      .input('tracked_at', sql.DateTime, trackingDate)
      .query(`
        SELECT TOP 1 * FROM Water_Tracking 
        WHERE user_id = @user_id AND tracked_at = @tracked_at
        ORDER BY tracked_at DESC
      `);

    return result.recordset[0];
  }

  // Get water history
  async getWaterHistory(
    userId: number,
    startDate?: Date,
    endDate?: Date,
    limit: number = 50
  ): Promise<WaterTracking[]> {
    const pool = getPool();

    const maxLimit = Math.min(Math.max(limit, 1), 100);

    let whereClause = 'WHERE user_id = @user_id';
    const request = pool.request()
      .input('user_id', sql.Int, userId)
      .input('limit', sql.Int, maxLimit);

    if (startDate) {
      whereClause += ' AND CAST(tracked_at AS DATE) >= @start_date';
      request.input('start_date', sql.Date, startDate);
    }
    if (endDate) {
      whereClause += ' AND CAST(tracked_at AS DATE) <= @end_date';
      request.input('end_date', sql.Date, endDate);
    }

    const result = await request.query(`
      SELECT TOP (@limit)
        user_id,
        amount_ml,
        notes,
        tracked_at
      FROM Water_Tracking
      ${whereClause}
      ORDER BY tracked_at DESC
    `);

    return result.recordset;
  }

  // Get daily water intake
  async getDailyWaterIntake(userId: number, date: Date = new Date()): Promise<{
    totalMl: number;
    entries: number;
    goal: number;
  }> {
    const pool = getPool();

    // Get water intake for the day
    const waterResult = await pool.request()
      .input('user_id', sql.Int, userId)
      .input('date', sql.Date, date)
      .query(`
        SELECT 
          COALESCE(SUM(amount_ml), 0) as total_ml,
          COUNT(*) as entries
        FROM Water_Tracking
        WHERE user_id = @user_id AND CAST(tracked_at AS DATE) = @date
      `);

    // Get water goal
    const goalResult = await pool.request()
      .input('user_id', sql.Int, userId)
      .query(`
        SELECT COALESCE(water_goal_ml, 2000) as water_goal
        FROM User_Goals
        WHERE user_id = @user_id
      `);

    const waterData = waterResult.recordset[0];
    const goalData = goalResult.recordset[0];

    return {
      totalMl: waterData.total_ml,
      entries: waterData.entries,
      goal: goalData?.water_goal || 2000,
    };
  }

  // Get weekly water summary (7 days, aggregated per day)
  async getWeeklyWaterSummary(userId: number): Promise<{
    date: string;
    totalMl: number;
  }[]> {
    const pool = getPool();

    // Get water goal for progress calculation
    const goalResult = await pool.request()
      .input('user_id', sql.Int, userId)
      .query(`
        SELECT COALESCE(water_goal_ml, 2000) as water_goal
        FROM User_Goals
        WHERE user_id = @user_id
      `);
    const goal = goalResult.recordset[0]?.water_goal || 2000;

    const result = await pool.request()
      .input('user_id', sql.Int, userId)
      .query(`
        WITH DateRange AS (
          SELECT CAST(DATEADD(day, -6, GETDATE()) AS DATE) as date
          UNION ALL
          SELECT DATEADD(day, 1, date)
          FROM DateRange
          WHERE date < CAST(GETDATE() AS DATE)
        )
        SELECT
          CONVERT(varchar, dr.date, 23) as date,
          COALESCE(SUM(wt.amount_ml), 0) as total_ml
        FROM DateRange dr
        LEFT JOIN Water_Tracking wt ON CAST(wt.tracked_at AS DATE) = dr.date AND wt.user_id = @user_id
        GROUP BY dr.date
        ORDER BY dr.date
      `);

    return result.recordset.map((r: { date: string; total_ml: number }) => ({
      date: r.date,
      totalMl: r.total_ml,
    }));
  }

  // Delete water tracking
  async deleteWaterTracking(
    userId: number,
    trackedAt: Date
  ): Promise<boolean> {
    const pool = getPool();

    const result = await pool.request()
      .input('user_id', sql.Int, userId)
      .input('tracked_at', sql.DateTime, trackedAt)
      .query(`
        DELETE FROM Water_Tracking
        WHERE user_id = @user_id AND tracked_at = @tracked_at
      `);

    return result.rowsAffected[0] > 0;
  }

  // ============ DASHBOARD STATS ============

  // Get daily stats
  async getDailyStats(userId: number, date: Date = new Date()): Promise<{
    totalCaloriesBurned: number;
    totalCaloriesConsumed: number;
    totalProtein: number;
    totalCarbs: number;
    totalFat: number;
    totalExerciseMinutes: number;
    exercisesCompleted: number;
    mealsLogged: number;
  }> {
    const pool = getPool();

    // Exercise stats
    const exerciseStats = await pool.request()
      .input('user_id', sql.Int, userId)
      .input('date', sql.Date, date)
      .query(`
        SELECT
          COALESCE(SUM(calories_burned), 0) as total_calories_burned,
          COALESCE(SUM(duration), 0) as total_minutes,
          COUNT(*) as exercises_completed
        FROM Exercise_Tracking
        WHERE user_id = @user_id AND CAST(tracked_at AS DATE) = @date
      `);

    // Meal stats with nutrition (directly from Meal_Tracking)
    const mealStats = await pool.request()
      .input('user_id', sql.Int, userId)
      .input('date', sql.Date, date)
      .query(`
        SELECT 
          COUNT(*) as meals_logged,
          COALESCE(SUM(calories), 0) as total_calories,
          COALESCE(SUM(protein), 0) as total_protein,
          COALESCE(SUM(carbs), 0) as total_carbs,
          COALESCE(SUM(fat), 0) as total_fat
        FROM Meal_Tracking
        WHERE user_id = @user_id AND tracked_date = @date
      `);

    const exerciseData = exerciseStats.recordset[0];
    const mealData = mealStats.recordset[0];

    return {
      totalCaloriesBurned: Math.round(exerciseData.total_calories_burned),
      totalCaloriesConsumed: Math.round(mealData.total_calories || 0),
      totalProtein: Math.round(mealData.total_protein || 0),
      totalCarbs: Math.round(mealData.total_carbs || 0),
      totalFat: Math.round(mealData.total_fat || 0),
      totalExerciseMinutes: exerciseData.total_minutes,
      exercisesCompleted: exerciseData.exercises_completed,
      mealsLogged: mealData.meals_logged,
    };
  }

  // Get weekly stats
  async getWeeklyStats(userId: number): Promise<{
    date: Date;
    caloriesBurned: number;
    caloriesConsumed: number;
    protein: number;
    carbs: number;
    fat: number;
    exerciseMinutes: number;
    exercisesCompleted: number;
    mealsLogged: number;
  }[]> {
    const pool = getPool();

    const result = await pool.request()
      .input('user_id', sql.Int, userId)
      .query(`
        WITH DateRange AS (
          SELECT CAST(DATEADD(day, -6, GETDATE()) AS DATE) as date
          UNION ALL
          SELECT DATEADD(day, 1, date)
          FROM DateRange
          WHERE date < CAST(GETDATE() AS DATE)
        )
        SELECT
          dr.date,
          COALESCE(SUM(et.calories_burned), 0) as calories_burned,
          COALESCE(SUM(et.duration), 0) as exercise_minutes,
          COUNT(DISTINCT CONCAT(et.user_id, '-', et.exercise_id, '-', et.tracked_at)) as exercises_completed,
          COUNT(DISTINCT CONCAT(mt.user_id, '-', mt.tracked_date, '-', mt.meal_type, '-', mt.created_at)) as meals_logged,
          COALESCE(SUM(mt.calories), 0) as calories_consumed,
          COALESCE(SUM(mt.protein), 0) as protein,
          COALESCE(SUM(mt.carbs), 0) as carbs,
          COALESCE(SUM(mt.fat), 0) as fat
        FROM DateRange dr
        LEFT JOIN Exercise_Tracking et ON dr.date = CAST(et.tracked_at AS DATE) AND et.user_id = @user_id
        LEFT JOIN Meal_Tracking mt ON dr.date = mt.tracked_date AND mt.user_id = @user_id
        GROUP BY dr.date
        ORDER BY dr.date
      `);

    return result.recordset.map((r: {
      date: Date;
      calories_burned: number;
      calories_consumed: number;
      protein: number;
      carbs: number;
      fat: number;
      exercise_minutes: number;
      exercises_completed: number;
      meals_logged: number;
    }) => ({
      date: r.date,
      caloriesBurned: r.calories_burned,
      caloriesConsumed: r.calories_consumed,
      protein: r.protein,
      carbs: r.carbs,
      fat: r.fat,
      exerciseMinutes: r.exercise_minutes,
      exercisesCompleted: r.exercises_completed,
      mealsLogged: r.meals_logged,
    }));
  }
}

export const trackingService = new TrackingService();

