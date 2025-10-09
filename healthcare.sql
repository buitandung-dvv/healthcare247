CREATE DATABASE HeathCare;
USE HeathCare;

CREATE TABLE Users (
    user_id INT PRIMARY KEY IDENTITY(1,1),
    username NVARCHAR(100) UNIQUE NOT NULL,
    password NVARCHAR(255) NOT NULL,
    email NVARCHAR(150) UNIQUE NOT NULL,
    gender NVARCHAR(10) CHECK (gender IN ('Male', 'Female', 'Other')),
    date_of_birth DATE,
    height DECIMAL(5,2),
    weight DECIMAL(5,2),
    goal NVARCHAR(255),
    created_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE Exercises (
    exercise_id INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(100) NOT NULL,
    type NVARCHAR(50) CHECK (type IN ('cardio','strength','flexibility','balance')),
    level NVARCHAR(50) CHECK (level IN ('beginner','intermediate','advanced')),
    calories_burned_per_hour DECIMAL(10,2)
);

CREATE TABLE Foods (
    food_id INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(100) NOT NULL,
    calories DECIMAL(10,2),
    protein DECIMAL(10,2),
    fat DECIMAL(10,2),
    carbs DECIMAL(10,2)
);

CREATE TABLE Meals (
    meal_id INT PRIMARY KEY IDENTITY(1,1),
    meal_type NVARCHAR(50) CHECK (meal_type IN ('breakfast','lunch','dinner','snack')),
    created_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE Meal_Food_Items (
    meal_id INT,
    food_id INT,
    quantity DECIMAL(10,2),
    PRIMARY KEY (meal_id, food_id),
    FOREIGN KEY (meal_id) REFERENCES Meals(meal_id),
    FOREIGN KEY (food_id) REFERENCES Foods(food_id)
);

CREATE TABLE Plans (
    plan_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT,
    plan_type NVARCHAR(50) CHECK (plan_type IN ('nutrition','workout','mixed')),
    description NVARCHAR(255),
    created_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Plan_Details (
    detail_id INT IDENTITY(1,1) PRIMARY KEY,
    plan_id INT NOT NULL,
    day_of_week INT NOT NULL,
    exercise_id INT NULL,
    meal_id INT NULL,
    FOREIGN KEY (plan_id) REFERENCES Plans(plan_id),
    FOREIGN KEY (exercise_id) REFERENCES Exercises(exercise_id),
    FOREIGN KEY (meal_id) REFERENCES Meals(meal_id)
);

CREATE TABLE Plan_Exercises (
    plan_id INT,
    exercise_id INT,
    duration_minutes INT,
    PRIMARY KEY (plan_id, exercise_id),
    FOREIGN KEY (plan_id) REFERENCES Plans(plan_id),
    FOREIGN KEY (exercise_id) REFERENCES Exercises(exercise_id)
);

CREATE TABLE Plan_Meals (
    plan_id INT,
    meal_id INT,
    PRIMARY KEY (plan_id, meal_id),
    FOREIGN KEY (plan_id) REFERENCES Plans(plan_id),
    FOREIGN KEY (meal_id) REFERENCES Meals(meal_id)
);

CREATE TABLE Exercise_Tracking (
    tracking_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT,
    exercise_id INT,
    duration_minutes INT,
    calories_burned DECIMAL(10,2),
    date DATE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (exercise_id) REFERENCES Exercises(exercise_id)
);

CREATE TABLE Meal_Tracking (
    tracking_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT,
    meal_id INT,
    date DATE,
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (meal_id) REFERENCES Meals(meal_id)
);

CREATE TABLE AI_Recommendations (
    rec_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    date DATE,
    recommendation NVARCHAR(MAX),
    source NVARCHAR(10) CHECK (source IN ('system','AI')),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Achievements (
    achievement_id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(255),
    description NVARCHAR(MAX),
    icon_url NVARCHAR(255)
);

CREATE TABLE User_Achievements (
    user_id INT NOT NULL,
    achievement_id INT NOT NULL,
    earned_at DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (user_id, achievement_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (achievement_id) REFERENCES Achievements(achievement_id)
);

CREATE TABLE Friendships (
    user_id INT,
    friend_id INT,
    status NVARCHAR(20) CHECK (status IN ('pending','accepted','blocked')),
    PRIMARY KEY (user_id, friend_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (friend_id) REFERENCES Users(user_id),
    CHECK (user_id <> friend_id)
);

CREATE TABLE Challenges (
    challenge_id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(255),
    description NVARCHAR(MAX),
    duration_days INT,
    reward NVARCHAR(255)
);

CREATE TABLE User_Challenges (
    user_id INT NOT NULL,
    challenge_id INT NOT NULL,
    progress INT DEFAULT 0,
    status NVARCHAR(20) CHECK (status IN ('in_progress','completed','failed')) DEFAULT 'in_progress',
    start_date DATE,
    end_date DATE,
    PRIMARY KEY (user_id, challenge_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (challenge_id) REFERENCES Challenges(challenge_id)
);

CREATE TABLE Notifications (
    notification_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT,
    message NVARCHAR(MAX),
    type NVARCHAR(20) CHECK (type IN ('reminder','achievement','system')) DEFAULT 'system',
    created_at DATETIME DEFAULT GETDATE(),
    is_read BIT DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- Users
INSERT INTO Users (username, password, email, gender, date_of_birth, height, weight, goal)
VALUES 
('john_doe', 'hashed_pw1', 'john@example.com', 'Male', '1995-05-12', 175.5, 70.0, 'Build muscle'),
('jane_smith', 'hashed_pw2', 'jane@example.com', 'Female', '1998-08-20', 165.0, 55.0, 'Lose weight');

-- Exercises
INSERT INTO Exercises (name, type, level, calories_burned_per_hour)
VALUES
('Running', 'cardio', 'beginner', 600),
('Push-ups', 'strength', 'intermediate', 500),
('Yoga', 'flexibility', 'beginner', 200);

-- Foods
INSERT INTO Foods (name, calories, protein, fat, carbs)
VALUES
('Chicken Breast', 165, 31, 3.6, 0),
('Brown Rice', 110, 2.6, 0.9, 23),
('Broccoli', 55, 4.7, 0.3, 11);

-- Meals
INSERT INTO Meals (meal_type) VALUES ('breakfast'), ('lunch'), ('dinner');

-- Meal_Food_Items
INSERT INTO Meal_Food_Items (meal_id, food_id, quantity)
VALUES
(1, 1, 1.0), -- breakfast: chicken breast
(1, 2, 1.0), -- breakfast: brown rice
(2, 3, 2.0); -- lunch: broccoli

-- Plans
INSERT INTO Plans (user_id, plan_type, description)
VALUES
(1, 'workout', 'John’s muscle building workout plan'),
(2, 'nutrition', 'Jane’s weight loss diet plan');

-- Plan_Details
INSERT INTO Plan_Details (plan_id, day_of_week, exercise_id, meal_id)
VALUES
(1, 1, 1, NULL), -- John Monday: Running
(1, 2, 2, NULL), -- John Tuesday: Push-ups
(2, 1, NULL, 1), -- Jane Monday: breakfast meal
(2, 2, NULL, 2); -- Jane Tuesday: lunch meal

-- Plan_Exercises
INSERT INTO Plan_Exercises (plan_id, exercise_id, duration_minutes)
VALUES
(1, 1, 30),
(1, 2, 20);

-- Plan_Meals
INSERT INTO Plan_Meals (plan_id, meal_id)
VALUES
(2, 1),
(2, 2);

-- Exercise_Tracking
INSERT INTO Exercise_Tracking (user_id, exercise_id, duration_minutes, calories_burned, date)
VALUES
(1, 1, 30, 300, '2025-09-20'),
(1, 2, 20, 160, '2025-09-21');

-- Meal_Tracking
INSERT INTO Meal_Tracking (user_id, meal_id, date)
VALUES
(2, 1, '2025-09-20'),
(2, 2, '2025-09-21');

-- AI_Recommendations
INSERT INTO AI_Recommendations (user_id, date, recommendation, source)
VALUES
(1, '2025-09-22', 'Increase protein intake today', 'AI'),
(2, '2025-09-22', 'Try a 20-min yoga session', 'system');

-- Achievements
INSERT INTO Achievements (name, description, icon_url)
VALUES
('First Run', 'Completed first running session', '/icons/run.png'),
('Healthy Meal', 'Logged a healthy meal', '/icons/meal.png');

-- User_Achievements
INSERT INTO User_Achievements (user_id, achievement_id)
VALUES
(1, 1),
(2, 2);

-- Friendships
INSERT INTO Friendships (user_id, friend_id, status)
VALUES
(1, 2, 'accepted');

-- Challenges
INSERT INTO Challenges (name, description, duration_days, reward)
VALUES
('7-Day Fitness Challenge', 'Workout daily for 7 days', 7, 'Badge'),
('Healthy Eating Challenge', 'Eat vegetables daily for 10 days', 10, 'Discount Coupon');

-- User_Challenges
INSERT INTO User_Challenges (user_id, challenge_id, progress, status, start_date, end_date)
VALUES
(1, 1, 3, 'in_progress', '2025-09-19', '2025-09-26'),
(2, 2, 5, 'in_progress', '2025-09-15', '2025-09-25');

-- Notifications
INSERT INTO Notifications (user_id, message, type, is_read)
VALUES
(1, 'Don’t forget your workout today!', 'reminder', 0),
(2, 'You earned the Healthy Meal achievement!', 'achievement', 0);


SELECT * FROM Users;
SELECT * FROM Exercises;
SELECT * FROM Foods;
SELECT * FROM Meals;
SELECT * FROM Meal_Food_Items;
SELECT * FROM Plans;
SELECT * FROM Plan_Details;
SELECT * FROM Plan_Exercises;
SELECT * FROM Plan_Meals;
SELECT * FROM Exercise_Tracking;
SELECT * FROM Meal_Tracking;
SELECT * FROM AI_Recommendations;
SELECT * FROM Achievements;
SELECT * FROM User_Achievements;
SELECT * FROM Friendships;
SELECT * FROM Challenges;
SELECT * FROM User_Challenges;
SELECT * FROM Notifications;