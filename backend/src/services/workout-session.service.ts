import { getPool, sql } from '../config/database';
import { WorkoutSession, WorkoutSessionDetail } from '../types';

export class WorkoutSessionService {
  // Start a new workout session
  async startSession(
    userId: number,
    planId?: number,
    exerciseId?: number,
    name?: string
  ): Promise<WorkoutSession> {
    const pool = getPool();

    // Validate: must have either planId or exerciseId
    // Relaxed validation to allow freestyle sessions
    // if (!planId && !exerciseId) {
    //     throw new Error('Either plan_id or exercise_id is required');
    // }

    const result = await pool.request()
      .input('user_id', sql.Int, userId)
      .input('plan_id', sql.Int, planId || null)
      .input('exercise_id', sql.Int, exerciseId || null)
      .input('name', sql.NVarChar, name || null)
      .query(`
        INSERT INTO Workout_Sessions (user_id, plan_id, exercise_id, name, status)
        OUTPUT INSERTED.*
        VALUES (@user_id, @plan_id, @exercise_id, @name, 'in_progress')
      `);

    const session = result.recordset[0];

    // If plan-based workout, create session details from plan
    if (planId) {
      await this.createSessionDetailsFromPlan(session.session_id, planId);
    } else if (exerciseId) {
      // Single exercise workout - create one detail entry
      await pool.request()
        .input('session_id', sql.Int, session.session_id)
        .input('exercise_id', sql.Int, exerciseId)
        .query(`
          INSERT INTO Workout_Session_Details 
          (session_id, exercise_id, target_sets, target_reps, rest_duration, order_index)
          VALUES (@session_id, @exercise_id, 3, 10, 60, 0)
        `);
    }

    return session;
  }

  // Create session details from a plan
  private async createSessionDetailsFromPlan(sessionId: number, planId: number): Promise<void> {
    const pool = getPool();

    await pool.request()
      .input('session_id', sql.Int, sessionId)
      .input('plan_id', sql.Int, planId)
      .query(`
        INSERT INTO Workout_Session_Details 
        (session_id, exercise_id, target_sets, target_reps, rest_duration, order_index)
        SELECT 
          @session_id,
          pd.exercise_id,
          ISNULL(pd.sets, 3),
          ISNULL(pd.reps, 10),
          ISNULL(pd.rest_duration, 60),
          ROW_NUMBER() OVER (ORDER BY pd.order_index, pd.exercise_id) - 1 as order_index
        FROM Plan_Details pd
        WHERE pd.plan_id = @plan_id AND pd.exercise_id IS NOT NULL
      `);
  }

  // Get session by ID with details
  async getSessionById(sessionId: number, languageId: number = 1): Promise<WorkoutSession | null> {
    const pool = getPool();

    const sessionResult = await pool.request()
      .input('session_id', sql.Int, sessionId)
      .query(`
        SELECT * FROM Workout_Sessions WHERE session_id = @session_id
      `);

    if (sessionResult.recordset.length === 0) {
      return null;
    }

    const session = sessionResult.recordset[0];

    // Get session details with exercise info
    const detailsResult = await pool.request()
      .input('session_id', sql.Int, sessionId)
      .input('language_id', sql.Int, languageId)
      .query(`
        SELECT 
          wsd.*,
          et.name as exercise_name,
          e.level,
          e.equipment,
          e.category
        FROM Workout_Session_Details wsd
        JOIN Exercises e ON wsd.exercise_id = e.exercise_id
        LEFT JOIN Exercise_Translations et ON e.exercise_id = et.exercise_id 
          AND et.language_id = @language_id
        WHERE wsd.session_id = @session_id
        ORDER BY wsd.order_index
      `);

    return {
      ...session,
      details: detailsResult.recordset,
    };
  }

  // Get user's active session (in_progress)
  async getActiveSession(userId: number): Promise<WorkoutSession | null> {
    const pool = getPool();

    const result = await pool.request()
      .input('user_id', sql.Int, userId)
      .query(`
        SELECT TOP 1 * FROM Workout_Sessions 
        WHERE user_id = @user_id AND status = 'in_progress'
        ORDER BY started_at DESC
      `);

    if (result.recordset.length === 0) {
      return null;
    }

    return this.getSessionById(result.recordset[0].session_id);
  }

  // Update exercise progress in session
  async updateExerciseProgress(
    sessionId: number,
    exerciseId: number,
    setsCompleted: number,
    repsCompleted?: string,
    weightUsed?: string,
    notes?: string,
    orderIndex?: number,
    startedAt?: Date,
    completedAt?: Date
  ): Promise<WorkoutSessionDetail | null> {
    const pool = getPool();

    console.log(`🔄 Updating exercise progress: session=${sessionId}, exercise=${exerciseId}, sets=${setsCompleted}, reps=${repsCompleted}, orderIndex=${orderIndex}`);
    console.log(`🔄 Timing: startedAt=${startedAt}, completedAt=${completedAt}`);

    // If orderIndex not provided, find the first one for this exercise
    let targetOrderIndex = orderIndex;
    if (targetOrderIndex === undefined) {
      const findResult = await pool.request()
        .input('session_id', sql.Int, sessionId)
        .input('exercise_id', sql.Int, exerciseId)
        .query(`
          SELECT TOP 1 order_index FROM Workout_Session_Details
          WHERE session_id = @session_id AND exercise_id = @exercise_id
          ORDER BY order_index
        `);
      if (findResult.recordset.length > 0) {
        targetOrderIndex = findResult.recordset[0].order_index;
      } else {
        return null;
      }
    }

    // Build dynamic update for started_at and completed_at
    const result = await pool.request()
      .input('session_id', sql.Int, sessionId)
      .input('exercise_id', sql.Int, exerciseId)
      .input('order_index', sql.Int, targetOrderIndex)
      .input('sets_completed', sql.Int, setsCompleted)
      .input('reps_completed', sql.NVarChar, repsCompleted || null)
      .input('weight_used', sql.NVarChar, weightUsed || null)
      .input('notes', sql.NVarChar, notes || null)
      .input('started_at', sql.DateTime, startedAt || null)
      .input('completed_at', sql.DateTime, completedAt || null)
      .query(`
        UPDATE Workout_Session_Details
        SET 
          sets_completed = @sets_completed,
          reps_completed = @reps_completed,
          weight_used = @weight_used,
          notes = @notes,
          started_at = CASE
            WHEN @started_at IS NOT NULL THEN @started_at
            WHEN started_at IS NULL THEN GETDATE()
            ELSE started_at
          END,
          completed_at = CASE
            WHEN @completed_at IS NOT NULL THEN @completed_at
            ELSE completed_at
          END
        OUTPUT INSERTED.*
        WHERE session_id = @session_id AND exercise_id = @exercise_id AND order_index = @order_index
      `);

    if (result.recordset[0]) {
      console.log(`✅ Updated: order_index=${result.recordset[0].order_index}, started_at=${result.recordset[0].started_at}, completed_at=${result.recordset[0].completed_at}, target_sets=${result.recordset[0].target_sets}`);
    }

    return result.recordset[0] || null;
  }

  // Complete workout session
  async completeSession(sessionId: number, notes?: string, totalDurationSeconds?: number): Promise<WorkoutSession | null> {
    const pool = getPool();

    console.log(`🏁 completeSession called: sessionId=${sessionId}, notes=${notes}, totalDurationSeconds=${totalDurationSeconds}`);

    // Get session with user info before completing
    const sessionQuery = await pool.request()
      .input('session_id', sql.Int, sessionId)
      .query(`SELECT user_id, started_at FROM Workout_Sessions WHERE session_id = @session_id`);

    if (sessionQuery.recordset.length === 0) {
      return null;
    }
    const userId = sessionQuery.recordset[0].user_id;
    const sessionStartedAt = sessionQuery.recordset[0].started_at;

    console.log(`🏁 Session started_at: ${sessionStartedAt}`);

    // Use provided duration or calculate from start time
    const duration = totalDurationSeconds || null;

    console.log(`🏁 Duration to save: ${duration}s (from client: ${totalDurationSeconds})`);

    // Calculate total duration and complete session
    const result = await pool.request()
      .input('session_id', sql.Int, sessionId)
      .input('notes', sql.NVarChar, notes || null)
      .input('total_duration', sql.Int, duration)
      .query(`
        UPDATE Workout_Sessions
        SET 
          status = 'completed',
          completed_at = GETDATE(),
          total_duration = ISNULL(@total_duration, DATEDIFF(SECOND, started_at, GETDATE())),
          notes = ISNULL(@notes, notes)
        OUTPUT INSERTED.*
        WHERE session_id = @session_id AND status = 'in_progress'
      `);

    if (result.recordset.length === 0) {
      return null;
    }

    // Get the actual total duration (from DB result) - in seconds
    const dbTotalDuration = result.recordset[0].total_duration;
    console.log(`🏁 DB returned total_duration: ${dbTotalDuration}s`);

    const actualTotalDuration = dbTotalDuration || totalDurationSeconds || 60;

    // Convert to minutes for display
    const totalDurationMinutes = Math.max(1, Math.round(actualTotalDuration / 60));

    console.log(`🏁 Using actualTotalDuration: ${actualTotalDuration}s = ${totalDurationMinutes} min`);

    // Save each exercise to Exercise_Tracking for history
    // Log ALL exercises in the session (regardless of is_completed flag)
    const details = await pool.request()
      .input('session_id', sql.Int, sessionId)
      .query(`
        SELECT * FROM Workout_Session_Details
        WHERE session_id = @session_id
      `);

    const exerciseCount = details.recordset.length || 1;

    // Fallback: divide total time by number of exercises if individual times not available
    const fallbackDurationPerExercise = Math.max(1, Math.round(totalDurationMinutes / exerciseCount));

    console.log(`📊 Total duration: ${actualTotalDuration}s (${totalDurationMinutes} min), exercises: ${exerciseCount}, fallback per exercise: ${fallbackDurationPerExercise} min`);

    for (const detail of details.recordset) {
      console.log('📊 Processing detail:', {
        exercise_id: detail.exercise_id,
        sets_completed: detail.sets_completed,
        reps_completed: detail.reps_completed,
        target_reps: detail.target_reps,
        started_at: detail.started_at,
        completed_at: detail.completed_at
      });

      // repsPerSet = số reps mỗi set (không phải tổng)
      let repsPerSet = detail.target_reps || 10; // default to target reps
      if (detail.reps_completed) {
        try {
          const parsed = JSON.parse(detail.reps_completed);
          if (Array.isArray(parsed)) {
            // If array, use average reps per set
            repsPerSet = parsed.length > 0
              ? Math.round(parsed.reduce((sum: number, r: number) => sum + (r || 0), 0) / parsed.length)
              : detail.target_reps || 10;
          } else {
            repsPerSet = parseInt(detail.reps_completed) || detail.target_reps || 10;
          }
        } catch {
          repsPerSet = parseInt(detail.reps_completed) || detail.target_reps || 10;
        }
      }

      const setsCompleted = detail.sets_completed || 0;

      // Tính calories dựa trên tổng số reps thực tế (sets * reps_per_set)
      const totalRepsForCalories = setsCompleted * repsPerSet;
      const estimatedCalories = totalRepsForCalories * 0.5;

      // Calculate ACTUAL duration from started_at to completed_at
      let durationMinutes = fallbackDurationPerExercise;
      if (detail.started_at && detail.completed_at) {
        const startTime = new Date(detail.started_at).getTime();
        const endTime = new Date(detail.completed_at).getTime();
        const diffMs = endTime - startTime;
        if (diffMs > 0) {
          durationMinutes = Math.max(1, Math.round(diffMs / 60000)); // Convert ms to minutes
          console.log(`📊 Actual duration for exercise ${detail.exercise_id}: ${diffMs}ms = ${durationMinutes} min`);
        }
      }

      console.log('💾 Saving to Exercise_Tracking:', {
        user_id: userId,
        exercise_id: detail.exercise_id,
        duration: durationMinutes,
        sets: setsCompleted,
        reps: repsPerSet,  // Lưu reps per set, không phải tổng
        calories: estimatedCalories
      });

      await pool.request()
        .input('user_id', sql.Int, userId)
        .input('exercise_id', sql.Int, detail.exercise_id)
        .input('duration', sql.Int, durationMinutes || 1)
        .input('sets', sql.Int, setsCompleted)
        .input('reps', sql.Int, repsPerSet)  // Lưu reps per set
        .input('calories_burned', sql.Decimal(10, 2), estimatedCalories || 0)
        .input('tracked_at', sql.DateTime, new Date())
        .query(`
          INSERT INTO Exercise_Tracking 
          (user_id, exercise_id, duration, sets, reps, calories_burned, tracked_at)
          VALUES (@user_id, @exercise_id, @duration, @sets, @reps, @calories_burned, @tracked_at)
        `);
    }

    return this.getSessionById(sessionId);
  }

  // Cancel workout session
  async cancelSession(sessionId: number): Promise<boolean> {
    const pool = getPool();

    const result = await pool.request()
      .input('session_id', sql.Int, sessionId)
      .query(`
        UPDATE Workout_Sessions
        SET status = 'cancelled', completed_at = GETDATE()
        WHERE session_id = @session_id AND status = 'in_progress'
      `);

    return result.rowsAffected[0] > 0;
  }

  // Get user's workout history
  async getSessionHistory(
    userId: number,
    page: number = 1,
    limit: number = 20
  ): Promise<{ sessions: WorkoutSession[]; total: number }> {
    const pool = getPool();
    const offset = (page - 1) * limit;

    // Get total count
    const countResult = await pool.request()
      .input('user_id', sql.Int, userId)
      .query(`
        SELECT COUNT(*) as total FROM Workout_Sessions 
        WHERE user_id = @user_id AND status = 'completed'
      `);

    const total = countResult.recordset[0].total;

    // Get sessions
    const result = await pool.request()
      .input('user_id', sql.Int, userId)
      .input('offset', sql.Int, offset)
      .input('limit', sql.Int, limit)
      .query(`
        SELECT 
          ws.*,
          p.description as plan_name,
          (SELECT COUNT(*) FROM Workout_Session_Details WHERE session_id = ws.session_id) as exercise_count
        FROM Workout_Sessions ws
        LEFT JOIN Plans p ON ws.plan_id = p.plan_id
        WHERE ws.user_id = @user_id AND ws.status = 'completed'
        ORDER BY ws.completed_at DESC
        OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
      `);

    return {
      sessions: result.recordset,
      total,
    };
  }
}

export const workoutSessionService = new WorkoutSessionService();
