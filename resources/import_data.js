/**
 * HealthCare Database Import Script
 * Imports all CSV/JSON data into SQL Server HeathCare database
 * 
 * Usage: node import_data.js
 * Run from: d:\health_care\resources
 */

const sql = require('mssql/msnodesqlv8');
const fs = require('fs');
const path = require('path');

// ============================================================
// CSV Parser (handles quoted fields with commas and newlines)
// ============================================================
function parseCSV(filePath) {
    const content = fs.readFileSync(filePath, 'utf-8');
    const rows = [];
    let currentRow = [];
    let currentField = '';
    let inQuotes = false;
    let i = 0;

    while (i < content.length) {
        const ch = content[i];

        if (inQuotes) {
            if (ch === '"') {
                if (i + 1 < content.length && content[i + 1] === '"') {
                    currentField += '"';
                    i += 2;
                } else {
                    inQuotes = false;
                    i++;
                }
            } else {
                currentField += ch;
                i++;
            }
        } else {
            if (ch === '"') {
                inQuotes = true;
                i++;
            } else if (ch === ',') {
                currentRow.push(currentField.trim());
                currentField = '';
                i++;
            } else if (ch === '\n' || (ch === '\r' && i + 1 < content.length && content[i + 1] === '\n')) {
                currentRow.push(currentField.trim());
                if (currentRow.some(f => f !== '')) {
                    rows.push(currentRow);
                }
                currentRow = [];
                currentField = '';
                i += (ch === '\r') ? 2 : 1;
            } else if (ch === '\r') {
                currentRow.push(currentField.trim());
                if (currentRow.some(f => f !== '')) {
                    rows.push(currentRow);
                }
                currentRow = [];
                currentField = '';
                i++;
            } else {
                currentField += ch;
                i++;
            }
        }
    }

    // Last field/row
    if (currentField !== '' || currentRow.length > 0) {
        currentRow.push(currentField.trim());
        if (currentRow.some(f => f !== '')) {
            rows.push(currentRow);
        }
    }

    if (rows.length === 0) return [];

    const headers = rows[0];
    return rows.slice(1).map(row => {
        const obj = {};
        headers.forEach((h, idx) => {
            obj[h] = idx < row.length ? row[idx] : '';
        });
        return obj;
    });
}

// ============================================================
// Helper: Parse numeric value from string (handles units like "g", "mg", etc.)
// ============================================================
function parseNum(val) {
    if (val === null || val === undefined || val === '') return null;
    const cleaned = String(val).replace(/[^\d.\-]/g, '');
    const num = parseFloat(cleaned);
    return isNaN(num) ? null : num;
}

// ============================================================
// Database connection  
// ============================================================
const dbConfig = {
    connectionString: 'Driver={ODBC Driver 17 for SQL Server};Server=localhost;Database=HeathCare;Trusted_Connection=yes;',
    driver: 'msnodesqlv8',
};

async function main() {
    console.log('🔗 Connecting to database...');
    const pool = await sql.connect(dbConfig);
    console.log('✅ Connected!\n');

    try {
        // Get language IDs
        const langResult = await pool.request().query(`SELECT language_id, code FROM Languages`);
        const langMap = {};
        langResult.recordset.forEach(r => { langMap[r.code] = r.language_id; });
        console.log('📝 Languages:', langMap);

        // ============================================================
        // 1. IMPORT EXERCISES
        // ============================================================
        console.log('\n' + '='.repeat(60));
        console.log('📋 IMPORTING EXERCISES');
        console.log('='.repeat(60));

        // 1a. Import exercise base data from exercises.json
        const exercisesJson = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'tools', 'exercises.json'), 'utf-8'));
        console.log(`  Found ${exercisesJson.length} exercises in exercises.json`);

        const slugToId = {};
        let exCount = 0;

        for (const ex of exercisesJson) {
            try {
                const result = await pool.request()
                    .input('slug', sql.NVarChar(200), ex.id)
                    .input('force', sql.NVarChar(20), ex.force || null)
                    .input('level', sql.NVarChar(20), ex.level)
                    .input('mechanic', sql.NVarChar(20), ex.mechanic || null)
                    .input('equipment', sql.NVarChar(50), ex.equipment || null)
                    .input('category', sql.NVarChar(50), ex.category)
                    .query(`INSERT INTO Exercises (slug, [force], level, mechanic, equipment, category)
                  OUTPUT INSERTED.exercise_id
                  VALUES (@slug, @force, @level, @mechanic, @equipment, @category)`);
                slugToId[ex.id] = result.recordset[0].exercise_id;
                exCount++;
            } catch (e) {
                if (!e.message.includes('duplicate') && !e.message.includes('UNIQUE')) {
                    console.error(`  ❌ Exercise ${ex.id}: ${e.message.substring(0, 100)}`);
                }
            }
        }
        console.log(`  ✅ Inserted ${exCount} exercises`);

        // 1b. Import Exercise Translations from CSV
        const transData = parseCSV(path.join(__dirname, 'Exercise_Translations.csv'));
        console.log(`  Found ${transData.length} exercise translation rows`);
        let transCount = 0;

        for (const row of transData) {
            const exId = slugToId[row.exercise_slug];
            const langId = langMap[row.language_code];
            if (!exId || !langId) continue;
            try {
                await pool.request()
                    .input('eid', sql.Int, exId)
                    .input('lid', sql.Int, langId)
                    .input('name', sql.NVarChar(255), row.name)
                    .query(`INSERT INTO Exercise_Translations (exercise_id, language_id, name) VALUES (@eid, @lid, @name)`);
                transCount++;
            } catch (e) {
                // skip duplicates
            }
        }
        console.log(`  ✅ Inserted ${transCount} exercise translations`);

        // 1c. Import Exercise Images from CSV
        const imgData = parseCSV(path.join(__dirname, 'ExerciseImages.csv'));
        console.log(`  Found ${imgData.length} exercise image rows`);
        let imgCount = 0;

        for (const row of imgData) {
            const exId = slugToId[row.exercise_slug];
            if (!exId) continue;
            try {
                await pool.request()
                    .input('eid', sql.Int, exId)
                    .input('url', sql.NVarChar(500), row.image_url)
                    .input('order', sql.Int, imgCount % 2)
                    .query(`INSERT INTO ExerciseImages (exercise_id, image_url, display_order) VALUES (@eid, @url, @order)`);
                imgCount++;
            } catch (e) { }
        }
        console.log(`  ✅ Inserted ${imgCount} exercise images`);

        // 1d. Import Exercise Instructions from CSV
        const instrData = parseCSV(path.join(__dirname, 'ExerciseInstructions.csv'));
        console.log(`  Found ${instrData.length} exercise instruction rows`);
        let instrCount = 0;

        for (const row of instrData) {
            const exId = slugToId[row.exercise_slug];
            const langId = langMap[row.language_code];
            if (!exId || !langId) continue;
            try {
                await pool.request()
                    .input('eid', sql.Int, exId)
                    .input('lid', sql.Int, langId)
                    .input('step', sql.Int, parseInt(row.step_order))
                    .input('instr', sql.NVarChar(sql.MAX), row.instruction)
                    .query(`INSERT INTO ExerciseInstructions (exercise_id, language_id, step_order, instruction) VALUES (@eid, @lid, @step, @instr)`);
                instrCount++;
            } catch (e) { }
        }
        console.log(`  ✅ Inserted ${instrCount} exercise instructions`);

        // 1e. Import Exercise Primary Muscles from CSV
        const primData = parseCSV(path.join(__dirname, 'ExercisePrimaryMuscles.csv'));
        let primCount = 0;
        for (const row of primData) {
            const exId = slugToId[row.exercise_slug];
            if (!exId) continue;
            try {
                await pool.request()
                    .input('eid', sql.Int, exId)
                    .input('muscle', sql.NVarChar(50), row.muscle)
                    .query(`INSERT INTO ExercisePrimaryMuscles (exercise_id, muscle) VALUES (@eid, @muscle)`);
                primCount++;
            } catch (e) { }
        }
        console.log(`  ✅ Inserted ${primCount} primary muscles`);

        // 1f. Import Exercise Secondary Muscles from CSV
        const secData = parseCSV(path.join(__dirname, 'ExerciseSecondaryMuscles.csv'));
        let secCount = 0;
        for (const row of secData) {
            const exId = slugToId[row.exercise_slug];
            if (!exId) continue;
            try {
                await pool.request()
                    .input('eid', sql.Int, exId)
                    .input('muscle', sql.NVarChar(50), row.muscle)
                    .query(`INSERT INTO ExerciseSecondaryMuscles (exercise_id, muscle) VALUES (@eid, @muscle)`);
                secCount++;
            } catch (e) { }
        }
        console.log(`  ✅ Inserted ${secCount} secondary muscles`);

        // ============================================================
        // 2. IMPORT FOODS
        // ============================================================
        console.log('\n' + '='.repeat(60));
        console.log('🍎 IMPORTING FOODS');
        console.log('='.repeat(60));

        // 2a. Import Daily Foods from daily_food_nutrition_dataset_VN.csv
        const dailyFoodData = parseCSV(path.join(__dirname, 'daily_food_nutrition_dataset_VN.csv'));
        console.log(`  Found ${dailyFoodData.length} daily food rows`);
        let dailyCount = 0;

        for (const row of dailyFoodData) {
            const code = (row['Food_Item'] || '').replace(/[^a-zA-Z0-9\s\-_()]/g, '').replace(/\s+/g, '_').substring(0, 195);
            if (!code) continue;

            try {
                const result = await pool.request()
                    .input('code', sql.NVarChar(200), 'daily_' + code)
                    .input('source', sql.NVarChar(50), 'daily_food')
                    .input('calories', sql.Float, parseNum(row['Calories (kcal)']))
                    .input('protein', sql.Float, parseNum(row['Protein (g)']))
                    .input('carbs', sql.Float, parseNum(row['Carbohydrates (g)']))
                    .input('fat', sql.Float, parseNum(row['Fat (g)']))
                    .input('fiber', sql.Float, parseNum(row['Fiber (g)']))
                    .input('sugars', sql.Float, parseNum(row['Sugars (g)']))
                    .input('sodium', sql.Float, parseNum(row['Sodium (mg)']))
                    .input('cholesterol', sql.Float, parseNum(row['Cholesterol (mg)']))
                    .input('meal_type', sql.NVarChar(50), row['Meal_Type'] || null)
                    .input('water_intake', sql.Int, parseNum(row['Water_Intake (ml)']))
                    .input('cat_code', sql.NVarChar(100), row['Category'] || null)
                    .query(`INSERT INTO Foods (code, source, calories, protein, carbs, fat, fiber, sugars, sodium, cholesterol, meal_type, water_intake_ml, category_code)
                  OUTPUT INSERTED.food_id
                  VALUES (@code, @source, @calories, @protein, @carbs, @fat, @fiber, @sugars, @sodium, @cholesterol, @meal_type, @water_intake, @cat_code)`);

                const foodId = result.recordset[0].food_id;

                // EN translation
                if (row['Food_Item']) {
                    await pool.request()
                        .input('fid', sql.Int, foodId)
                        .input('lid', sql.Int, langMap['en'])
                        .input('name', sql.NVarChar(255), row['Food_Item'])
                        .input('cat', sql.NVarChar(100), row['Category'] || null)
                        .query(`INSERT INTO Food_Translations (food_id, language_id, name, category_name) VALUES (@fid, @lid, @name, @cat)`);
                }

                // VI translation
                if (row['Food_Item_VN']) {
                    await pool.request()
                        .input('fid', sql.Int, foodId)
                        .input('lid', sql.Int, langMap['vi'])
                        .input('name', sql.NVarChar(255), row['Food_Item_VN'])
                        .input('cat', sql.NVarChar(100), row['Category_VN'] || null)
                        .query(`INSERT INTO Food_Translations (food_id, language_id, name, category_name) VALUES (@fid, @lid, @name, @cat)`);
                }

                dailyCount++;
            } catch (e) {
                if (!e.message.includes('duplicate') && !e.message.includes('UNIQUE')) {
                    console.error(`  ❌ Daily food: ${e.message.substring(0, 120)}`);
                }
            }
        }
        console.log(`  ✅ Inserted ${dailyCount} daily foods`);

        // 2b. Import nutrition_VN.csv (detailed nutrition data)
        const nutritionData = parseCSV(path.join(__dirname, 'nutrition_VN.csv'));
        console.log(`  Found ${nutritionData.length} nutrition rows`);
        let nutCount = 0;

        for (const row of nutritionData) {
            const nameEN = row['name'] || '';
            const nameVN = row['name_VN'] || '';
            if (!nameEN) continue;

            const code = 'nut_' + nameEN.replace(/[^a-zA-Z0-9\s\-_]/g, '').replace(/\s+/g, '_').substring(0, 190);

            try {
                const result = await pool.request()
                    .input('code', sql.NVarChar(200), code)
                    .input('source', sql.NVarChar(50), 'nutrition_vn')
                    .input('calories', sql.Float, parseNum(row['calories']))
                    .input('protein', sql.Float, parseNum(row['protein']))
                    .input('fat', sql.Float, parseNum(row['total_fat']))
                    .input('saturated_fat', sql.Float, parseNum(row['saturated_fat']))
                    .input('carbs', sql.Float, parseNum(row['carbohydrate']))
                    .input('fiber', sql.Float, parseNum(row['fiber']))
                    .input('sugars', sql.Float, parseNum(row['sugars']))
                    .input('cholesterol', sql.Float, parseNum(row['cholesterol']))
                    .input('calcium', sql.Float, parseNum(row['calcium']))
                    .input('phosphorus', sql.Float, parseNum(row['phosphorous']))
                    .input('iron', sql.Float, parseNum(row['irom']))  // note: typo in CSV header
                    .input('sodium', sql.Float, parseNum(row['sodium']))
                    .input('potassium', sql.Float, parseNum(row['potassium']))
                    .input('magnesium', sql.Float, parseNum(row['magnesium']))
                    .input('zinc', sql.Float, parseNum(row['zink']))  // note: typo in CSV header
                    .input('copper', sql.Float, parseNum(row['copper']))
                    .input('manganese', sql.Float, parseNum(row['manganese']))
                    .input('selenium', sql.Float, parseNum(row['selenium']))
                    .input('beta_carotene', sql.Float, parseNum(row['carotene_beta']))
                    .input('vitamin_a', sql.Float, parseNum(row['vitamin_a']))
                    .input('vitamin_a_rae', sql.Float, parseNum(row['vitamin_a_rae']))
                    .input('vitamin_b1', sql.Float, parseNum(row['thiamin']))
                    .input('vitamin_b6', sql.Float, parseNum(row['vitamin_b6']))
                    .input('vitamin_b12', sql.Float, parseNum(row['vitamin_b12']))
                    .input('vitamin_c', sql.Float, parseNum(row['vitamin_c']))
                    .input('vitamin_d', sql.Float, parseNum(row['vitamin_d']))
                    .input('vitamin_e', sql.Float, parseNum(row['vitamin_e']))
                    .input('vitamin_k', sql.Float, parseNum(row['vitamin_k']))
                    .input('folate', sql.Float, parseNum(row['folate']))
                    .input('niacin', sql.Float, parseNum(row['niacin']))
                    .input('riboflavin', sql.Float, parseNum(row['riboflavin']))
                    .input('pantothenic_acid', sql.Float, parseNum(row['pantothenic_acid']))
                    .input('choline', sql.Float, parseNum(row['choline']))
                    .input('water', sql.Float, parseNum(row['water']))
                    .input('alcohol', sql.Float, parseNum(row['alcohol']))
                    .input('caffeine', sql.Float, parseNum(row['caffeine']))
                    .input('ash', sql.Float, parseNum(row['ash']))
                    .query(`INSERT INTO Foods (code, source, calories, protein, fat, saturated_fat, carbs, fiber, sugars,
                    cholesterol, calcium, phosphorus, iron, sodium, potassium, magnesium, zinc, copper,
                    manganese, selenium, beta_carotene, vitamin_a, vitamin_a_rae, vitamin_b1, vitamin_b6,
                    vitamin_b12, vitamin_c, vitamin_d, vitamin_e, vitamin_k, folate, niacin, riboflavin,
                    pantothenic_acid, choline, water, alcohol, caffeine, ash)
                  OUTPUT INSERTED.food_id
                  VALUES (@code, @source, @calories, @protein, @fat, @saturated_fat, @carbs, @fiber, @sugars,
                    @cholesterol, @calcium, @phosphorus, @iron, @sodium, @potassium, @magnesium, @zinc, @copper,
                    @manganese, @selenium, @beta_carotene, @vitamin_a, @vitamin_a_rae, @vitamin_b1, @vitamin_b6,
                    @vitamin_b12, @vitamin_c, @vitamin_d, @vitamin_e, @vitamin_k, @folate, @niacin, @riboflavin,
                    @pantothenic_acid, @choline, @water, @alcohol, @caffeine, @ash)`);

                const foodId = result.recordset[0].food_id;

                // EN translation
                await pool.request()
                    .input('fid', sql.Int, foodId).input('lid', sql.Int, langMap['en'])
                    .input('name', sql.NVarChar(255), nameEN.substring(0, 255))
                    .query(`INSERT INTO Food_Translations (food_id, language_id, name) VALUES (@fid, @lid, @name)`);

                // VI translation
                if (nameVN) {
                    await pool.request()
                        .input('fid', sql.Int, foodId).input('lid', sql.Int, langMap['vi'])
                        .input('name', sql.NVarChar(255), nameVN.substring(0, 255))
                        .query(`INSERT INTO Food_Translations (food_id, language_id, name) VALUES (@fid, @lid, @name)`);
                }

                // Food_Amino_Acids
                const hasAmino = ['alanine', 'arginine', 'aspartic_acid', 'cystine', 'glutamic_acid', 'glycine',
                    'histidine', 'hydroxyproline', 'isoleucine', 'leucine', 'lysine', 'methionine',
                    'phenylalanine', 'proline', 'serine', 'threonine', 'tryptophan', 'tyrosine', 'valine']
                    .some(k => parseNum(row[k]) !== null);

                if (hasAmino) {
                    const req = pool.request().input('fid', sql.Int, foodId);
                    const aminoFields = ['alanine', 'arginine', 'aspartic_acid', 'cystine', 'glutamic_acid', 'glycine',
                        'histidine', 'hydroxyproline', 'isoleucine', 'leucine', 'lysine', 'methionine',
                        'phenylalanine', 'proline', 'serine', 'threonine', 'tryptophan', 'tyrosine', 'valine'];
                    aminoFields.forEach(f => req.input(f, sql.Float, parseNum(row[f])));
                    await req.query(`INSERT INTO Food_Amino_Acids (food_id, ${aminoFields.join(',')})
                           VALUES (@fid, ${aminoFields.map(f => '@' + f).join(',')})`);
                }

                // Food_Fatty_Acids
                const hasFatty = ['saturated_fatty_acids', 'monounsaturated_fatty_acids', 'polyunsaturated_fatty_acids', 'fatty_acids_total_trans']
                    .some(k => parseNum(row[k]) !== null);

                if (hasFatty) {
                    await pool.request()
                        .input('fid', sql.Int, foodId)
                        .input('sat', sql.Float, parseNum(row['saturated_fatty_acids']))
                        .input('mono', sql.Float, parseNum(row['monounsaturated_fatty_acids']))
                        .input('poly', sql.Float, parseNum(row['polyunsaturated_fatty_acids']))
                        .input('trans', sql.Float, parseNum(row['fatty_acids_total_trans']))
                        .query(`INSERT INTO Food_Fatty_Acids (food_id, saturated_fatty_acids, monounsaturated_fatty_acids, polyunsaturated_fatty_acids, fatty_acids_total_trans)
                    VALUES (@fid, @sat, @mono, @poly, @trans)`);
                }

                // Food_Sugars
                const hasSugars = ['fructose', 'galactose', 'glucose', 'lactose', 'maltose', 'sucrose']
                    .some(k => parseNum(row[k]) !== null);

                if (hasSugars) {
                    await pool.request()
                        .input('fid', sql.Int, foodId)
                        .input('fructose', sql.Float, parseNum(row['fructose']))
                        .input('galactose', sql.Float, parseNum(row['galactose']))
                        .input('glucose', sql.Float, parseNum(row['glucose']))
                        .input('lactose', sql.Float, parseNum(row['lactose']))
                        .input('maltose', sql.Float, parseNum(row['maltose']))
                        .input('sucrose', sql.Float, parseNum(row['sucrose']))
                        .query(`INSERT INTO Food_Sugars (food_id, fructose, galactose, glucose, lactose, maltose, sucrose)
                    VALUES (@fid, @fructose, @galactose, @glucose, @lactose, @maltose, @sucrose)`);
                }

                // Food_Carotenoids
                const hasCarotenoids = ['carotene_alpha', 'carotene_beta', 'cryptoxanthin_beta', 'lutein_zeaxanthin', 'lucopene']
                    .some(k => parseNum(row[k]) !== null);

                if (hasCarotenoids) {
                    await pool.request()
                        .input('fid', sql.Int, foodId)
                        .input('ca', sql.Float, parseNum(row['carotene_alpha']))
                        .input('cb', sql.Float, parseNum(row['carotene_beta']))
                        .input('cxb', sql.Float, parseNum(row['cryptoxanthin_beta']))
                        .input('lz', sql.Float, parseNum(row['lutein_zeaxanthin']))
                        .input('lyc', sql.Float, parseNum(row['lucopene']))
                        .query(`INSERT INTO Food_Carotenoids (food_id, carotene_alpha, carotene_beta, cryptoxanthin_beta, lutein_zeaxanthin, lycopene)
                    VALUES (@fid, @ca, @cb, @cxb, @lz, @lyc)`);
                }

                nutCount++;
                if (nutCount % 1000 === 0) console.log(`    ... ${nutCount} nutrition items imported`);
            } catch (e) {
                if (!e.message.includes('duplicate') && !e.message.includes('UNIQUE')) {
                    // Only log first few errors
                    if (nutCount < 10) console.error(`  ❌ Nutrition: ${e.message.substring(0, 120)}`);
                }
            }
        }
        console.log(`  ✅ Inserted ${nutCount} nutrition items (with amino acids, fatty acids, sugars, carotenoids)`);

        // ============================================================
        // 3. IMPORT RECIPES
        // ============================================================
        console.log('\n' + '='.repeat(60));
        console.log('🍳 IMPORTING RECIPES');
        console.log('='.repeat(60));

        // 3a. Import recipe names (base data)
        const recipeNameData = parseCSV(path.join(__dirname, 'translate_recipe_names.csv'));
        console.log(`  Found ${recipeNameData.length} recipe name rows`);
        const recipeCodeToId = {};
        let recipeCount = 0;

        for (const row of recipeNameData) {
            const code = row['recipe_code'];
            if (!code || recipeCodeToId[code]) continue;

            try {
                const result = await pool.request()
                    .input('code', sql.NVarChar(200), code)
                    .input('category', sql.NVarChar(100), row['category'] || null)
                    .input('area', sql.NVarChar(100), row['area'] || null)
                    .query(`INSERT INTO Recipes (recipe_code, category, area)
                  OUTPUT INSERTED.recipe_id
                  VALUES (@code, @category, @area)`);

                const recipeId = result.recordset[0].recipe_id;
                recipeCodeToId[code] = recipeId;

                // EN translation
                if (row['name_en']) {
                    await pool.request()
                        .input('rid', sql.Int, recipeId).input('lid', sql.Int, langMap['en'])
                        .input('name', sql.NVarChar(255), row['name_en'])
                        .query(`INSERT INTO Recipe_Translations (recipe_id, language_id, name) VALUES (@rid, @lid, @name)`);
                }

                // VI translation
                if (row['name_vi']) {
                    await pool.request()
                        .input('rid', sql.Int, recipeId).input('lid', sql.Int, langMap['vi'])
                        .input('name', sql.NVarChar(255), row['name_vi'])
                        .query(`INSERT INTO Recipe_Translations (recipe_id, language_id, name) VALUES (@rid, @lid, @name)`);
                }

                recipeCount++;
            } catch (e) {
                if (!e.message.includes('duplicate') && !e.message.includes('UNIQUE')) {
                    console.error(`  ❌ Recipe ${code}: ${e.message.substring(0, 120)}`);
                }
            }
        }
        console.log(`  ✅ Inserted ${recipeCount} recipes with translations`);

        // 3b. Import recipe instructions overview
        const recipeInstrData = parseCSV(path.join(__dirname, 'translate_recipe_instructions.csv'));
        console.log(`  Found ${recipeInstrData.length} recipe instruction overview rows`);
        let recipeInstrCount = 0;

        for (const row of recipeInstrData) {
            const recipeId = recipeCodeToId[row['recipe_code']];
            if (!recipeId) continue;

            try {
                // Update EN translation with overview
                if (row['instructions_en']) {
                    await pool.request()
                        .input('rid', sql.Int, recipeId).input('lid', sql.Int, langMap['en'])
                        .input('overview', sql.NVarChar(sql.MAX), row['instructions_en'])
                        .query(`UPDATE Recipe_Translations SET overview = @overview WHERE recipe_id = @rid AND language_id = @lid`);
                }

                // Update VI translation with overview
                if (row['instructions_vn']) {
                    await pool.request()
                        .input('rid', sql.Int, recipeId).input('lid', sql.Int, langMap['vi'])
                        .input('overview', sql.NVarChar(sql.MAX), row['instructions_vn'])
                        .query(`UPDATE Recipe_Translations SET overview = @overview WHERE recipe_id = @rid AND language_id = @lid`);
                }
                recipeInstrCount++;
            } catch (e) { }
        }
        console.log(`  ✅ Updated ${recipeInstrCount} recipe overviews`);

        // 3c. Import recipe steps (detailed instructions)
        const recipeStepsData = parseCSV(path.join(__dirname, 'translate_recipe_steps.csv'));
        console.log(`  Found ${recipeStepsData.length} recipe step rows`);
        let stepCount = 0;

        for (const row of recipeStepsData) {
            const recipeId = recipeCodeToId[row['recipe_code']];
            if (!recipeId) continue;

            const stepOrder = parseInt(row['step_order']);
            if (isNaN(stepOrder)) continue;

            try {
                // EN instruction
                if (row['instruction_en']) {
                    await pool.request()
                        .input('rid', sql.Int, recipeId).input('lid', sql.Int, langMap['en'])
                        .input('step', sql.Int, stepOrder)
                        .input('instr', sql.NVarChar(sql.MAX), row['instruction_en'])
                        .query(`INSERT INTO Recipe_Instructions (recipe_id, language_id, step_order, instruction)
                    VALUES (@rid, @lid, @step, @instr)`);
                }

                // VI instruction
                if (row['instruction_vi']) {
                    await pool.request()
                        .input('rid', sql.Int, recipeId).input('lid', sql.Int, langMap['vi'])
                        .input('step', sql.Int, stepOrder)
                        .input('instr', sql.NVarChar(sql.MAX), row['instruction_vi'])
                        .query(`INSERT INTO Recipe_Instructions (recipe_id, language_id, step_order, instruction)
                    VALUES (@rid, @lid, @step, @instr)`);
                }
                stepCount++;
            } catch (e) { }
        }
        console.log(`  ✅ Inserted ${stepCount} recipe steps`);

        // 3d. Import recipe ingredients
        const ingredientTransData = parseCSV(path.join(__dirname, 'translate_recipe_ingredients.csv'));
        const ingredientMap = {};
        for (const row of ingredientTransData) {
            if (row['ingredient_en'] && row['ingredient_vi']) {
                ingredientMap[row['ingredient_en'].toLowerCase()] = row['ingredient_vi'];
            }
        }
        console.log(`  Found ${Object.keys(ingredientMap).length} ingredient translations`);

        // ============================================================
        // SUMMARY
        // ============================================================
        console.log('\n' + '='.repeat(60));
        console.log('📊 IMPORT SUMMARY');
        console.log('='.repeat(60));

        const counts = await pool.request().query(`
      SELECT 'Exercises' as tbl, COUNT(*) as cnt FROM Exercises UNION ALL
      SELECT 'Exercise_Translations', COUNT(*) FROM Exercise_Translations UNION ALL
      SELECT 'ExerciseImages', COUNT(*) FROM ExerciseImages UNION ALL
      SELECT 'ExerciseInstructions', COUNT(*) FROM ExerciseInstructions UNION ALL
      SELECT 'ExercisePrimaryMuscles', COUNT(*) FROM ExercisePrimaryMuscles UNION ALL
      SELECT 'ExerciseSecondaryMuscles', COUNT(*) FROM ExerciseSecondaryMuscles UNION ALL
      SELECT 'Foods', COUNT(*) FROM Foods UNION ALL
      SELECT 'Food_Translations', COUNT(*) FROM Food_Translations UNION ALL
      SELECT 'Food_Amino_Acids', COUNT(*) FROM Food_Amino_Acids UNION ALL
      SELECT 'Food_Fatty_Acids', COUNT(*) FROM Food_Fatty_Acids UNION ALL
      SELECT 'Food_Sugars', COUNT(*) FROM Food_Sugars UNION ALL
      SELECT 'Food_Carotenoids', COUNT(*) FROM Food_Carotenoids UNION ALL
      SELECT 'Recipes', COUNT(*) FROM Recipes UNION ALL
      SELECT 'Recipe_Translations', COUNT(*) FROM Recipe_Translations UNION ALL
      SELECT 'Recipe_Instructions', COUNT(*) FROM Recipe_Instructions
      ORDER BY tbl
    `);

        counts.recordset.forEach(r => {
            console.log(`  ${r.tbl}: ${r.cnt} rows`);
        });

        console.log('\n✅ Import completed successfully!');

    } catch (err) {
        console.error('❌ Fatal error:', err.message);
    } finally {
        await pool.close();
    }
}

main().catch(console.error);
