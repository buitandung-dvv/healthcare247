import { getPool, sql } from '../config/database';
import { Plan, PlanDetail } from '../types';

export class PlanService {
  // Get user plans with details
  async getUserPlans(userId: number, languageId: number = 1): Promise<Plan[]> {
    const pool = getPool();

    // Get all plans for user
    const plansResult = await pool.request()
      .input('user_id', sql.Int, userId)
      .query(`
        SELECT plan_id, user_id, name, plan_type, description, created_at
        FROM Plans
        WHERE user_id = @user_id
        ORDER BY created_at DESC
      `);

    const plans = plansResult.recordset;

    // Get details for all plans
    if (plans.length > 0) {
      const planIds = plans.map(p => p.plan_id);

      const detailsResult = await pool.request()
        .input('language_id', sql.Int, languageId)
        .query(`
          SELECT
            pd.plan_id,
            pd.day_of_week,
            pd.exercise_id,
            pd.recipe_id,
            pd.sets,
            pd.reps,
            pd.rest_duration,
            pd.order_index,
            et.name as exercise_name,
            e.images as exercise_images,
            rt.name as recipe_name
          FROM Plan_Details pd
          LEFT JOIN Exercise_Translations et ON pd.exercise_id = et.exercise_id AND et.language_id = @language_id
          LEFT JOIN Exercises e ON pd.exercise_id = e.exercise_id
          LEFT JOIN Recipe_Translations rt ON pd.recipe_id = rt.recipe_id AND rt.language_id = @language_id
          WHERE pd.plan_id IN (${planIds.join(',')})
          ORDER BY pd.day_of_week, pd.order_index
        `);

      // Group details by plan_id
      const detailsByPlanId: Record<number, any[]> = {};
      for (const detail of detailsResult.recordset) {
        if (!detailsByPlanId[detail.plan_id]) {
          detailsByPlanId[detail.plan_id] = [];
        }
        detailsByPlanId[detail.plan_id].push(detail);
      }

      // Attach details to plans
      for (const plan of plans) {
        plan.details = detailsByPlanId[plan.plan_id] || [];
      }
    }

    return plans;
  }

  // Get plan by ID with details
  async getPlanById(planId: number, languageId: number = 1): Promise<Plan | null> {
    const pool = getPool();

    const planResult = await pool.request()
      .input('plan_id', sql.Int, planId)
      .query(`
        SELECT plan_id, user_id, name, plan_type, description, created_at
        FROM Plans
        WHERE plan_id = @plan_id
      `);

    if (planResult.recordset.length === 0) {
      return null;
    }

    const plan = planResult.recordset[0];

    // Get plan details
    const detailsResult = await pool.request()
      .input('plan_id', sql.Int, planId)
      .input('language_id', sql.Int, languageId)
      .query(`
        SELECT
          pd.plan_id,
          pd.day_of_week,
          pd.exercise_id,
          pd.recipe_id,
          pd.sets,
          pd.reps,
          pd.rest_duration,
          pd.order_index,
          et.name as exercise_name,
          e.images as exercise_images,
          rt.name as recipe_name
        FROM Plan_Details pd
        LEFT JOIN Exercise_Translations et ON pd.exercise_id = et.exercise_id AND et.language_id = @language_id
        LEFT JOIN Exercises e ON pd.exercise_id = e.exercise_id
        LEFT JOIN Recipe_Translations rt ON pd.recipe_id = rt.recipe_id AND rt.language_id = @language_id
        WHERE pd.plan_id = @plan_id
        ORDER BY pd.day_of_week, pd.order_index
      `);

    return {
      ...plan,
      details: detailsResult.recordset,
    };
  }

  // Create plan
  async createPlan(
    userId: number,
    planType?: string,
    description?: string,
    name?: string
  ): Promise<Plan> {
    const pool = getPool();

    const result = await pool.request()
      .input('user_id', sql.Int, userId)
      .input('name', sql.NVarChar, name || null)
      .input('plan_type', sql.NVarChar, planType || null)
      .input('description', sql.NVarChar, description || null)
      .query(`
        INSERT INTO Plans (user_id, name, plan_type, description)
        OUTPUT INSERTED.*
        VALUES (@user_id, @name, @plan_type, @description)
      `);

    return result.recordset[0];
  }

  // Add detail to plan
  async addPlanDetail(
    planId: number,
    dayOfWeek: number,
    exerciseId?: number,
    recipeId?: number, // Changed from mealId to match database schema
    sets?: number,
    reps?: number,
    restDuration?: number,
    orderIndex?: number
  ): Promise<PlanDetail> {
    const pool = getPool();

    const result = await pool.request()
      .input('plan_id', sql.Int, planId)
      .input('day_of_week', sql.Int, dayOfWeek)
      .input('exercise_id', sql.Int, exerciseId || null)
      .input('recipe_id', sql.Int, recipeId || null)
      .input('sets', sql.Int, sets || 3)
      .input('reps', sql.Int, reps || 10)
      .input('rest_duration', sql.Int, restDuration || 60)
      .input('order_index', sql.Int, orderIndex || 0)
      .query(`
        INSERT INTO Plan_Details (
          plan_id, day_of_week, exercise_id, recipe_id,
          sets, reps, rest_duration, order_index
        )
        OUTPUT INSERTED.*
        VALUES (
          @plan_id, @day_of_week, @exercise_id, @recipe_id,
          @sets, @reps, @rest_duration, @order_index
        )
      `);

    return result.recordset[0];
  }

  // Delete plan detail
  async deletePlanDetail(detailId: number): Promise<boolean> {
    const pool = getPool();

    const result = await pool.request()
      .input('detail_id', sql.Int, detailId)
      .query(`DELETE FROM Plan_Details WHERE detail_id = @detail_id`);

    return result.rowsAffected[0] > 0;
  }

  // Delete plan
  async deletePlan(planId: number, userId: number): Promise<boolean> {
    const pool = getPool();

    const result = await pool.request()
      .input('plan_id', sql.Int, planId)
      .input('user_id', sql.Int, userId)
      .query(`DELETE FROM Plans WHERE plan_id = @plan_id AND user_id = @user_id`);

    return result.rowsAffected[0] > 0;
  }

  // Update plan
  async updatePlan(
    planId: number,
    userId: number,
    data: { name?: string; description?: string }
  ): Promise<Plan | null> {
    const pool = getPool();

    // Build dynamic SET clause
    const setClauses: string[] = [];
    const request = pool.request()
      .input('plan_id', sql.Int, planId)
      .input('user_id', sql.Int, userId);

    if (data.name !== undefined) {
      setClauses.push('name = @name');
      request.input('name', sql.NVarChar, data.name);
    }
    if (data.description !== undefined) {
      setClauses.push('description = @description');
      request.input('description', sql.NVarChar, data.description);
    }

    if (setClauses.length === 0) {
      // Nothing to update, just return existing plan
      const existing = await this.getPlanById(planId, 1);
      return existing;
    }

    const result = await request.query(`
      UPDATE Plans SET ${setClauses.join(', ')}
      OUTPUT INSERTED.*
      WHERE plan_id = @plan_id AND user_id = @user_id
    `);

    return result.recordset[0] || null;
  }

  // Clear all details from a plan
  async clearPlanDetails(planId: number): Promise<void> {
    const pool = getPool();

    await pool.request()
      .input('plan_id', sql.Int, planId)
      .query(`DELETE FROM Plan_Details WHERE plan_id = @plan_id`);
  }
}

export const planService = new PlanService();

