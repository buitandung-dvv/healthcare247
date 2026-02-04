-- =====================================================
-- HEALTHCARE DATABASE - OPTIMIZED SCHEMA
-- Version 2.0 - Tối ưu hóa cấu trúc
-- =====================================================

USE master;
GO

-- Ngắt tất cả kết nối
DECLARE @SQL NVARCHAR(MAX) = '';
SELECT @SQL = @SQL + 'KILL ' + CAST(session_id AS VARCHAR(10)) + ';'
FROM sys.dm_exec_sessions
WHERE database_id = DB_ID('HeathCare');
EXEC sp_executesql @SQL;
GO

-- Xóa database nếu tồn tại
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'HeathCare')
BEGIN
    DROP DATABASE HeathCare;
END
GO

-- Tạo database mới
CREATE DATABASE HeathCare COLLATE Vietnamese_CI_AS;
GO

USE HeathCare;
GO

-- =====================================================
-- BẢNG LANGUAGES
-- =====================================================
CREATE TABLE Languages (
    language_id INT PRIMARY KEY IDENTITY(1,1),
    code NVARCHAR(10) UNIQUE NOT NULL,
    name NVARCHAR(100) NOT NULL,
    is_default BIT DEFAULT 0,
    created_at DATETIME DEFAULT GETDATE()
);

INSERT INTO Languages (code, name, is_default) VALUES 
('en', 'English', 1),
('vi', N'Tiếng Việt', 0);
GO

-- =====================================================
-- BẢNG USERS
-- =====================================================
CREATE TABLE Users (
    user_id INT PRIMARY KEY IDENTITY(1,1),
    username NVARCHAR(100) UNIQUE NOT NULL,
    password NVARCHAR(255) NOT NULL,
    full_name NVARCHAR(100) NULL,
    email NVARCHAR(150) UNIQUE NOT NULL,
    gender NVARCHAR(50),
    date_of_birth DATE,
    height DECIMAL(5,2),
    weight DECIMAL(5,2),
    goal NVARCHAR(255),
    body_goals NVARCHAR(500),
    activity_level NVARCHAR(50),
    preferred_language_id INT DEFAULT 1,
    onboarding_completed BIT NOT NULL DEFAULT 0,
    created_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (preferred_language_id) REFERENCES Languages(language_id)
);
GO

-- =====================================================
-- BẢNG USER_GOALS
-- =====================================================
CREATE TABLE User_Goals (
    goal_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT NOT NULL UNIQUE,
    calories_goal DECIMAL(10,2) NOT NULL DEFAULT 2000,
    protein_goal DECIMAL(10,2) NOT NULL DEFAULT 150,
    carbs_goal DECIMAL(10,2) NOT NULL DEFAULT 250,
    fat_goal DECIMAL(10,2) NOT NULL DEFAULT 65,
    water_goal_ml INT NOT NULL DEFAULT 2000,
    workouts_per_week INT NOT NULL DEFAULT 3,
    created_at DATETIME NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME NOT NULL DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

CREATE INDEX IX_UserGoals_UserId ON User_Goals(user_id);
GO

-- Trigger: Tự động tạo goals mặc định khi user mới đăng ký
CREATE TRIGGER TR_Users_CreateDefaultGoals
ON Users
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO User_Goals (user_id, calories_goal, protein_goal, carbs_goal, fat_goal, workouts_per_week)
    SELECT i.user_id,
           CASE 
               WHEN i.goal = 'lose_weight' THEN 1500
               WHEN i.goal = 'build_muscle' THEN 2500
               ELSE 2000
           END,
           CASE 
               WHEN i.goal = 'build_muscle' THEN 180
               ELSE 150
           END,
           250,
           65,
           CASE 
               WHEN i.goal = 'build_muscle' THEN 5
               ELSE 3
           END
    FROM INSERTED i;
END;
GO

-- =====================================================
-- BẢNG EXERCISES (Giữ nguyên, đã tối ưu)
-- =====================================================
CREATE TABLE Exercises (
    exercise_id INT PRIMARY KEY IDENTITY(1,1),
    slug NVARCHAR(200) UNIQUE NOT NULL,
    force NVARCHAR(20) NULL CHECK (force IN ('static','pull','push')),
    level NVARCHAR(20) NOT NULL CHECK (level IN ('beginner','intermediate','expert')),
    mechanic NVARCHAR(20) NULL CHECK (mechanic IN ('isolation','compound')),
    equipment NVARCHAR(50) NULL CHECK (equipment IN (
        'medicine ball','dumbbell','body only','bands','kettlebells',
        'foam roll','cable','machine','barbell','exercise ball','e-z curl bar','other'
    )),
    category NVARCHAR(50) NOT NULL CHECK (category IN (
        'powerlifting','strength','stretching','cardio',
        'olympic weightlifting','strongman','plyometrics'
    )),
    created_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE Exercise_Translations (
    exercise_id INT NOT NULL,
    language_id INT NOT NULL,
    name NVARCHAR(255) NOT NULL,
    PRIMARY KEY (exercise_id, language_id),
    FOREIGN KEY (exercise_id) REFERENCES Exercises(exercise_id) ON DELETE CASCADE,
    FOREIGN KEY (language_id) REFERENCES Languages(language_id)
);

CREATE TABLE ExercisePrimaryMuscles (
    exercise_id INT NOT NULL,
    muscle NVARCHAR(50) NOT NULL CHECK (muscle IN (
        'abdominals','abductors','adductors','biceps','calves','chest',
        'forearms','glutes','hamstrings','lats','lower back','middle back',
        'neck','quadriceps','shoulders','traps','triceps'
    )),
    PRIMARY KEY (exercise_id, muscle),
    FOREIGN KEY (exercise_id) REFERENCES Exercises(exercise_id) ON DELETE CASCADE
);

CREATE TABLE ExerciseSecondaryMuscles (
    exercise_id INT NOT NULL,
    muscle NVARCHAR(50) NOT NULL CHECK (muscle IN (
        'abdominals','abductors','adductors','biceps','calves','chest',
        'forearms','glutes','hamstrings','lats','lower back','middle back',
        'neck','quadriceps','shoulders','traps','triceps'
    )),
    PRIMARY KEY (exercise_id, muscle),
    FOREIGN KEY (exercise_id) REFERENCES Exercises(exercise_id) ON DELETE CASCADE
);

CREATE TABLE ExerciseInstructions (
    exercise_id INT NOT NULL,
    language_id INT NOT NULL,
    step_order INT NOT NULL,
    instruction NVARCHAR(MAX) NOT NULL,
    PRIMARY KEY (exercise_id, language_id, step_order),
    FOREIGN KEY (exercise_id) REFERENCES Exercises(exercise_id) ON DELETE CASCADE,
    FOREIGN KEY (language_id) REFERENCES Languages(language_id)
);

CREATE TABLE ExerciseImages (
    exercise_id INT NOT NULL,
    image_url NVARCHAR(500) NOT NULL,
    display_order INT DEFAULT 0,
    PRIMARY KEY (exercise_id, image_url),
    FOREIGN KEY (exercise_id) REFERENCES Exercises(exercise_id) ON DELETE CASCADE
);

-- =====================================================
-- BẢNG MUSCLES (Dùng để dịch tên cơ bắp theo ngôn ngữ)
-- =====================================================
CREATE TABLE Muscles (
    muscle_id INT PRIMARY KEY IDENTITY(1,1),
    code NVARCHAR(50) UNIQUE NOT NULL  -- abdominals, biceps, etc.
);

CREATE TABLE Muscle_Translations (
    muscle_id INT NOT NULL,
    language_id INT NOT NULL,
    name NVARCHAR(100) NOT NULL,
    description NVARCHAR(MAX),
    PRIMARY KEY (muscle_id, language_id),
    FOREIGN KEY (muscle_id) REFERENCES Muscles(muscle_id) ON DELETE CASCADE,
    FOREIGN KEY (language_id) REFERENCES Languages(language_id)
);

-- Insert muscle data
INSERT INTO Muscles (code) VALUES
('abdominals'), ('abductors'), ('adductors'), ('biceps'), ('calves'),
('chest'), ('forearms'), ('glutes'), ('hamstrings'), ('lats'),
('lower back'), ('middle back'), ('neck'), ('quadriceps'), ('shoulders'),
('traps'), ('triceps');

-- English translations
INSERT INTO Muscle_Translations (muscle_id, language_id, name, description) VALUES
(1, 1, N'Abdominals', N'Abdominal muscles'),
(2, 1, N'Abductors', N'Hip abductor muscles'),
(3, 1, N'Adductors', N'Hip adductor muscles'),
(4, 1, N'Biceps', N'Biceps brachii'),
(5, 1, N'Calves', N'Calf muscles'),
(6, 1, N'Chest', N'Pectoral muscles'),
(7, 1, N'Forearms', N'Forearm muscles'),
(8, 1, N'Glutes', N'Gluteal muscles'),
(9, 1, N'Hamstrings', N'Hamstring muscles'),
(10, 1, N'Lats', N'Latissimus dorsi'),
(11, 1, N'Lower Back', N'Lower back muscles'),
(12, 1, N'Middle Back', N'Middle back muscles'),
(13, 1, N'Neck', N'Neck muscles'),
(14, 1, N'Quadriceps', N'Quadriceps femoris'),
(15, 1, N'Shoulders', N'Deltoid muscles'),
(16, 1, N'Traps', N'Trapezius muscles'),
(17, 1, N'Triceps', N'Triceps brachii');

-- Vietnamese translations
INSERT INTO Muscle_Translations (muscle_id, language_id, name, description) VALUES
(1, 2, N'Cơ bụng', N'Nhóm cơ vùng bụng'),
(2, 2, N'Cơ dạng chân', N'Nhóm cơ đưa chân ra ngoài'),
(3, 2, N'Cơ khép chân', N'Nhóm cơ khép chân vào trong'),
(4, 2, N'Cơ nhị đầu', N'Cơ nhị đầu cánh tay'),
(5, 2, N'Cơ bắp chân', N'Nhóm cơ bắp chân'),
(6, 2, N'Cơ ngực', N'Nhóm cơ vùng ngực'),
(7, 2, N'Cơ cẳng tay', N'Nhóm cơ cẳng tay'),
(8, 2, N'Cơ mông', N'Nhóm cơ vùng mông'),
(9, 2, N'Cơ gân kheo', N'Nhóm cơ sau đùi'),
(10, 2, N'Cơ lưng xô', N'Cơ lưng rộng'),
(11, 2, N'Cơ lưng dưới', N'Nhóm cơ vùng lưng dưới'),
(12, 2, N'Cơ lưng giữa', N'Nhóm cơ vùng lưng giữa'),
(13, 2, N'Cơ cổ', N'Nhóm cơ vùng cổ'),
(14, 2, N'Cơ tứ đầu', N'Cơ tứ đầu đùi'),
(15, 2, N'Cơ vai', N'Nhóm cơ vai (cơ delta)'),
(16, 2, N'Cơ thang', N'Cơ thang vai gáy'),
(17, 2, N'Cơ tam đầu', N'Cơ tam đầu cánh tay');
GO

-- Function: Dịch muscle code sang tên theo ngôn ngữ
CREATE FUNCTION dbo.fn_GetMuscleName
(
    @muscle_code NVARCHAR(50),
    @language_id INT
)
RETURNS NVARCHAR(100)
AS
BEGIN
    DECLARE @muscle_name NVARCHAR(100);
    
    SELECT @muscle_name = mt.name
    FROM Muscles m
    INNER JOIN Muscle_Translations mt ON m.muscle_id = mt.muscle_id
    WHERE m.code = @muscle_code AND mt.language_id = @language_id;
    
    RETURN @muscle_name;
END
GO

-- =====================================================
-- BẢNG FOODS (Đã merge Daily_Foods)
-- Thêm: source, meal_type, water_intake_ml
-- =====================================================
CREATE TABLE Foods (
    food_id INT PRIMARY KEY IDENTITY(1,1),
    code NVARCHAR(200) UNIQUE NOT NULL,
    source NVARCHAR(50) DEFAULT 'nutrition_vn' CHECK (source IN ('nutrition_vn', 'daily_food', 'user')),
    -- Macronutrients
    calories FLOAT,
    protein FLOAT,
    fat FLOAT,
    saturated_fat FLOAT,
    carbs FLOAT,
    fiber FLOAT,
    sugars FLOAT,
    -- Minerals
    cholesterol FLOAT,
    calcium FLOAT,
    phosphorus FLOAT,
    iron FLOAT,
    sodium FLOAT,
    potassium FLOAT,
    magnesium FLOAT,
    zinc FLOAT,
    copper FLOAT,
    manganese FLOAT,
    selenium FLOAT,
    -- Vitamins
    beta_carotene FLOAT,
    vitamin_a FLOAT,
    vitamin_a_rae FLOAT,
    vitamin_b1 FLOAT,
    vitamin_b6 FLOAT,
    vitamin_b12 FLOAT,
    vitamin_c FLOAT,
    vitamin_d FLOAT,
    vitamin_e FLOAT,
    vitamin_k FLOAT,
    folate FLOAT,
    niacin FLOAT,
    riboflavin FLOAT,
    pantothenic_acid FLOAT,
    choline FLOAT,
    -- Other
    water FLOAT,
    alcohol FLOAT,
    caffeine FLOAT,
    ash FLOAT,
    category_code NVARCHAR(100),
    -- Daily Food specific (optional)
    meal_type NVARCHAR(50) NULL CHECK (meal_type IN ('Breakfast', 'Lunch', 'Dinner', 'Snack')),
    water_intake_ml INT NULL,
    created_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE Food_Translations (
    food_id INT NOT NULL,
    language_id INT NOT NULL,
    name NVARCHAR(255) NOT NULL,
    category_name NVARCHAR(100),
    PRIMARY KEY (food_id, language_id),
    FOREIGN KEY (food_id) REFERENCES Foods(food_id) ON DELETE CASCADE,
    FOREIGN KEY (language_id) REFERENCES Languages(language_id)
);

-- =====================================================
-- BẢNG FOOD CHI TIẾT (Giữ nguyên - cần cho phân tích chuyên sâu)
-- =====================================================
CREATE TABLE Food_Amino_Acids (
    food_id INT PRIMARY KEY,
    alanine FLOAT, arginine FLOAT, aspartic_acid FLOAT, cystine FLOAT,
    glutamic_acid FLOAT, glycine FLOAT, histidine FLOAT, hydroxyproline FLOAT,
    isoleucine FLOAT, leucine FLOAT, lysine FLOAT, methionine FLOAT,
    phenylalanine FLOAT, proline FLOAT, serine FLOAT, threonine FLOAT,
    tryptophan FLOAT, tyrosine FLOAT, valine FLOAT,
    FOREIGN KEY (food_id) REFERENCES Foods(food_id) ON DELETE CASCADE
);

CREATE TABLE Food_Fatty_Acids (
    food_id INT PRIMARY KEY,
    saturated_fatty_acids FLOAT,
    monounsaturated_fatty_acids FLOAT,
    polyunsaturated_fatty_acids FLOAT,
    fatty_acids_total_trans FLOAT,
    FOREIGN KEY (food_id) REFERENCES Foods(food_id) ON DELETE CASCADE
);

CREATE TABLE Food_Sugars (
    food_id INT PRIMARY KEY,
    fructose FLOAT, galactose FLOAT, glucose FLOAT,
    lactose FLOAT, maltose FLOAT, sucrose FLOAT,
    FOREIGN KEY (food_id) REFERENCES Foods(food_id) ON DELETE CASCADE
);

CREATE TABLE Food_Carotenoids (
    food_id INT PRIMARY KEY,
    carotene_alpha FLOAT, carotene_beta FLOAT,
    cryptoxanthin_beta FLOAT, lutein_zeaxanthin FLOAT, lycopene FLOAT,
    FOREIGN KEY (food_id) REFERENCES Foods(food_id) ON DELETE CASCADE
);

CREATE INDEX IX_Foods_Source ON Foods(source);
CREATE INDEX IX_Foods_MealType ON Foods(meal_type);
CREATE INDEX IX_Foods_Category ON Foods(category_code);
CREATE INDEX IX_Food_Translations_Lang ON Food_Translations(language_id);
GO

-- =====================================================
-- BẢNG RECIPES (Giữ nguyên)
-- =====================================================
CREATE TABLE Recipes (
    recipe_id INT PRIMARY KEY IDENTITY(1,1),
    recipe_code NVARCHAR(200) UNIQUE NOT NULL,
    themealdb_id NVARCHAR(50),
    category NVARCHAR(100),
    area NVARCHAR(100),
    image_url NVARCHAR(500),
    thumbnail_url NVARCHAR(500),
    youtube_url NVARCHAR(500),
    source_url NVARCHAR(500),
    tags NVARCHAR(500),
    created_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE Recipe_Translations (
    recipe_id INT NOT NULL,
    language_id INT NOT NULL,
    name NVARCHAR(255) NOT NULL,
    overview NVARCHAR(MAX) NULL,                 -- Giới thiệu tổng quan (không chia step)
    PRIMARY KEY (recipe_id, language_id),
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id) ON DELETE CASCADE,
    FOREIGN KEY (language_id) REFERENCES Languages(language_id)
);

-- Recipe Instructions (tương tự ExerciseInstructions)
CREATE TABLE Recipe_Instructions (
    recipe_id INT NOT NULL,
    language_id INT NOT NULL,
    step_order INT NOT NULL,
    instruction NVARCHAR(MAX) NOT NULL,
    PRIMARY KEY (recipe_id, language_id, step_order),
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id) ON DELETE CASCADE,
    FOREIGN KEY (language_id) REFERENCES Languages(language_id)
);

CREATE TABLE Recipe_Ingredients (
    recipe_id INT NOT NULL,
    language_id INT NOT NULL,
    display_order INT NOT NULL,
    ingredient_name NVARCHAR(200) NOT NULL,
    measure NVARCHAR(100),
    PRIMARY KEY (recipe_id, language_id, display_order),
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id) ON DELETE CASCADE,
    FOREIGN KEY (language_id) REFERENCES Languages(language_id)
);

CREATE INDEX IX_Recipes_Category ON Recipes(category);
CREATE INDEX IX_Recipes_Area ON Recipes(area);
CREATE INDEX IX_Recipe_Instructions_Recipe ON Recipe_Instructions(recipe_id);
GO

-- =====================================================
-- BẢNG FAVORITES (Món ăn/Công thức yêu thích của User)
-- =====================================================
CREATE TABLE Favorite_Foods (
    user_id INT NOT NULL,
    food_id INT NOT NULL,
    notes NVARCHAR(255) NULL,
    created_at DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (user_id, food_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (food_id) REFERENCES Foods(food_id) ON DELETE CASCADE
);

CREATE TABLE Favorite_Recipes (
    user_id INT NOT NULL,
    recipe_id INT NOT NULL,
    notes NVARCHAR(255) NULL,
    created_at DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (user_id, recipe_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id) ON DELETE CASCADE
);

CREATE INDEX IX_FavoriteFoods_UserId ON Favorite_Foods(user_id);
CREATE INDEX IX_FavoriteRecipes_UserId ON Favorite_Recipes(user_id);
GO

-- =====================================================
-- BẢNG PLANS
-- =====================================================
CREATE TABLE Plans (
    plan_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT NOT NULL,
    plan_type NVARCHAR(50) CHECK (plan_type IN ('workout', 'meal', 'combined')),
    name NVARCHAR(255),
    description NVARCHAR(MAX),
    is_active BIT DEFAULT 1,
    created_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

CREATE TABLE Plan_Details (
    plan_id INT NOT NULL,
    day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
    exercise_id INT NULL,
    recipe_id INT NULL,                          -- Thay meal_id bằng recipe_id
    food_id INT NULL,                            -- Thêm food_id để plan có thể chứa foods
    sets INT NULL,
    reps INT NULL,
    rest_duration INT NULL,
    order_index INT DEFAULT 0,
    PRIMARY KEY (plan_id, day_of_week, order_index),
    FOREIGN KEY (plan_id) REFERENCES Plans(plan_id) ON DELETE CASCADE,
    FOREIGN KEY (exercise_id) REFERENCES Exercises(exercise_id),
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id),
    FOREIGN KEY (food_id) REFERENCES Foods(food_id)
);

CREATE INDEX IX_Plans_UserId ON Plans(user_id);
GO

-- =====================================================
-- BẢNG WORKOUT SESSIONS
-- =====================================================
CREATE TABLE Workout_Sessions (
    session_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    plan_id INT NULL,
    exercise_id INT NULL,
    name NVARCHAR(255) NULL,
    status NVARCHAR(50) DEFAULT 'in_progress' 
        CHECK (status IN ('in_progress', 'completed', 'cancelled')),
    started_at DATETIME DEFAULT GETDATE(),
    completed_at DATETIME NULL,
    total_duration INT NULL,
    notes NVARCHAR(MAX) NULL,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (plan_id) REFERENCES Plans(plan_id),
    FOREIGN KEY (exercise_id) REFERENCES Exercises(exercise_id)
);

CREATE TABLE Workout_Session_Details (
    session_id INT NOT NULL,
    exercise_id INT NOT NULL,
    order_index INT NOT NULL,
    target_sets INT DEFAULT 3,
    sets_completed INT DEFAULT 0,
    target_reps INT DEFAULT 10,
    reps_completed NVARCHAR(50) NULL,
    weight_used NVARCHAR(50) NULL,
    rest_duration INT DEFAULT 60,
    notes NVARCHAR(MAX) NULL,
    started_at DATETIME NULL,
    completed_at DATETIME NULL,
    PRIMARY KEY (session_id, exercise_id, order_index),
    FOREIGN KEY (session_id) REFERENCES Workout_Sessions(session_id) ON DELETE CASCADE,
    FOREIGN KEY (exercise_id) REFERENCES Exercises(exercise_id)
);

CREATE INDEX IX_WorkoutSessions_UserId ON Workout_Sessions(user_id);
CREATE INDEX IX_WorkoutSessions_Status ON Workout_Sessions(status);
CREATE INDEX IX_WorkoutSessions_StartedAt ON Workout_Sessions(started_at DESC);
GO

-- =====================================================
-- BẢNG TRACKING (Đã tối ưu)
-- =====================================================
CREATE TABLE Exercise_Tracking (
    user_id INT NOT NULL,
    exercise_id INT NOT NULL,
    tracked_at DATETIME NOT NULL DEFAULT GETDATE(),
    duration INT NULL,
    sets INT NULL,
    reps INT NULL,
    weight DECIMAL(10,2) NULL,
    calories_burned DECIMAL(10,2) NULL,
    notes NVARCHAR(500) NULL,
    PRIMARY KEY (user_id, exercise_id, tracked_at),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (exercise_id) REFERENCES Exercises(exercise_id)
);

CREATE TABLE Meal_Tracking (
    user_id INT NOT NULL,
    tracked_date DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    meal_type NVARCHAR(50) NOT NULL CHECK (meal_type IN ('Breakfast', 'Lunch', 'Dinner', 'Snack')),
    recipe_id INT NULL,                          -- Thay meal_id bằng recipe_id
    food_id INT NULL,
    meal_name NVARCHAR(255) NULL,                -- Tên tùy chỉnh nếu không từ recipe/food
    calories DECIMAL(10,2) NULL,
    protein DECIMAL(10,2) NULL,
    carbs DECIMAL(10,2) NULL,
    fat DECIMAL(10,2) NULL,
    quantity DECIMAL(10,2) DEFAULT 100,
    notes NVARCHAR(500) NULL,
    created_at DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (user_id, tracked_date, meal_type, created_at),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES Recipes(recipe_id),
    FOREIGN KEY (food_id) REFERENCES Foods(food_id)
);

CREATE TABLE Weight_Tracking (
    user_id INT NOT NULL,
    tracked_at DATETIME NOT NULL DEFAULT GETDATE(),
    weight DECIMAL(5,2) NOT NULL,
    notes NVARCHAR(500) NULL,
    PRIMARY KEY (user_id, tracked_at),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

CREATE TABLE Water_Tracking (
    user_id INT NOT NULL,
    tracked_at DATETIME NOT NULL DEFAULT GETDATE(),
    amount_ml INT NOT NULL,
    notes NVARCHAR(255) NULL,
    PRIMARY KEY (user_id, tracked_at),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

CREATE INDEX IX_ExerciseTracking_Date ON Exercise_Tracking(tracked_at);
CREATE INDEX IX_MealTracking_Date ON Meal_Tracking(tracked_date);
CREATE INDEX IX_WeightTracking_Date ON Weight_Tracking(tracked_at DESC);
CREATE INDEX IX_WaterTracking_Date ON Water_Tracking(tracked_at);
GO

-- =====================================================
-- BẢNG SOCIAL
-- =====================================================
CREATE TABLE Friendships (
    user_id INT NOT NULL,
    friend_id INT NOT NULL,
    status NVARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'blocked')),
    created_at DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (user_id, friend_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (friend_id) REFERENCES Users(user_id),
    CHECK (user_id <> friend_id)
);

CREATE TABLE Notifications (
    notification_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    type NVARCHAR(50) DEFAULT 'system' CHECK (type IN ('system', 'achievement', 'reminder', 'social')),
    title NVARCHAR(255),
    message NVARCHAR(MAX),
    is_read BIT DEFAULT 0,
    created_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

CREATE INDEX IX_Notifications_UserId ON Notifications(user_id);
CREATE INDEX IX_Notifications_Unread ON Notifications(user_id, is_read) WHERE is_read = 0;
GO

-- =====================================================
-- BẢNG ACHIEVEMENTS
-- =====================================================
CREATE TABLE Achievements (
    achievement_id INT PRIMARY KEY IDENTITY(1,1),
    code NVARCHAR(50) UNIQUE NOT NULL,
    icon_name NVARCHAR(100) NOT NULL,
    color_hex NVARCHAR(10) NOT NULL,
    points INT DEFAULT 10,
    created_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE Achievement_Translations (
    achievement_id INT NOT NULL,
    language_id INT NOT NULL,
    title NVARCHAR(255) NOT NULL,
    description NVARCHAR(MAX),
    PRIMARY KEY (achievement_id, language_id),
    FOREIGN KEY (achievement_id) REFERENCES Achievements(achievement_id) ON DELETE CASCADE,
    FOREIGN KEY (language_id) REFERENCES Languages(language_id)
);

CREATE TABLE User_Achievements (
    user_id INT NOT NULL,
    achievement_id INT NOT NULL,
    unlocked_at DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (user_id, achievement_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (achievement_id) REFERENCES Achievements(achievement_id)
);
GO

-- Insert default achievements
INSERT INTO Achievements (code, icon_name, color_hex, points) VALUES
('first_week', 'emoji_events', '#FF6B6B', 10),
('7_day_streak', 'local_fire_department', '#FF9500', 20),
('10_workouts', 'fitness_center', '#7C3AED', 30),
('30_days', 'star', '#3B82F6', 50),
('goal_reached', 'flag', '#7C3AED', 100);

INSERT INTO Achievement_Translations (achievement_id, language_id, title, description) VALUES
(1, 1, 'First Week', 'Complete your first week using the app'),
(2, 1, '7 Day Streak', 'Maintain a 7-day activity streak'),
(3, 1, '10 Workouts', 'Complete 10 workout sessions'),
(4, 1, '30 Days', 'Use the app for 30 days'),
(5, 1, 'Goal Reached', 'Reach your weight goal');

INSERT INTO Achievement_Translations (achievement_id, language_id, title, description) VALUES
(1, 2, N'Tuần đầu', N'Hoàn thành tuần đầu tiên sử dụng app'),
(2, 2, N'7 ngày liên tiếp', N'Duy trì hoạt động 7 ngày liên tiếp'),
(3, 2, N'10 bài tập', N'Hoàn thành 10 buổi tập luyện'),
(4, 2, N'30 ngày', N'Sử dụng app 30 ngày'),
(5, 2, N'Đạt mục tiêu', N'Đạt mục tiêu cân nặng');
GO

-- =====================================================
-- VIEWS
-- =====================================================

-- View: Recipes tiếng Việt
CREATE VIEW vw_Recipes_Vietnamese AS
SELECT 
    r.recipe_id,
    r.recipe_code,
    rt.name,
    r.category,
    r.area,
    r.image_url,
    r.youtube_url,
    r.tags
FROM Recipes r
INNER JOIN Recipe_Translations rt ON r.recipe_id = rt.recipe_id
WHERE rt.language_id = 2;
GO

-- View: Foods với translation
CREATE VIEW vw_Foods_Vietnamese AS
SELECT 
    f.food_id,
    f.code,
    ft.name,
    ft.category_name,
    f.calories,
    f.protein,
    f.fat,
    f.carbs,
    f.fiber,
    f.source,
    f.meal_type
FROM Foods f
INNER JOIN Food_Translations ft ON f.food_id = ft.food_id
WHERE ft.language_id = 2;
GO

-- View: User daily summary
CREATE VIEW vw_User_Daily_Summary AS
SELECT 
    mt.user_id,
    mt.tracked_date,
    SUM(mt.calories) as total_calories,
    SUM(mt.protein) as total_protein,
    SUM(mt.carbs) as total_carbs,
    SUM(mt.fat) as total_fat,
    (SELECT SUM(amount_ml) FROM Water_Tracking wt 
     WHERE wt.user_id = mt.user_id 
       AND CAST(wt.tracked_at AS DATE) = mt.tracked_date) as total_water_ml,
    (SELECT COUNT(*) FROM Exercise_Tracking et 
     WHERE et.user_id = mt.user_id 
       AND CAST(et.tracked_at AS DATE) = mt.tracked_date) as exercises_count
FROM Meal_Tracking mt
GROUP BY mt.user_id, mt.tracked_date;
GO

-- =====================================================
-- STORED PROCEDURES
-- =====================================================

-- SP: Get user progress for today
CREATE PROCEDURE sp_GetUserDailyProgress
    @user_id INT,
    @date DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @date IS NULL SET @date = CAST(GETDATE() AS DATE);
    
    -- Nutrition progress
    SELECT 
        COALESCE(SUM(mt.calories), 0) as consumed_calories,
        COALESCE(SUM(mt.protein), 0) as consumed_protein,
        COALESCE(SUM(mt.carbs), 0) as consumed_carbs,
        COALESCE(SUM(mt.fat), 0) as consumed_fat,
        ug.calories_goal,
        ug.protein_goal,
        ug.carbs_goal,
        ug.fat_goal
    FROM User_Goals ug
    LEFT JOIN Meal_Tracking mt ON mt.user_id = ug.user_id AND mt.tracked_date = @date
    WHERE ug.user_id = @user_id
    GROUP BY ug.calories_goal, ug.protein_goal, ug.carbs_goal, ug.fat_goal;
    
    -- Water progress
    SELECT 
        COALESCE(SUM(wt.amount_ml), 0) as consumed_water_ml,
        ug.water_goal_ml
    FROM User_Goals ug
    LEFT JOIN Water_Tracking wt ON wt.user_id = ug.user_id AND CAST(wt.tracked_at AS DATE) = @date
    WHERE ug.user_id = @user_id
    GROUP BY ug.water_goal_ml;
END;
GO

-- =====================================================
-- CONFIRMATION
-- =====================================================
PRINT '============================================='
PRINT '✅ DATABASE HEATHCARE - OPTIMIZED SCHEMA v2.1'
PRINT '============================================='
PRINT ''
PRINT '📊 TABLES: 34 (from original 38)'
PRINT ''
PRINT '🗑️ REMOVED:'
PRINT '   - Daily_Foods, Daily_Food_Translations (merged to Foods)'
PRINT '   - Meals, Meal_Translations, Meal_Food_Items (replaced by Favorites)'
PRINT ''
PRINT '✨ NEW:'
PRINT '   - Favorite_Foods, Favorite_Recipes (user favorites)'
PRINT '   - Muscles, Muscle_Translations (i18n for muscle names)'
PRINT ''
PRINT '✨ OPTIMIZATIONS:'
PRINT '   - Foods: added source, meal_type, water_intake_ml'
PRINT '   - All translation tables: composite primary keys'
PRINT '   - Tracking tables: composite primary keys'
PRINT '============================================='
GO

-- =====================================================
-- KIỂM TRA DỮ LIỆU CÁC BẢNG
-- =====================================================

-- Core Tables
SELECT 'Languages' AS [Table], COUNT(*) AS [Records] FROM Languages UNION ALL
SELECT 'Users', COUNT(*) FROM Users UNION ALL
SELECT 'User_Goals', COUNT(*) FROM User_Goals;

-- Exercises
SELECT 'Exercises' AS [Table], COUNT(*) AS [Records] FROM Exercises UNION ALL
SELECT 'Exercise_Translations', COUNT(*) FROM Exercise_Translations UNION ALL
SELECT 'ExercisePrimaryMuscles', COUNT(*) FROM ExercisePrimaryMuscles UNION ALL
SELECT 'ExerciseSecondaryMuscles', COUNT(*) FROM ExerciseSecondaryMuscles UNION ALL
SELECT 'ExerciseInstructions', COUNT(*) FROM ExerciseInstructions UNION ALL
SELECT 'ExerciseImages', COUNT(*) FROM ExerciseImages;

-- Muscles
SELECT 'Muscles' AS [Table], COUNT(*) AS [Records] FROM Muscles UNION ALL
SELECT 'Muscle_Translations', COUNT(*) FROM Muscle_Translations;

-- Foods
SELECT 'Foods' AS [Table], COUNT(*) AS [Records] FROM Foods UNION ALL
SELECT 'Food_Translations', COUNT(*) FROM Food_Translations UNION ALL
SELECT 'Food_Amino_Acids', COUNT(*) FROM Food_Amino_Acids UNION ALL
SELECT 'Food_Fatty_Acids', COUNT(*) FROM Food_Fatty_Acids UNION ALL
SELECT 'Food_Sugars', COUNT(*) FROM Food_Sugars UNION ALL
SELECT 'Food_Carotenoids', COUNT(*) FROM Food_Carotenoids;

-- Recipes
SELECT 'Recipes' AS [Table], COUNT(*) AS [Records] FROM Recipes UNION ALL
SELECT 'Recipe_Translations', COUNT(*) FROM Recipe_Translations UNION ALL
SELECT 'Recipe_Instructions', COUNT(*) FROM Recipe_Instructions UNION ALL
SELECT 'Recipe_Ingredients', COUNT(*) FROM Recipe_Ingredients;

-- Favorites
SELECT 'Favorite_Foods' AS [Table], COUNT(*) AS [Records] FROM Favorite_Foods UNION ALL
SELECT 'Favorite_Recipes', COUNT(*) FROM Favorite_Recipes;

-- Plans & Workouts
SELECT 'Plans' AS [Table], COUNT(*) AS [Records] FROM Plans UNION ALL
SELECT 'Plan_Details', COUNT(*) FROM Plan_Details UNION ALL
SELECT 'Workout_Sessions', COUNT(*) FROM Workout_Sessions UNION ALL
SELECT 'Workout_Session_Details', COUNT(*) FROM Workout_Session_Details;

-- Tracking
SELECT 'Exercise_Tracking' AS [Table], COUNT(*) AS [Records] FROM Exercise_Tracking UNION ALL
SELECT 'Meal_Tracking', COUNT(*) FROM Meal_Tracking UNION ALL
SELECT 'Weight_Tracking', COUNT(*) FROM Weight_Tracking UNION ALL
SELECT 'Water_Tracking', COUNT(*) FROM Water_Tracking;

-- Social
SELECT 'Friendships' AS [Table], COUNT(*) AS [Records] FROM Friendships UNION ALL
SELECT 'Notifications', COUNT(*) FROM Notifications;

-- Achievements
SELECT 'Achievements' AS [Table], COUNT(*) AS [Records] FROM Achievements UNION ALL
SELECT 'Achievement_Translations', COUNT(*) FROM Achievement_Translations UNION ALL
SELECT 'User_Achievements', COUNT(*) FROM User_Achievements;

-- Sample Data Queries
SELECT * FROM Foods;
SELECT  * FROM Food_Translations;
SELECT * FROM Food_Translations WHERE category_name LIKE N'%Bữa ăn%';
SELECT  * FROM Exercises;
SELECT  * FROM Exercise_Translations WHERE language_id = 2;
SELECT  * FROM Recipes;
SELECT  * FROM Recipe_Translations WHERE language_id = 2;
SELECT  * FROM Recipe_Instructions WHERE language_id = 2;

ALTER TABLE Users ADD activity_level NVARCHAR(50);
ALTER TABLE Users ADD onboarding_completed BIT NOT NULL DEFAULT 0;

ALTER TABLE Users ADD body_goals NVARCHAR(500) NULL;
ALTER TABLE Users ADD full_name NVARCHAR(100) NULL;