import { getPool, sql } from '../config/database';

export interface UserGoals {
    goal_id: number;
    user_id: number;
    calories_goal: number;
    protein_goal: number;
    carbs_goal: number;
    fat_goal: number;
    water_goal_ml: number;
    workouts_per_week: number;
    created_at: Date;
    updated_at: Date;
}

export interface UpdateGoalsDTO {
    calories_goal?: number;
    protein_goal?: number;
    carbs_goal?: number;
    fat_goal?: number;
    water_goal_ml?: number;
    workouts_per_week?: number;
}

export class GoalsService {
    // Get user goals
    async getUserGoals(userId: number): Promise<UserGoals | null> {
        const pool = getPool();

        const result = await pool.request()
            .input('user_id', sql.Int, userId)
            .query(`
        SELECT goal_id, user_id, calories_goal, protein_goal, carbs_goal, 
               fat_goal, water_goal_ml, workouts_per_week, created_at, updated_at
        FROM User_Goals
        WHERE user_id = @user_id
      `);

        return result.recordset[0] || null;
    }

    // Update user goals
    async updateUserGoals(userId: number, data: UpdateGoalsDTO): Promise<UserGoals | null> {
        const pool = getPool();

        const updates: string[] = ['updated_at = GETDATE()'];
        const request = pool.request().input('user_id', sql.Int, userId);

        if (data.calories_goal !== undefined) {
            updates.push('calories_goal = @calories_goal');
            request.input('calories_goal', sql.Decimal(10, 2), data.calories_goal);
        }
        if (data.protein_goal !== undefined) {
            updates.push('protein_goal = @protein_goal');
            request.input('protein_goal', sql.Decimal(10, 2), data.protein_goal);
        }
        if (data.carbs_goal !== undefined) {
            updates.push('carbs_goal = @carbs_goal');
            request.input('carbs_goal', sql.Decimal(10, 2), data.carbs_goal);
        }
        if (data.fat_goal !== undefined) {
            updates.push('fat_goal = @fat_goal');
            request.input('fat_goal', sql.Decimal(10, 2), data.fat_goal);
        }
        if (data.water_goal_ml !== undefined) {
            updates.push('water_goal_ml = @water_goal_ml');
            request.input('water_goal_ml', sql.Int, data.water_goal_ml);
        }
        if (data.workouts_per_week !== undefined) {
            updates.push('workouts_per_week = @workouts_per_week');
            request.input('workouts_per_week', sql.Int, data.workouts_per_week);
        }

        const result = await request.query(`
      UPDATE User_Goals 
      SET ${updates.join(', ')}
      OUTPUT INSERTED.*
      WHERE user_id = @user_id
    `);

        return result.recordset[0] || null;
    }

    // Create default goals for user
    async createDefaultGoals(userId: number, userGoal?: string): Promise<UserGoals> {
        const pool = getPool();

        const caloriesGoal = userGoal === 'lose_weight' ? 1500 : userGoal === 'build_muscle' ? 2500 : 2000;
        const proteinGoal = userGoal === 'build_muscle' ? 180 : 150;
        const workoutsPerWeek = userGoal === 'build_muscle' ? 5 : 3;

        const result = await pool.request()
            .input('user_id', sql.Int, userId)
            .input('calories_goal', sql.Decimal(10, 2), caloriesGoal)
            .input('protein_goal', sql.Decimal(10, 2), proteinGoal)
            .input('carbs_goal', sql.Decimal(10, 2), 250)
            .input('fat_goal', sql.Decimal(10, 2), 65)
            .input('water_goal_ml', sql.Int, 2000)
            .input('workouts_per_week', sql.Int, workoutsPerWeek)
            .query(`
        INSERT INTO User_Goals (user_id, calories_goal, protein_goal, carbs_goal, fat_goal, water_goal_ml, workouts_per_week)
        OUTPUT INSERTED.*
        VALUES (@user_id, @calories_goal, @protein_goal, @carbs_goal, @fat_goal, @water_goal_ml, @workouts_per_week)
      `);

        return result.recordset[0];
    }

    // Get or create goals
    async getOrCreateGoals(userId: number, userGoal?: string): Promise<UserGoals> {
        let goals = await this.getUserGoals(userId);

        if (!goals) {
            goals = await this.createDefaultGoals(userId, userGoal);
        }

        return goals;
    }
}

export const goalsService = new GoalsService();
