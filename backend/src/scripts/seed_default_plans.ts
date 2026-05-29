/**
 * Seed Default Plans - Tạo kế hoạch tập luyện & ăn uống mặc định
 * 
 * Chạy: npx tsx src/scripts/seed_default_plans.ts
 */
import { connectDB, getPool, sql, closeDB } from '../config/database';

// ─── Workout Plan Templates ───────────────────────────────────────
interface PlanTemplate {
    name: string;
    plan_type: string;
    description: string;
    schedule_days: string; // "1,3,5" = Mon,Wed,Fri
    exercises: {
        slug_pattern: string; // partial match on exercise slug
        sets: number;
        reps: number;
        rest_duration: number;
    }[];
}

const WORKOUT_PLANS: PlanTemplate[] = [
    {
        name: 'Upper Body Day',
        plan_type: 'workout',
        description: 'Focus on chest, shoulders, arms and back',
        schedule_days: '1,4', // Mon, Thu
        exercises: [
            { slug_pattern: '%bench%press%', sets: 4, reps: 10, rest_duration: 90 },
            { slug_pattern: '%shoulder%press%', sets: 3, reps: 12, rest_duration: 60 },
            { slug_pattern: '%bicep%curl%', sets: 3, reps: 12, rest_duration: 60 },
            { slug_pattern: '%tricep%', sets: 3, reps: 12, rest_duration: 60 },
            { slug_pattern: '%lat%pull%', sets: 3, reps: 10, rest_duration: 90 },
            { slug_pattern: '%row%', sets: 3, reps: 12, rest_duration: 60 },
        ],
    },
    {
        name: 'Lower Body Day',
        plan_type: 'workout',
        description: 'Focus on quads, hamstrings, glutes and calves',
        schedule_days: '2,5', // Tue, Fri
        exercises: [
            { slug_pattern: '%squat%', sets: 4, reps: 10, rest_duration: 120 },
            { slug_pattern: '%lunge%', sets: 3, reps: 12, rest_duration: 60 },
            { slug_pattern: '%leg%press%', sets: 3, reps: 12, rest_duration: 90 },
            { slug_pattern: '%leg%curl%', sets: 3, reps: 12, rest_duration: 60 },
            { slug_pattern: '%calf%raise%', sets: 4, reps: 15, rest_duration: 45 },
            { slug_pattern: '%deadlift%', sets: 3, reps: 8, rest_duration: 120 },
        ],
    },
    {
        name: 'Full Body Workout',
        plan_type: 'workout',
        description: 'Complete full body training session',
        schedule_days: '3,6', // Wed, Sat
        exercises: [
            { slug_pattern: '%push%up%', sets: 3, reps: 15, rest_duration: 60 },
            { slug_pattern: '%squat%', sets: 3, reps: 12, rest_duration: 90 },
            { slug_pattern: '%plank%', sets: 3, reps: 30, rest_duration: 45 },
            { slug_pattern: '%pull%up%', sets: 3, reps: 8, rest_duration: 90 },
            { slug_pattern: '%crunch%', sets: 3, reps: 20, rest_duration: 45 },
            { slug_pattern: '%burpee%', sets: 3, reps: 10, rest_duration: 60 },
        ],
    },
    {
        name: 'Core & Abs',
        plan_type: 'workout',
        description: 'Strengthen your core and abs',
        schedule_days: '7', // Sun
        exercises: [
            { slug_pattern: '%crunch%', sets: 3, reps: 20, rest_duration: 30 },
            { slug_pattern: '%plank%', sets: 3, reps: 45, rest_duration: 30 },
            { slug_pattern: '%sit%up%', sets: 3, reps: 15, rest_duration: 30 },
            { slug_pattern: '%leg%raise%', sets: 3, reps: 12, rest_duration: 30 },
            { slug_pattern: '%twist%', sets: 3, reps: 20, rest_duration: 30 },
        ],
    },
];

// ─── Meal Plan Templates ──────────────────────────────────────────
interface MealPlanTemplate {
    name: string;
    plan_type: string;
    description: string;
    schedule_days: string;
    recipe_patterns: string[]; // partial match on recipe name
}

const MEAL_PLANS: MealPlanTemplate[] = [
    {
        name: 'Healthy Breakfast',
        plan_type: 'meal',
        description: 'Nutritious breakfast options for every day',
        schedule_days: '1,2,3,4,5,6,7',
        recipe_patterns: ['%oat%', '%egg%', '%smoothie%', '%pancake%', '%yogurt%'],
    },
    {
        name: 'High Protein Lunch',
        plan_type: 'meal',
        description: 'Protein-rich lunch meals for muscle building',
        schedule_days: '1,2,3,4,5',
        recipe_patterns: ['%chicken%', '%salad%', '%rice%', '%beef%', '%fish%'],
    },
    {
        name: 'Light Dinner',
        plan_type: 'meal',
        description: 'Light and healthy dinner options',
        schedule_days: '1,2,3,4,5,6,7',
        recipe_patterns: ['%soup%', '%salad%', '%vegetable%', '%steam%', '%grilled%'],
    },
];

// ─── Main Seed Function ──────────────────────────────────────────
async function seedDefaultPlans() {
    console.log('🌱 Starting default plans seed...\n');

    try {
        await connectDB();
        const pool = getPool();

        // 1. Get all user IDs
        const usersResult = await pool.request().query(
            `SELECT user_id FROM Users`
        );
        const userIds = usersResult.recordset.map((r: any) => r.user_id);
        console.log(`👥 Found ${userIds.length} users: [${userIds.join(', ')}]`);

        if (userIds.length === 0) {
            console.log('❌ No users found. Create a user first.');
            return;
        }

        // 2. Get available exercise count
        const exerciseCount = await pool.request().query(
            `SELECT COUNT(*) as cnt FROM Exercises`
        );
        console.log(`💪 Available exercises: ${exerciseCount.recordset[0].cnt}`);

        // 3. Get available recipe count
        const recipeCount = await pool.request().query(
            `SELECT COUNT(*) as cnt FROM Recipes`
        );
        console.log(`🍽️  Available recipes: ${recipeCount.recordset[0].cnt}\n`);

        // 4. Seed plans for each user
        for (const userId of userIds) {
            console.log(`\n📋 Seeding plans for user ${userId}...`);

            // Check if user already has plans
            const existingPlans = await pool.request()
                .input('user_id', sql.Int, userId)
                .query(`SELECT COUNT(*) as cnt FROM Plans WHERE user_id = @user_id`);

            if (existingPlans.recordset[0].cnt > 0) {
                console.log(`   ⏭️  User ${userId} already has ${existingPlans.recordset[0].cnt} plans, skipping.`);
                continue;
            }

            // ── Create Workout Plans ──
            for (const template of WORKOUT_PLANS) {
                const planResult = await pool.request()
                    .input('user_id', sql.Int, userId)
                    .input('name', sql.NVarChar, template.name)
                    .input('plan_type', sql.NVarChar, template.plan_type)
                    .input('description', sql.NVarChar, template.description)
                    .input('schedule_days', sql.NVarChar, template.schedule_days)
                    .query(`
            INSERT INTO Plans (user_id, name, plan_type, description, schedule_days)
            OUTPUT INSERTED.plan_id
            VALUES (@user_id, @name, @plan_type, @description, @schedule_days)
          `);

                const planId = planResult.recordset[0].plan_id;
                console.log(`   ✅ Created plan: "${template.name}" (ID: ${planId})`);

                // Add exercises to plan
                let orderIndex = 1;
                for (const ex of template.exercises) {
                    // Find matching exercise by slug
                    const exResult = await pool.request()
                        .input('slug_pattern', sql.NVarChar, ex.slug_pattern)
                        .query(`SELECT TOP 1 exercise_id FROM Exercises WHERE slug LIKE @slug_pattern`);

                    if (exResult.recordset.length > 0) {
                        const exerciseId = exResult.recordset[0].exercise_id;
                        await pool.request()
                            .input('plan_id', sql.Int, planId)
                            .input('exercise_id', sql.Int, exerciseId)
                            .input('sets', sql.Int, ex.sets)
                            .input('reps', sql.Int, ex.reps)
                            .input('rest_duration', sql.Int, ex.rest_duration)
                            .input('order_index', sql.Int, orderIndex)
                            .query(`
                INSERT INTO Plan_Details (plan_id, exercise_id, sets, reps, rest_duration, order_index)
                VALUES (@plan_id, @exercise_id, @sets, @reps, @rest_duration, @order_index)
              `);
                        orderIndex++;
                    }
                }
                console.log(`      Added ${orderIndex - 1} exercises to plan`);
            }

            // ── Create Meal Plans ──
            for (const template of MEAL_PLANS) {
                const planResult = await pool.request()
                    .input('user_id', sql.Int, userId)
                    .input('name', sql.NVarChar, template.name)
                    .input('plan_type', sql.NVarChar, template.plan_type)
                    .input('description', sql.NVarChar, template.description)
                    .input('schedule_days', sql.NVarChar, template.schedule_days)
                    .query(`
            INSERT INTO Plans (user_id, name, plan_type, description, schedule_days)
            OUTPUT INSERTED.plan_id
            VALUES (@user_id, @name, @plan_type, @description, @schedule_days)
          `);

                const planId = planResult.recordset[0].plan_id;
                console.log(`   ✅ Created meal plan: "${template.name}" (ID: ${planId})`);

                // Add recipes to plan
                let orderIndex = 1;
                for (const pattern of template.recipe_patterns) {
                    const recResult = await pool.request()
                        .input('name_pattern', sql.NVarChar, pattern)
                        .query(`
              SELECT TOP 1 r.recipe_id
              FROM Recipes r
              JOIN Recipe_Translations rt ON r.recipe_id = rt.recipe_id AND rt.language_id = 1
              WHERE rt.name LIKE @name_pattern
            `);

                    if (recResult.recordset.length > 0) {
                        const recipeId = recResult.recordset[0].recipe_id;
                        await pool.request()
                            .input('plan_id', sql.Int, planId)
                            .input('recipe_id', sql.Int, recipeId)
                            .input('order_index', sql.Int, orderIndex)
                            .query(`
                INSERT INTO Plan_Details (plan_id, recipe_id, sets, reps, rest_duration, order_index)
                VALUES (@plan_id, @recipe_id, 1, 1, 0, @order_index)
              `);
                        orderIndex++;
                    }
                }
                console.log(`      Added ${orderIndex - 1} recipes to plan`);
            }
        }

        console.log('\n\n🎉 Default plans seed completed successfully!');
    } catch (error) {
        console.error('❌ Seed error:', error);
    } finally {
        await closeDB();
    }
}

seedDefaultPlans();
